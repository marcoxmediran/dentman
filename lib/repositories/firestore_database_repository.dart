import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';
import '../models/appointment.dart';
import '../models/treatment.dart';
import '../models/dentist.dart';
import 'database_repository.dart';

class FirestoreDatabaseRepository implements DatabaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _patientsRef =>
      _firestore.collection('patients');

  CollectionReference<Map<String, dynamic>> get _appointmentsRef =>
      _firestore.collection('appointments');

  CollectionReference<Map<String, dynamic>> get _treatmentsRef =>
      _firestore.collection('treatments');

  CollectionReference<Map<String, dynamic>> get _dentistsRef =>
      _firestore.collection('dentists');

  // --- DatabaseRepository Implementation ---

  @override
  Stream<List<Patient>> watchPatients() {
    return _patientsRef
        .orderBy('fullName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Patient.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<List<Patient>> getPatients() async {
    final snapshot = await _patientsRef.orderBy('fullName').get();
    return snapshot.docs
        .map((doc) => Patient.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<String> addPatient(Patient patient) async {
    final docRef = await _patientsRef.add(patient.toJson());
    return docRef.id;
  }

  @override
  Future<void> updatePatient(Patient patient) async {
    // 1. Update the patient document
    await _patientsRef.doc(patient.id).update(patient.toJson());

    // 2. Denormalize: Update patientName in all of this patient's appointments
    final appointmentsQuery = await _appointmentsRef
        .where('patientId', isEqualTo: patient.id)
        .get();

    final batch = _firestore.batch();
    for (var doc in appointmentsQuery.docs) {
      batch.update(doc.reference, {'patientName': patient.fullName});
    }
    await batch.commit();
  }

  @override
  Future<Patient?> getPatientById(String id) async {
    final doc = await _patientsRef.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Patient.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  Stream<List<Appointment>> watchAppointments() {
    // Order by dateTime ascending/descending sorting will be done in memory or client-side
    // or by queries. For standard clinic view: orderBy dateTime
    return _appointmentsRef
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Appointment.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<List<Appointment>> getAppointmentsForPatient(String patientId) async {
    final snapshot = await _appointmentsRef
        .where('patientId', isEqualTo: patientId)
        .orderBy('dateTime', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Appointment.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> addAppointment(Appointment appointment) async {
    await _appointmentsRef.add(appointment.toJson());
  }

  @override
  Future<void> updateAppointment(Appointment appointment) async {
    await _appointmentsRef.doc(appointment.id).update(appointment.toJson());
  }

  @override
  Future<void> deleteAppointment(String id) async {
    await _appointmentsRef.doc(id).delete();
  }

  @override
  Stream<List<Treatment>> watchTreatmentsForPatient(String patientId) {
    return _treatmentsRef
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Treatment.fromJson(doc.data(), doc.id))
          .toList();
      // Firestore requires composite indexes for where + orderBy.
      // To avoid forcing the user to create composite indexes immediately, we sort client-side.
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  @override
  Future<List<Treatment>> getTreatmentsForPatient(String patientId) async {
    final snapshot = await _treatmentsRef
        .where('patientId', isEqualTo: patientId)
        .get();
    final list = snapshot.docs
        .map((doc) => Treatment.fromJson(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Stream<List<Treatment>> watchAllTreatments() {
    return _treatmentsRef.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Treatment.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  @override
  Future<List<Treatment>> getAllTreatments() async {
    final snapshot = await _treatmentsRef.get();
    final list = snapshot.docs
        .map((doc) => Treatment.fromJson(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<void> addTreatment(Treatment treatment) async {
    await _treatmentsRef.add(treatment.toJson());
  }

  @override
  Future<void> updateTreatment(Treatment treatment) async {
    await _treatmentsRef.doc(treatment.id).update(treatment.toJson());
  }

  @override
  Future<void> deleteTreatment(String id, String patientId) async {
    await _treatmentsRef.doc(id).delete();
  }

  // --- Dentist CRUD Implementation ---
  @override
  Stream<List<Dentist>> watchDentists() {
    return _dentistsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Dentist.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<List<Dentist>> getDentists() async {
    final snapshot = await _dentistsRef.get();
    return snapshot.docs
        .map((doc) => Dentist.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> addDentist(Dentist dentist) async {
    await _dentistsRef.add(dentist.toJson());
  }

  @override
  Future<void> updateDentist(Dentist dentist) async {
    await _dentistsRef.doc(dentist.id).update(dentist.toJson());
  }

  @override
  Future<void> deleteDentist(String id) async {
    await _dentistsRef.doc(id).delete();
  }
}
