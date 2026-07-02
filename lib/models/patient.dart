import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String id;
  final String fullName;
  final DateTime dob;
  final String gender;
  final String phone;
  final String homeAddress;
  final String medicalHistory;
  final DateTime createdAt;

  Patient({
    required this.id,
    required this.fullName,
    required this.dob,
    required this.gender,
    required this.phone,
    required this.homeAddress,
    required this.medicalHistory,
    required this.createdAt,
  });

  Patient copyWith({
    String? id,
    String? fullName,
    DateTime? dob,
    String? gender,
    String? phone,
    String? homeAddress,
    String? medicalHistory,
    DateTime? createdAt,
  }) {
    return Patient(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      homeAddress: homeAddress ?? this.homeAddress,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Patient.fromJson(Map<String, dynamic> json, String documentId) {
    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) {
        return val.toDate();
      } else if (val is String) {
        return DateTime.parse(val);
      } else {
        return DateTime.now();
      }
    }

    return Patient(
      id: documentId,
      fullName: json['fullName'] ?? '',
      dob: parseDateTime(json['dob']),
      gender: json['gender'] ?? 'Male',
      phone: json['phone'] ?? '',
      homeAddress: json['homeAddress'] ?? '',
      medicalHistory: json['medicalHistory'] ?? '',
      createdAt: parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'dob': Timestamp.fromDate(dob),
      'gender': gender,
      'phone': phone,
      'homeAddress': homeAddress,
      'medicalHistory': medicalHistory,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
