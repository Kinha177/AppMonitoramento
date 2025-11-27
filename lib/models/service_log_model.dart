class ServiceLogModel {
  final int? id;
  final int serviceId;
  final String status;
  final int latencyMs;
  final String checkedAt;

  ServiceLogModel({
    this.id,
    required this.serviceId,
    required this.status,
    required this.latencyMs,
    required this.checkedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceId': serviceId,
      'status': status,
      'latencyMs': latencyMs,
      'checkedAt': checkedAt,
    };
  }

  factory ServiceLogModel.fromMap(Map<String, dynamic> map) {
    return ServiceLogModel(
      id: map['id'] as int?,
      serviceId: map['serviceId'] as int,
      status: map['status'] as String,
      latencyMs: map['latencyMs'] as int,
      checkedAt: map['checkedAt'] as String,
    );
  }
}