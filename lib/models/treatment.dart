import 'package:cloud_firestore/cloud_firestore.dart';

class Treatment {
  final String id;
  final String patientId;
  final String dentistName;
  final String category;
  final String notes;
  final double cost;
  final DateTime date;

  Treatment({
    required this.id,
    required this.patientId,
    required this.dentistName,
    required this.category,
    required this.notes,
    required this.cost,
    required this.date,
  });

  Treatment copyWith({
    String? id,
    String? patientId,
    String? dentistName,
    String? category,
    String? notes,
    double? cost,
    DateTime? date,
  }) {
    return Treatment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      dentistName: dentistName ?? this.dentistName,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      cost: cost ?? this.cost,
      date: date ?? this.date,
    );
  }

  factory Treatment.fromJson(Map<String, dynamic> json, String documentId) {
    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) {
        return val.toDate();
      } else if (val is String) {
        return DateTime.parse(val);
      } else {
        return DateTime.now();
      }
    }

    return Treatment(
      id: documentId,
      patientId: json['patientId'] ?? '',
      dentistName: json['dentistName'] ?? '',
      category: json['category'] ?? '',
      notes: json['notes'] ?? '',
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      date: parseDateTime(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'dentistName': dentistName,
      'category': category,
      'notes': notes,
      'cost': cost,
      'date': Timestamp.fromDate(date),
    };
  }
}
