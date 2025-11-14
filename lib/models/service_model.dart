class ServiceModel {
  final int? id;
  final int userId;
  final String name;
  final String address;
  final String lastStatus;
  final int lastLatencyMs;
  final String createdAt;

  ServiceModel({
    this.id,
    required this.userId,
    required this.name,
    required this.address,
    this.lastStatus = 'Desconhecido',
    this.lastLatencyMs = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'address': address,
      'lastStatus': lastStatus,
      'lastLatencyMs': lastLatencyMs,
      'createdAt': createdAt,
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      name: map['name'] as String,
      address: map['address'] as String,
      lastStatus: map['lastStatus'] as String? ?? 'Desconhecido',
      lastLatencyMs: map['lastLatencyMs'] as int? ?? 0,
      createdAt: map['createdAt'] as String,
    );
  }

  ServiceModel copyWith({
    int? id,
    int? userId,
    String? name,
    String? address,
    String? lastStatus,
    int? lastLatencyMs,
    String? createdAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      address: address ?? this.address,
      lastStatus: lastStatus ?? this.lastStatus,
      lastLatencyMs: lastLatencyMs ?? this.lastLatencyMs,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
