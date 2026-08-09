/// The identifying metadata stored at a Vault's root.
class VaultManifest {
  const VaultManifest({
    required this.version,
    required this.id,
    required this.name,
  });

  final int version;
  final String id;
  final String name;

  factory VaultManifest.fromJson(Map<String, Object?> json) => VaultManifest(
    version: json['version']! as int,
    id: json['id']! as String,
    name: json['name']! as String,
  );

  Map<String, Object?> toJson() => {'version': version, 'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      other is VaultManifest &&
      other.version == version &&
      other.id == id &&
      other.name == name;

  @override
  int get hashCode => Object.hash(version, id, name);
}
