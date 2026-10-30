import '../entities/blocking_config.dart';

/// Contract for the native watcher.
///
/// `sync` both stores the configuration and (re)starts the foreground service;
/// `stop` is called when there is nothing to enforce or the user clears the
/// limit and app selection.
abstract interface class BlockingRepository {
  Future<void> sync(BlockingConfig config);

  Future<void> stop();
}
