import { describe, expect, test } from 'vitest';

import {
  buildFriendNotificationId,
  buildFriendNotificationText,
  buildNotificationId,
  buildNotificationText,
  normalizeLanguage,
  processInviteCreated,
  processInviteUpdated,
  type InviteDoc,
  type NotificationContext,
  type PushMessagePayload,
  type PushToken,
  type UserDoc,
  processUserUpdated,
} from './index';

class FakeContext implements NotificationContext {
  preferredLanguage = new Map<string, string>();
  displayNames = new Map<string, string>();
  notifications = new Map<string, Record<string, unknown>>();
  pushTokens = new Map<string, PushToken[]>();
  sentPushes: PushMessagePayload[] = [];
  invalidDeviceIds = new Set<string>();
  removedDeviceIds: string[] = [];

  async getUserPreferredLanguage(uid: string): Promise<string | null> {
    return this.preferredLanguage.get(uid) ?? null;
  }

  async getUserDisplayName(uid: string): Promise<string | null> {
    return this.displayNames.get(uid) ?? null;
  }

  async createNotification(
    recipientUid: string,
    notificationId: string,
    payload: Record<string, unknown>,
  ): Promise<boolean> {
    const key = `${recipientUid}/${notificationId}`;
    if (this.notifications.has(key)) {
      return false;
    }
    this.notifications.set(key, payload);
    return true;
  }

  async listPushTokens(recipientUid: string): Promise<PushToken[]> {
    return this.pushTokens.get(recipientUid) ?? [];
  }

  async sendPush(
    tokens: PushToken[],
    payload: PushMessagePayload,
  ): Promise<string[]> {
    this.sentPushes.push(payload);
    return tokens
      .filter((token) => this.invalidDeviceIds.has(token.deviceId))
      .map((token) => token.deviceId);
  }

  async removePushTokens(
    recipientUid: string,
    deviceIds: string[],
  ): Promise<void> {
    const currentTokens = this.pushTokens.get(recipientUid) ?? [];
    const nextTokens = currentTokens.filter(
      (token) => !deviceIds.includes(token.deviceId),
    );
    this.pushTokens.set(recipientUid, nextTokens);
    this.removedDeviceIds.push(...deviceIds);
  }
}

function invite(overrides: Partial<InviteDoc> = {}): InviteDoc {
  return {
    id: 'inv_1',
    type: 'team',
    targetId: 'team_1',
    inviterId: 'user_inviter',
    inviteeId: 'user_invitee',
    status: 'pending',
    ...overrides,
  };
}

function userDoc(overrides: Partial<UserDoc> = {}): UserDoc {
  return {
    friends: [],
    receivedFriendRequests: [],
    sentFriendRequests: [],
    ...overrides,
  };
}

describe('notification helpers', () => {
  test('buildNotificationId uses stable contract', () => {
    expect(buildNotificationId('abc', 'invite_received')).toBe(
      'invite_abc_received',
    );
    expect(buildNotificationId('abc', 'invite_accepted')).toBe(
      'invite_abc_accepted',
    );
  });

  test('normalizeLanguage resolves supported values with fallback', () => {
    expect(normalizeLanguage('tr')).toBe('tr');
    expect(normalizeLanguage('en-US')).toBe('en');
    expect(normalizeLanguage('de')).toBe('tr');
    expect(normalizeLanguage(null)).toBe('tr');
  });

  test('buildNotificationText localizes by language and status', () => {
    const tr = buildNotificationText({
      type: 'invite_received',
      language: 'tr',
      actorName: 'Ayşe',
      inviteType: 'team',
    });
    expect(tr.title).toBe('Yeni davet');
    expect(tr.body).toContain('Ayşe');

    const en = buildNotificationText({
      type: 'invite_rejected',
      language: 'en',
      actorName: 'Alex',
      inviteType: 'journal',
    });
    expect(en.title).toBe('Invite declined');
    expect(en.body).toContain('Alex');
  });

  test('friend notification helpers build stable ids and text', () => {
    const id = buildFriendNotificationId(
      'evt/123',
      'friend_request_received',
      'user_a',
    );
    expect(id).toBe('friend_evt_123_received_user_a');

    const tr = buildFriendNotificationText({
      type: 'friend_request_received',
      language: 'tr',
      actorName: 'Ayşe',
    });
    expect(tr.title).toBe('Yeni arkadaşlık isteği');
    expect(tr.body).toContain('Ayşe');

    const en = buildFriendNotificationText({
      type: 'friend_request_accepted',
      language: 'en',
      actorName: 'Alex',
    });
    expect(en.title).toBe('Friend request accepted');
    expect(en.body).toContain('Alex');
  });
});

describe('invite notification workflows', () => {
  test('processInviteCreated creates inbox doc and sends push', async () => {
    const context = new FakeContext();
    context.preferredLanguage.set('user_invitee', 'en');
    context.displayNames.set('user_inviter', 'Alex');
    context.pushTokens.set('user_invitee', [
      { deviceId: 'device_1', token: 'token_1' },
      { deviceId: 'device_2', token: 'token_2' },
    ]);

    await processInviteCreated('inv_1', invite(), context);

    const notification = context.notifications.get(
      'user_invitee/invite_inv_1_received',
    );
    expect(notification).toBeDefined();
    expect(notification?.type).toBe('invite_received');
    expect(notification?.title).toBe('New invite');
    expect(notification?.route).toBe('/notifications');

    expect(context.sentPushes).toHaveLength(1);
    expect(context.sentPushes[0].data.notificationId).toBe(
      'invite_inv_1_received',
    );
  });

  test('processInviteUpdated creates accepted notification for inviter', async () => {
    const context = new FakeContext();
    context.preferredLanguage.set('user_inviter', 'tr');
    context.displayNames.set('user_invitee', 'Zeynep');
    context.pushTokens.set('user_inviter', [
      { deviceId: 'device_1', token: 'token_1' },
    ]);

    await processInviteUpdated(
      'inv_2',
      invite({ status: 'pending' }),
      invite({ status: 'accepted' }),
      context,
    );

    const notification = context.notifications.get(
      'user_inviter/invite_inv_2_accepted',
    );
    expect(notification).toBeDefined();
    expect(notification?.type).toBe('invite_accepted');
    expect(notification?.title).toBe('Davet kabul edildi');
  });

  test('idempotency skips duplicate document and push', async () => {
    const context = new FakeContext();
    context.preferredLanguage.set('user_invitee', 'tr');
    context.displayNames.set('user_inviter', 'Berk');
    context.pushTokens.set('user_invitee', [
      { deviceId: 'device_1', token: 'token_1' },
    ]);

    await processInviteCreated('inv_dupe', invite({ id: 'inv_dupe' }), context);
    await processInviteCreated('inv_dupe', invite({ id: 'inv_dupe' }), context);

    expect(context.notifications.size).toBe(1);
    expect(context.sentPushes).toHaveLength(1);
  });

  test('invalid push tokens are removed after send attempt', async () => {
    const context = new FakeContext();
    context.preferredLanguage.set('user_invitee', 'en');
    context.displayNames.set('user_inviter', 'Alex');
    context.pushTokens.set('user_invitee', [
      { deviceId: 'device_1', token: 'token_1' },
      { deviceId: 'device_2', token: 'token_2' },
    ]);
    context.invalidDeviceIds.add('device_2');

    await processInviteCreated('inv_invalid', invite({ id: 'inv_invalid' }), context);

    expect(context.removedDeviceIds).toContain('device_2');
    expect(context.pushTokens.get('user_invitee')).toHaveLength(1);
  });
});

describe('friend notification workflows', () => {
  test('processUserUpdated creates friend request received notification', async () => {
    const context = new FakeContext();
    context.preferredLanguage.set('user_target', 'tr');
    context.displayNames.set('user_sender', 'Ayşe');
    context.pushTokens.set('user_target', [
      { deviceId: 'device_1', token: 'token_1' },
    ]);

    await processUserUpdated(
      'user_target',
      userDoc(),
      userDoc({ receivedFriendRequests: ['user_sender'] }),
      'evt_received_1',
      context,
    );

    const notificationId = buildFriendNotificationId(
      'evt_received_1',
      'friend_request_received',
      'user_sender',
    );
    const notification = context.notifications.get(
      `user_target/${notificationId}`,
    );
    expect(notification).toBeDefined();
    expect(notification?.type).toBe('friend_request_received');
    expect(notification?.title).toBe('Yeni arkadaşlık isteği');
    expect(context.sentPushes).toHaveLength(1);
    expect(context.sentPushes[0].data.notificationId).toBe(notificationId);
  });

  test('processUserUpdated creates accepted notification for requester', async () => {
    const context = new FakeContext();
    context.preferredLanguage.set('user_requester', 'en');
    context.displayNames.set('user_accepter', 'Alex');
    context.pushTokens.set('user_requester', [
      { deviceId: 'device_1', token: 'token_1' },
    ]);

    await processUserUpdated(
      'user_requester',
      userDoc({ sentFriendRequests: ['user_accepter'] }),
      userDoc({ friends: ['user_accepter'] }),
      'evt_accepted_1',
      context,
    );

    const notificationId = buildFriendNotificationId(
      'evt_accepted_1',
      'friend_request_accepted',
      'user_accepter',
    );
    const notification = context.notifications.get(
      `user_requester/${notificationId}`,
    );
    expect(notification).toBeDefined();
    expect(notification?.type).toBe('friend_request_accepted');
    expect(notification?.title).toBe('Friend request accepted');
  });

  test('processUserUpdated ignores request cancellation and rejection', async () => {
    const context = new FakeContext();
    context.preferredLanguage.set('user_requester', 'tr');
    context.displayNames.set('user_other', 'Mert');
    context.pushTokens.set('user_requester', [
      { deviceId: 'device_1', token: 'token_1' },
    ]);

    await processUserUpdated(
      'user_requester',
      userDoc({ sentFriendRequests: ['user_other'] }),
      userDoc(),
      'evt_cancel_1',
      context,
    );

    expect(context.notifications.size).toBe(0);
    expect(context.sentPushes).toHaveLength(0);
  });

  test('friend notifications are idempotent per event id', async () => {
    const context = new FakeContext();
    context.preferredLanguage.set('user_target', 'en');
    context.displayNames.set('user_sender', 'Alex');
    context.pushTokens.set('user_target', [
      { deviceId: 'device_1', token: 'token_1' },
    ]);

    const before = userDoc();
    const after = userDoc({ receivedFriendRequests: ['user_sender'] });
    await processUserUpdated('user_target', before, after, 'evt_dupe_1', context);
    await processUserUpdated('user_target', before, after, 'evt_dupe_1', context);

    expect(context.notifications.size).toBe(1);
    expect(context.sentPushes).toHaveLength(1);
  });
});
