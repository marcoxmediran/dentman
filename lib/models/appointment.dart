import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime dateTime;
  final String status;
  final String notes;

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.dateTime,
    required this.status,
    required this.notes,
  });

  Appointment copyWith({
    String? id,
    String? patientId,
    String? patientName,
    DateTime? dateTime,
    String? status,
    String? notes,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  factory Appointment.fromJson(Map<String, dynamic> json, String documentId) {
    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) {
        return val.toDate();
      } else if (val is String) {
        return DateTime.parse(val);
      } else {
        return DateTime.now();
      }
    }

    return Appointment(
      id: documentId,
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      dateTime: parseDateTime(json['dateTime']),
      status: json['status'] ?? 'scheduled',
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status,
      'notes': notes,
    };
  }
}
