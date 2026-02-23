class FirestorePaths {
  const FirestorePaths._();

  static const String users = 'users';
  static const String journals = 'journals';
  static const String pages = 'pages';
  static const String blocks = 'blocks';
  static const String teams = 'teams';
  static const String teamMembers = 'team_members';
  static const String invites = 'invites';
  static const String userStickers = 'user_stickers';
  static const String oplogs = 'oplogs';
  static const String usernames = 'usernames';
  static const String displayIds = 'displayIds';
  static const String pushTokens = 'push_tokens';
  static const String notifications = 'notifications';

  static String userDoc(String uid) => '$users/$uid';
  static String journalDoc(String uid, String journalId) =>
      '${userDoc(uid)}/$journals/$journalId';
  static String pageDoc(String uid, String journalId, String pageId) =>
      '${journalDoc(uid, journalId)}/$pages/$pageId';
  static String blockDoc(String uid, String blockId) =>
      '${userDoc(uid)}/$blocks/$blockId';
  static String userPushTokenDoc(String uid, String deviceId) =>
      '${userDoc(uid)}/$pushTokens/$deviceId';
  static String userNotificationDoc(String uid, String notificationId) =>
      '${userDoc(uid)}/$notifications/$notificationId';
}
