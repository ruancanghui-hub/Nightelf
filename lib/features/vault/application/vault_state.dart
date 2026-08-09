import 'package:ai_workbench/features/vault/domain/resource_record.dart';
import 'package:ai_workbench/features/vault/domain/vault_handle.dart';

sealed class VaultState {
  const VaultState();
}

final class VaultClosed extends VaultState {
  const VaultClosed();
}

final class VaultOpening extends VaultState {
  const VaultOpening();
}

final class VaultOpen extends VaultState {
  const VaultOpen({required this.handle, required this.resources});

  final VaultHandle handle;
  final List<ResourceRecord> resources;
}

final class VaultFailure extends VaultState {
  const VaultFailure(this.message);

  final String message;
}
