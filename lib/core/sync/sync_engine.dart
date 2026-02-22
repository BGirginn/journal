abstract class SyncBootstrapper {
  Future<void> bootstrapDown();
}

abstract class SyncUploader {
  Future<void> syncUp();
}

abstract class SyncReconciler {
  Future<void> reconcile();
}

abstract class SyncEngine
    implements SyncBootstrapper, SyncUploader, SyncReconciler {
  Future<void> startSyncLoop();
  void stopSyncLoop();
}
