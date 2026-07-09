import 'package:hive/hive.dart';

enum TriageStatus {
  pending,
  inTransit,
}

class TriageRecord {
  final String id;
  final String patientName;
  final String conditionDescription;
  final int priority;
  final TriageStatus status;
  final DateTime createdAt;
  final bool isSynced;

  TriageRecord({
    required this.id,
    required this.patientName,
    required this.conditionDescription,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.isSynced = false,
  });

  TriageRecord copyWith({
    String? id,
    String? patientName,
    String? conditionDescription,
    int? priority,
    TriageStatus? status,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return TriageRecord(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      conditionDescription: conditionDescription ?? this.conditionDescription,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientName': patientName,
      'conditionDescription': conditionDescription,
      'priority': priority,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory TriageRecord.fromJson(Map<String, dynamic> json) {
    return TriageRecord(
      id: json['id'] as String,
      patientName: json['patientName'] as String,
      conditionDescription: json['conditionDescription'] as String,
      priority: json['priority'] as int,
      status: TriageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TriageStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }
}

class TriageRecordAdapter extends TypeAdapter<TriageRecord> {
  @override
  final int typeId = 0;

  @override
  TriageRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TriageRecord(
      id: fields[0] as String,
      patientName: fields[1] as String,
      conditionDescription: fields[2] as String,
      priority: fields[3] as int,
      status: TriageStatus.values.firstWhere(
        (e) => e.name == (fields[4] as String),
        orElse: () => TriageStatus.pending,
      ),
      createdAt: fields[5] as DateTime,
      isSynced: fields[6] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, TriageRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientName)
      ..writeByte(2)
      ..write(obj.conditionDescription)
      ..writeByte(3)
      ..write(obj.priority)
      ..writeByte(4)
      ..write(obj.status.name)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.isSynced);
  }
}
