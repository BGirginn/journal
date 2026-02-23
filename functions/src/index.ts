import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getMessaging, type BatchResponse, type SendResponse } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions/v2';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';

initializeApp();

const firestore = getFirestore();
const messaging = getMessaging();

const USERS_COLLECTION = 'users';
const INVITES_COLLECTION = 'invites';
const NOTIFICATIONS_COLLECTION = 'notifications';
const PUSH_TOKENS_COLLECTION = 'push_tokens';
const NOTIFICATION_ROUTE = '/notifications';
const NOTIFICATION_SCHEMA_VERSION = 1;

type InviteType = 'team' | 'journal';
type InviteStatus = 'pending' | 'accepted' | 'rejected' | 'expired';
export type InviteNotificationType =
  | 'invite_received'
  | 'invite_accepted'
  | 'invite_rejected';

export interface InviteDoc {
  id?: string;
  type?: InviteType;
  targetId?: string;
  inviterId?: string;
  inviteeId?: string | null;
  status?: InviteStatus;
}

export interface PushToken {
  deviceId: string;
  token: string;
}

export interface NotificationText {
  title: string;
  body: string;
}

export interface PushMessagePayload {
  title: string;
  body: string;
  data: Record<string, string>;
}

export interface NotificationContext {
  getUserPreferredLanguage(uid: string): Promise<string | null>;
  getUserDisplayName(uid: string): Promise<string | null>;
  createNotification(
    recipientUid: string,
    notificationId: string,
    payload: Record<string, unknown>,
  ): Promise<boolean>;
  listPushTokens(recipientUid: string): Promise<PushToken[]>;
  sendPush(tokens: PushToken[], payload: PushMessagePayload): Promise<string[]>;
  removePushTokens(recipientUid: string, deviceIds: string[]): Promise<void>;
}

const runtimeContext: NotificationContext = {
  async getUserPreferredLanguage(uid: string): Promise<string | null> {
    const doc = await firestore.collection(USERS_COLLECTION).doc(uid).get();
    const preferredLanguage = doc.data()?.preferredLanguage;
    return typeof preferredLanguage === 'string' ? preferredLanguage : null;
  },

  async getUserDisplayName(uid: string): Promise<string | null> {
    const doc = await firestore.collection(USERS_COLLECTION).doc(uid).get();
    const displayName = doc.data()?.displayName;
    return typeof displayName === 'string' ? displayName : null;
  },

  async createNotification(
    recipientUid: string,
    notificationId: string,
    payload: Record<string, unknown>,
  ): Promise<boolean> {
    const docRef = firestore
      .collection(USERS_COLLECTION)
      .doc(recipientUid)
      .collection(NOTIFICATIONS_COLLECTION)
      .doc(notificationId);

    try {
      await docRef.create({
        ...payload,
        createdAt: FieldValue.serverTimestamp(),
      });
      return true;
    } catch (error) {
      if (isAlreadyExistsError(error)) {
        return false;
      }
      throw error;
    }
  },

  async listPushTokens(recipientUid: string): Promise<PushToken[]> {
    const snapshot = await firestore
      .collection(USERS_COLLECTION)
      .doc(recipientUid)
      .collection(PUSH_TOKENS_COLLECTION)
      .get();

    return snapshot.docs
      .map((doc) => ({
        deviceId: doc.id,
        token: (doc.data().token as string | undefined) ?? '',
      }))
      .filter((entry) => entry.token.length > 0);
  },

  async sendPush(
    tokens: PushToken[],
    payload: PushMessagePayload,
  ): Promise<string[]> {
    if (tokens.length === 0) {
      return [];
    }

    const response = await messaging.sendEachForMulticast({
      tokens: tokens.map((entry) => entry.token),
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data,
      android: {
        notification: {
          channelId: 'invites',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    });

    return extractInvalidDeviceIds(tokens, response);
  },

  async removePushTokens(recipientUid: string, deviceIds: string[]): Promise<void> {
    if (deviceIds.length === 0) {
      return;
    }

    const batch = firestore.batch();
    const uniqueDeviceIds = [...new Set(deviceIds)];
    for (const deviceId of uniqueDeviceIds) {
      batch.delete(
        firestore
          .collection(USERS_COLLECTION)
          .doc(recipientUid)
          .collection(PUSH_TOKENS_COLLECTION)
          .doc(deviceId),
      );
    }
    await batch.commit();
  },
};

export const onInviteCreated = onDocumentCreated(
  `${INVITES_COLLECTION}/{inviteId}`,
  async (event) => {
    const inviteId = event.params.inviteId;
    const invite = event.data?.data() as InviteDoc | undefined;
    if (!invite) {
      return;
    }

    try {
      await processInviteCreated(inviteId, invite, runtimeContext);
    } catch (error) {
      logger.error('onInviteCreated failed', { inviteId, error });
      throw error;
    }
  },
);

export const onInviteUpdated = onDocumentUpdated(
  `${INVITES_COLLECTION}/{inviteId}`,
  async (event) => {
    const inviteId = event.params.inviteId;
    const before = event.data?.before.data() as InviteDoc | undefined;
    const after = event.data?.after.data() as InviteDoc | undefined;
    if (!before || !after) {
      return;
    }

    try {
      await processInviteUpdated(inviteId, before, after, runtimeContext);
    } catch (error) {
      logger.error('onInviteUpdated failed', { inviteId, error });
      throw error;
    }
  },
);

export async function processInviteCreated(
  inviteId: string,
  invite: InviteDoc,
  context: NotificationContext,
): Promise<void> {
  const recipientUid = invite.inviteeId;
  const actorUid = invite.inviterId;
  if (!recipientUid || !actorUid) {
    return;
  }

  await dispatchInviteNotification({
    context,
    recipientUid,
    actorUid,
    inviteId,
    inviteType: normalizeInviteType(invite.type),
    targetId: invite.targetId ?? '',
    notificationType: 'invite_received',
    notificationId: buildNotificationId(inviteId, 'invite_received'),
  });
}

export async function processInviteUpdated(
  inviteId: string,
  before: InviteDoc,
  after: InviteDoc,
  context: NotificationContext,
): Promise<void> {
  if (before.status !== 'pending') {
    return;
  }
  if (after.status !== 'accepted' && after.status !== 'rejected') {
    return;
  }

  const recipientUid = after.inviterId;
  const actorUid = after.inviteeId;
  if (!recipientUid || !actorUid) {
    return;
  }

  const notificationType: InviteNotificationType =
    after.status === 'accepted' ? 'invite_accepted' : 'invite_rejected';

  await dispatchInviteNotification({
    context,
    recipientUid,
    actorUid,
    inviteId,
    inviteType: normalizeInviteType(after.type),
    targetId: after.targetId ?? '',
    notificationType,
    notificationId: buildNotificationId(inviteId, notificationType),
  });
}

interface DispatchInviteNotificationParams {
  context: NotificationContext;
  recipientUid: string;
  actorUid: string;
  inviteId: string;
  inviteType: InviteType;
  targetId: string;
  notificationType: InviteNotificationType;
  notificationId: string;
}

async function dispatchInviteNotification(
  params: DispatchInviteNotificationParams,
): Promise<void> {
  const {
    context,
    recipientUid,
    actorUid,
    inviteId,
    inviteType,
    targetId,
    notificationType,
    notificationId,
  } = params;

  const preferredLanguage = normalizeLanguage(
    await context.getUserPreferredLanguage(recipientUid),
  );
  const actorName =
    (await context.getUserDisplayName(actorUid)) ?? fallbackActorName(preferredLanguage);
  const text = buildNotificationText({
    type: notificationType,
    language: preferredLanguage,
    actorName,
    inviteType,
  });

  const notificationPayload: Record<string, unknown> = {
    id: notificationId,
    type: notificationType,
    title: text.title,
    body: text.body,
    inviteId,
    inviteType,
    targetId,
    actorId: actorUid,
    isRead: false,
    readAt: null,
    route: NOTIFICATION_ROUTE,
    schemaVersion: NOTIFICATION_SCHEMA_VERSION,
  };

  const created = await context.createNotification(
    recipientUid,
    notificationId,
    notificationPayload,
  );
  if (!created) {
    return;
  }

  const pushTokens = await context.listPushTokens(recipientUid);
  if (pushTokens.length === 0) {
    return;
  }

  const dataPayload: Record<string, string> = {
    notificationId,
    type: notificationType,
    route: NOTIFICATION_ROUTE,
    inviteId,
    targetId,
  };

  const invalidDeviceIds = await context.sendPush(pushTokens, {
    title: text.title,
    body: text.body,
    data: dataPayload,
  });

  if (invalidDeviceIds.length > 0) {
    await context.removePushTokens(recipientUid, invalidDeviceIds);
  }
}

export function buildNotificationId(
  inviteId: string,
  notificationType: InviteNotificationType,
): string {
  return `invite_${inviteId}_${notificationType.replace('invite_', '')}`;
}

export function normalizeLanguage(raw: string | null | undefined): 'tr' | 'en' {
  if (!raw) {
    return 'tr';
  }

  const normalized = raw.toLowerCase();
  if (normalized.startsWith('en')) {
    return 'en';
  }
  if (normalized.startsWith('tr')) {
    return 'tr';
  }
  return 'tr';
}

function normalizeInviteType(raw: string | undefined): InviteType {
  return raw === 'journal' ? 'journal' : 'team';
}

export function buildNotificationText(params: {
  type: InviteNotificationType;
  language: 'tr' | 'en';
  actorName: string;
  inviteType: InviteType;
}): NotificationText {
  const { type, language, actorName, inviteType } = params;

  if (language === 'en') {
    switch (type) {
      case 'invite_received': {
        const scope = inviteType === 'journal' ? 'journal' : 'team';
        return {
          title: 'New invite',
          body: `${actorName} invited you to a ${scope}.`,
        };
      }
      case 'invite_accepted':
        return {
          title: 'Invite accepted',
          body: `${actorName} accepted your invite.`,
        };
      case 'invite_rejected':
        return {
          title: 'Invite declined',
          body: `${actorName} declined your invite.`,
        };
    }
  }

  switch (type) {
    case 'invite_received': {
      const scope = inviteType === 'journal' ? 'günlüğe' : 'ekibe';
      return {
        title: 'Yeni davet',
        body: `${actorName} sizi ${scope} davet etti.`,
      };
    }
    case 'invite_accepted':
      return {
        title: 'Davet kabul edildi',
        body: `${actorName} davetinizi kabul etti.`,
      };
    case 'invite_rejected':
      return {
        title: 'Davet reddedildi',
        body: `${actorName} davetinizi reddetti.`,
      };
  }
}

function fallbackActorName(language: 'tr' | 'en'): string {
  return language === 'en' ? 'Someone' : 'Bir kullanıcı';
}

function extractInvalidDeviceIds(tokens: PushToken[], response: BatchResponse): string[] {
  const invalidDeviceIds: string[] = [];
  response.responses.forEach((result: SendResponse, index: number) => {
    if (result.success) {
      return;
    }

    const code = result.error?.code;
    if (
      code === 'messaging/registration-token-not-registered' ||
      code === 'messaging/invalid-registration-token'
    ) {
      invalidDeviceIds.push(tokens[index].deviceId);
    }
  });
  return invalidDeviceIds;
}

function isAlreadyExistsError(error: unknown): boolean {
  if (!error || typeof error !== 'object') {
    return false;
  }

  const code = (error as { code?: unknown }).code;
  if (code === 6 || code === 'already-exists') {
    return true;
  }

  const message = (error as { message?: unknown }).message;
  if (typeof message === 'string' && message.toLowerCase().includes('already exists')) {
    return true;
  }

  return false;
}
