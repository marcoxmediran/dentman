import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/patient.dart';
import '../models/appointment.dart';
import '../models/treatment.dart';
import '../models/dentist.dart';
import 'database_repository.dart';

class MockDatabaseRepository implements DatabaseRepository {
  final _uuid = const Uuid();

  // In-memory data stores
  final List<Patient> _patients = [];
  final List<Appointment> _appointments = [];
  final List<Treatment> _treatments = [];
  final List<Dentist> _dentists = [];

  // StreamControllers to simulate real-time updates
  final _patientsController = StreamController<List<Patient>>.broadcast();
  final _appointmentsController =
      StreamController<List<Appointment>>.broadcast();
  final _dentistsController = StreamController<List<Dentist>>.broadcast();
  // We can track individual patient treatment stream controllers if we want, or keep a map
  final _treatmentControllers = <String, StreamController<List<Treatment>>>{};

  MockDatabaseRepository() {
    _populateSeedData();
  }

  void _populateSeedData() {
    // Generate IDs
    final p1Id = _uuid.v4();
    final p2Id = _uuid.v4();
    final p3Id = _uuid.v4();

    // 0. Add Dentists
    _dentists.addAll([
      Dentist(id: '1', name: 'Dr. Alex Carter'),
      Dentist(id: '2', name: 'Dr. Jordan Lee'),
    ]);

    // 1. Add Patients
    _patients.addAll([
      Patient(
        id: p1Id,
        fullName: 'John Doe',
        dob: DateTime(1985, 5, 12),
        gender: 'Male',
        phone: '01234567890',
        homeAddress: '123 Main St, Cityville',
        medicalHistory:
            'Penicillin allergy. High blood pressure under control.',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Patient(
        id: p2Id,
        fullName: 'Jane Smith',
        dob: DateTime(1992, 10, 22),
        gender: 'Female',
        phone: '01499982384',
        homeAddress: '456 Oak Lane, Townsville',
        medicalHistory:
            'No known drug allergies. Currently pregnant (2nd trimester).',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Patient(
        id: p3Id,
        fullName: 'Robert Johnson',
        dob: DateTime(1960, 2, 8),
        gender: 'Male',
        phone: '92030174455',
        homeAddress: '789 Pine Road, Metrocity',
        medicalHistory:
            'Type 2 Diabetes. Takes Metformin. Blood thinners (aspirin).',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ]);

    // 2. Add Treatments (Past)
    _treatments.addAll([
      Treatment(
        id: _uuid.v4(),
        patientId: p1Id,
        dentistName: 'Dr. Alex Carter',
        category: 'Cleaning',
        notes: 'Routine scaling and polishing. No cavities detected.',
        cost: 1000.00,
        date: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Treatment(
        id: _uuid.v4(),
        patientId: p1Id,
        dentistName: 'Dr. Alex Carter',
        category: 'Filling',
        notes: 'Composite resin filling on Tooth #14 (occlusal).',
        cost: 1500.00,
        date: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Treatment(
        id: _uuid.v4(),
        patientId: p2Id,
        dentistName: 'Dr. Jordan Lee',
        category: 'Consultation',
        notes:
            'Initial checkup and emergency consultation for minor tooth pain on lower left.',
        cost: 500.00,
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Treatment(
        id: _uuid.v4(),
        patientId: p3Id,
        dentistName: 'Dr. Jordan Lee',
        category: 'Extraction',
        notes:
            'Surgical extraction of Tooth #32 (impacted wisdom tooth). Hemostasis achieved.',
        cost: 1000.00,
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);

    // 3. Add Appointments
    _appointments.addAll([
      // Past Completed Appointments
      Appointment(
        id: _uuid.v4(),
        patientId: p1Id,
        patientName: 'John Doe',
        dateTime: DateTime.now().subtract(const Duration(days: 15, hours: 2)),
        status: 'completed',
        notes: 'Scaling & Filling on Tooth #14.',
      ),
      Appointment(
        id: _uuid.v4(),
        patientId: p3Id,
        patientName: 'Robert Johnson',
        dateTime: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
        status: 'completed',
        notes: 'Tooth #32 Extraction follow-up.',
      ),
      // Upcoming Appointments
      Appointment(
        id: _uuid.v4(),
        patientId: p2Id,
        patientName: 'Jane Smith',
        dateTime: DateTime.now().add(const Duration(days: 2, hours: 3)),
        status: 'scheduled',
        notes:
            'Routine prophylaxis and soft tissue check. Patient is pregnant, avoid X-rays.',
      ),
      Appointment(
        id: _uuid.v4(),
        patientId: p1Id,
        patientName: 'John Doe',
        dateTime: DateTime.now().add(const Duration(days: 5, hours: 1)),
        status: 'scheduled',
        notes: 'Check filling integrity and sensitivity check on Tooth #14.',
      ),
      Appointment(
        id: _uuid.v4(),
        patientId: p3Id,
        patientName: 'Robert Johnson',
        dateTime: DateTime.now().add(const Duration(days: 12, hours: 4)),
        status: 'scheduled',
        notes: 'Root Canal therapy initiation on Tooth #19.',
      ),
    ]);

    // Push initial states
    _notifyPatients();
    _notifyAppointments();
    _notifyDentists();
  }

  // Helper methods to update streams
  void _notifyDentists() {
    _dentistsController.add(List.unmodifiable(_dentists));
  }

  void _notifyPatients() {
    _patientsController.add(List.unmodifiable(_patients));
  }

  void _notifyAppointments() {
    // Sort appointments: Scheduled (closest first) then Completed (most recent first)
    _appointments.sort((a, b) {
      if (a.status == 'scheduled' && b.status != 'scheduled') return -1;
      if (a.status != 'scheduled' && b.status == 'scheduled') return 1;
      if (a.status == 'scheduled') {
        return a.dateTime.compareTo(b.dateTime); // Ascending for upcoming
      } else {
        return b.dateTime.compareTo(a.dateTime); // Descending for past
      }
    });
    _appointmentsController.add(List.unmodifiable(_appointments));
  }

  void _notifyTreatmentsForPatient(String patientId) {
    if (_treatmentControllers.containsKey(patientId)) {
      final patientTreatments = _treatments
          .where((t) => t.patientId == patientId)
          .toList();
      patientTreatments.sort(
        (a, b) => b.date.compareTo(a.date),
      ); // Newest first
      _treatmentControllers[patientId]!.add(
        List.unmodifiable(patientTreatments),
      );
    }
  }

  // --- DatabaseRepository Implementation ---

  @override
  Stream<List<Patient>> watchPatients() {
    // Return stream, but immediately trigger first emit
    Timer.run(() => _notifyPatients());
    return _patientsController.stream;
  }

  @override
  Future<List<Patient>> getPatients() async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate latency
    return List.unmodifiable(_patients);
  }

  @override
  Future<String> addPatient(Patient patient) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newId = _uuid.v4();
    final newPatient = patient.copyWith(id: newId);
    _patients.add(newPatient);
    _notifyPatients();
    return newId;
  }

  @override
  Future<void> updatePatient(Patient patient) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _patients.indexWhere((p) => p.id == patient.id);
    if (index != -1) {
      _patients[index] = patient;
      _notifyPatients();

      // Update patient name in appointments denormalized field if changed
      final appointmentsToUpdate = _appointments
          .where((a) => a.patientId == patient.id)
          .toList();
      for (var app in appointmentsToUpdate) {
        final appIndex = _appointments.indexOf(app);
        _appointments[appIndex] = app.copyWith(patientName: patient.fullName);
      }
      if (appointmentsToUpdate.isNotEmpty) {
        _notifyAppointments();
      }
    }
  }

  @override
  Future<Patient?> getPatientById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Appointment>> watchAppointments() {
    Timer.run(() => _notifyAppointments());
    return _appointmentsController.stream;
  }

  @override
  Future<List<Appointment>> getAppointmentsForPatient(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _appointments.where((a) => a.patientId == patientId).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  Future<void> addAppointment(Appointment appointment) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newApp = appointment.copyWith(id: _uuid.v4());
    _appointments.add(newApp);
    _notifyAppointments();
  }

  @override
  Future<void> updateAppointment(Appointment appointment) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _appointments.indexWhere((a) => a.id == appointment.id);
    if (index != -1) {
      _appointments[index] = appointment;
      _notifyAppointments();
    }
  }

  @override
  Stream<List<Treatment>> watchTreatmentsForPatient(String patientId) {
    if (!_treatmentControllers.containsKey(patientId)) {
      _treatmentControllers[patientId] =
          StreamController<List<Treatment>>.broadcast();
    }
    Timer.run(() => _notifyTreatmentsForPatient(patientId));
    return _treatmentControllers[patientId]!.stream;
  }

  @override
  Future<List<Treatment>> getTreatmentsForPatient(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _treatments.where((t) => t.patientId == patientId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> addTreatment(Treatment treatment) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newTreatment = treatment.copyWith(id: _uuid.v4());
    _treatments.add(newTreatment);
    _notifyTreatmentsForPatient(treatment.patientId);
  }

  @override
  Future<void> deleteAppointment(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _appointments.removeWhere((a) => a.id == id);
    _notifyAppointments();
  }

  @override
  Future<void> updateTreatment(Treatment treatment) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _treatments.indexWhere((t) => t.id == treatment.id);
    if (index != -1) {
      _treatments[index] = treatment;
      _notifyTreatmentsForPatient(treatment.patientId);
    }
  }

  @override
  Future<void> deleteTreatment(String id, String patientId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _treatments.removeWhere((t) => t.id == id);
    _notifyTreatmentsForPatient(patientId);
  }

  // --- Dentist CRUD Implementation ---
  @override
  Stream<List<Dentist>> watchDentists() {
    Timer.run(() => _notifyDentists());
    return _dentistsController.stream;
  }

  @override
  Future<List<Dentist>> getDentists() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_dentists);
  }

  @override
  Future<void> addDentist(Dentist dentist) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newDentist = dentist.copyWith(id: _uuid.v4());
    _dentists.add(newDentist);
    _notifyDentists();
  }

  @override
  Future<void> updateDentist(Dentist dentist) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _dentists.indexWhere((d) => d.id == dentist.id);
    if (index != -1) {
      _dentists[index] = dentist;
      _notifyDentists();
    }
  }

  @override
  Future<void> deleteDentist(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _dentists.removeWhere((d) => d.id == id);
    _notifyDentists();
  }
}
