import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../domain/entities/permission_snapshot.dart';

/// Loads and refreshes the permission snapshot.
///
/// Every permission is granted in a system screen outside the app, so the only
/// way to know the new state is to re-check it — screens call [refresh] when
/// the app resumes.
class PermissionsController extends AsyncNotifier<PermissionSnapshot> {
  @override
  Future<PermissionSnapshot> build() =>
      ref.watch(permissionsRepositoryProvider).getStatus();

  Future<void> refresh() async {
    final repository = ref.read(permissionsRepositoryProvider);
    state = await AsyncValue.guard(repository.getStatus);
  }

  Future<void> openSettings(PermissionKind kind) =>
      ref.read(permissionsRepositoryProvider).openSettings(kind);
}

final permissionsControllerProvider =
    AsyncNotifierProvider<PermissionsController, PermissionSnapshot>(
      PermissionsController.new,
    );
