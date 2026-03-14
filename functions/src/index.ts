import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getMessaging, type BatchResponse, type SendResponse } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions/v2';
import { onDocumentCreated, onDocumentUpdated, onDocumentWritten } from 'firebase-functions/v2/firestore';

initializeApp();

const firestore = getFirestore();
const messaging = getMessaging();

const USERS_COLLECTION = 'users';
const INVITES_COLLECTION = 'invites';
const NOTIFICATIONS_COLLECTION = 'notifications';
const PUSH_TOKENS_COLLECTION = 'push_tokens';
const JOURNALS_COLLECTION = 'journals';
const JOURNAL_MEMBERS_COLLECTION = 'journal_members';
const TEAM_MEMBERS_COLLECTION = 'team_members';
const NOTIFICATION_ROUTE = '/notifications';
const NOTIFICATION_SCHEMA_VERSION = 1;

// --- Team ↔ Journal membership propagation ---

/**
 * When a team member document is created or updated (un-deleted),
 * propagate their membership to all journals linked to that team.
 */
export const onTeamMemberWritten = onDocumentWritten(
  `${TEAM_MEMBERS_COLLECTION}/{memberId}`,
  async (event) => {
    const after = event.data?.after?.data();
    const before = event.data?.before?.data();
    if (!after) return; // deleted — handled via soft-delete

    const teamId = after.teamId as string | undefined;
    const userId = after.userId as string | undefined;
    const role = (after.role as string) ?? 'viewer';
    const deletedAt = after.deletedAt;
    if (!teamId || !userId) return;

    // If the member was soft-deleted, remove them from team journals.
    if (deletedAt) {
      const wasActive = before && !before.deletedAt;
      if (!wasActive) return; // already deleted before, no-op
      await removeUserFromTeamJournals(teamId, userId);
      return;
    }

    // Member is active — propagate to team journals.
    await addUserToTeamJournals(teamId, userId, role);
  },
);

async function addUserToTeamJournals(teamId: string, userId: string, role: string): Promise<void> {
  // Find all journals with this teamId.
  // We look across all users' journal subcollections that have teamId == teamId.
  // Alternative: Use a top-level journals index. For now, query journal_members
  // for existing entries to discover journal IDs.
  const existingMemberships = await firestore
    .collection(JOURNAL_MEMBERS_COLLECTION)
    .where('journalId', isNotEqualTo, null)
    .get();

  // Collect unique journal IDs linked to this team.
  const journalIds = new Set<string>();
  for (const doc of existingMemberships.docs) {
    const data = doc.data();
    // We need to check if the journal is linked to this team.
    // Since journal_members don't store teamId, we rely on the ownerId pattern.
    // A better approach: query the owner's journals subcollection for teamId.
    // For now, we use a team-specific owner lookup.
  }

  // Better approach: find team owner's journals with matching teamId.
  const teamDoc = await firestore.collection('teams').doc(teamId).get();
  if (!teamDoc.exists) return;
  const ownerId = teamDoc.data()?.ownerId as string | undefined;
  if (!ownerId) return;

  const journalSnapshot = await firestore
    .collection(USERS_COLLECTION)
    .doc(ownerId)
    .collection(JOURNALS_COLLECTION)
    .where('teamId', '==', teamId)
    .get();

  const batch = firestore.batch();
  const now = new Date().toISOString();

  for (const journalDoc of journalSnapshot.docs) {
    const journalId = journalDoc.id;
    const memberId = `${journalId}_${userId}`;
    const ref = firestore.collection(JOURNAL_MEMBERS_COLLECTION).doc(memberId);

    batch.set(ref, {
      id: memberId,
      journalId,
      userId,
      ownerId,
      role,
      joinedAt: now,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    }, { merge: true });
  }

  if (journalSnapshot.size > 0) {
    await batch.commit();
    logger.info(`Propagated team member ${userId} to ${journalSnapshot.size} journals for team ${teamId}`);
  }
}

async function removeUserFromTeamJournals(teamId: string, userId: string): Promise<void> {
  // Find team owner to discover journals.
  const teamDoc = await firestore.collection('teams').doc(teamId).get();
  if (!teamDoc.exists) return;
  const ownerId = teamDoc.data()?.ownerId as string | undefined;
  if (!ownerId) return;

  const journalSnapshot = await firestore
    .collection(USERS_COLLECTION)
    .doc(ownerId)
    .collection(JOURNALS_COLLECTION)
    .where('teamId', '==', teamId)
    .get();

  const batch = firestore.batch();
  const now = new Date().toISOString();

  for (const journalDoc of journalSnapshot.docs) {
    const memberId = `${journalDoc.id}_${userId}`;
    const ref = firestore.collection(JOURNAL_MEMBERS_COLLECTION).doc(memberId);
    batch.set(ref, {
      deletedAt: now,
      updatedAt: now,
    }, { merge: true });
  }

  if (journalSnapshot.size > 0) {
    await batch.commit();
    logger.info(`Removed team member ${userId} from ${journalSnapshot.size} journals for team ${teamId}`);
  }
}

type InviteType = 'team' | 'journal';
type InviteStatus = 'pending' | 'accepted' | 'rejected' | 'expired';
export type InviteNotificationType =
  | 'invite_received'
  | 'invite_accepted'
  | 'invite_rejected';
export type FriendNotificationType =
  | 'friend_request_received'
  | 'friend_request_accepted';

export interface InviteDoc {
  id?: string;
  type?: InviteType;
  targetId?: string;
  inviterId?: string;
  inviteeId?: string | null;
  status?: InviteStatus;
}

export interface UserDoc {
  friends?: unknown;
  receivedFriendRequests?: unknown;
  sentFriendRequests?: unknown;
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

export const onUserUpdated = onDocumentUpdated(
  `${USERS_COLLECTION}/{userId}`,
  async (event) => {
    const userId = event.params.userId;
    const before = event.data?.before.data() as UserDoc | undefined;
    const after = event.data?.after.data() as UserDoc | undefined;
    if (!before || !after) {
      return;
    }

    try {
      await processUserUpdated(userId, before, after, event.id, runtimeContext);
    } catch (error) {
      logger.error('onUserUpdated failed', { userId, eventId: event.id, error });
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

export async function processUserUpdated(
  userId: string,
  before: UserDoc,
  after: UserDoc,
  eventId: string,
  context: NotificationContext,
): Promise<void> {
  const beforeReceived = normalizeUidList(before.receivedFriendRequests);
  const afterReceived = normalizeUidList(after.receivedFriendRequests);
  const newlyReceivedRequesters = getAddedUids(beforeReceived, afterReceived).filter(
    (actorUid) => actorUid !== userId,
  );

  for (const actorUid of newlyReceivedRequesters) {
    await dispatchFriendNotification({
      context,
      recipientUid: userId,
      actorUid,
      notificationType: 'friend_request_received',
      notificationId: buildFriendNotificationId(
        eventId,
        'friend_request_received',
        actorUid,
      ),
    });
  }

  const beforeFriends = normalizeUidList(before.friends);
  const afterFriends = normalizeUidList(after.friends);
  const beforeSentSet = new Set(normalizeUidList(before.sentFriendRequests));
  const afterSentSet = new Set(normalizeUidList(after.sentFriendRequests));
  const acceptedBy = getAddedUids(beforeFriends, afterFriends).filter(
    (actorUid) =>
      actorUid !== userId &&
      beforeSentSet.has(actorUid) &&
      !afterSentSet.has(actorUid),
  );

  for (const actorUid of acceptedBy) {
    await dispatchFriendNotification({
      context,
      recipientUid: userId,
      actorUid,
      notificationType: 'friend_request_accepted',
      notificationId: buildFriendNotificationId(
        eventId,
        'friend_request_accepted',
        actorUid,
      ),
    });
  }
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

interface DispatchFriendNotificationParams {
  context: NotificationContext;
  recipientUid: string;
  actorUid: string;
  notificationType: FriendNotificationType;
  notificationId: string;
}

async function dispatchFriendNotification(
  params: DispatchFriendNotificationParams,
): Promise<void> {
  const { context, recipientUid, actorUid, notificationType, notificationId } =
    params;

  const preferredLanguage = normalizeLanguage(
    await context.getUserPreferredLanguage(recipientUid),
  );
  const actorName =
    (await context.getUserDisplayName(actorUid)) ??
    fallbackActorName(preferredLanguage);
  const text = buildFriendNotificationText({
    type: notificationType,
    language: preferredLanguage,
    actorName,
  });

  const notificationPayload: Record<string, unknown> = {
    id: notificationId,
    type: notificationType,
    title: text.title,
    body: text.body,
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
    actorId: actorUid,
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

export function buildFriendNotificationId(
  eventId: string,
  notificationType: FriendNotificationType,
  actorUid: string,
): string {
  const safeEventId = sanitizeIdPart(eventId);
  const safeActorUid = sanitizeIdPart(actorUid);
  return `friend_${safeEventId}_${notificationType.replace(
    'friend_request_',
    '',
  )}_${safeActorUid}`;
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

export function buildFriendNotificationText(params: {
  type: FriendNotificationType;
  language: 'tr' | 'en';
  actorName: string;
}): NotificationText {
  const { type, language, actorName } = params;

  if (language === 'en') {
    switch (type) {
      case 'friend_request_received':
        return {
          title: 'New friend request',
          body: `${actorName} sent you a friend request.`,
        };
      case 'friend_request_accepted':
        return {
          title: 'Friend request accepted',
          body: `${actorName} accepted your friend request.`,
        };
    }
  }

  switch (type) {
    case 'friend_request_received':
      return {
        title: 'Yeni arkadaşlık isteği',
        body: `${actorName} size arkadaşlık isteği gönderdi.`,
      };
    case 'friend_request_accepted':
      return {
        title: 'Arkadaşlık isteği kabul edildi',
        body: `${actorName} arkadaşlık isteğinizi kabul etti.`,
      };
  }
}

function fallbackActorName(language: 'tr' | 'en'): string {
  return language === 'en' ? 'Someone' : 'Bir kullanıcı';
}

function normalizeUidList(raw: unknown): string[] {
  if (!Array.isArray(raw)) {
    return [];
  }
  const values = raw.filter(
    (entry): entry is string => typeof entry === 'string' && entry.length > 0,
  );
  return [...new Set(values)];
}

function getAddedUids(before: string[], after: string[]): string[] {
  const beforeSet = new Set(before);
  return after.filter((uid) => !beforeSet.has(uid));
}

function sanitizeIdPart(raw: string): string {
  return raw.replace(/[^a-zA-Z0-9_-]/g, '_');
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
