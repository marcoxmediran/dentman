import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/database_repository.dart';
import '../repositories/mock_database_repository.dart';
import '../repositories/firestore_database_repository.dart';
import '../models/patient.dart';
import '../models/appointment.dart';
import '../models/treatment.dart';
import '../models/dentist.dart';

// StateProvider to toggle between Mock and Live Firebase Database
final useMockDatabaseProvider = StateProvider<bool>((ref) => true);

// Expose the active DatabaseRepository based on the toggle
final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  final useMock = ref.watch(useMockDatabaseProvider);
  if (useMock) {
    // We keep a single instance of MockDatabaseRepository cached by Riverpod
    return ref.watch(_mockDatabaseRepositoryProvider);
  } else {
    return ref.watch(_firestoreDatabaseRepositoryProvider);
  }
});

// Cache individual repository instances
final _mockDatabaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  return MockDatabaseRepository();
});

final _firestoreDatabaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  return FirestoreDatabaseRepository();
});

// Stream Providers
final patientsStreamProvider = StreamProvider<List<Patient>>((ref) {
  final repository = ref.watch(databaseRepositoryProvider);
  return repository.watchPatients();
});

final appointmentsStreamProvider = StreamProvider<List<Appointment>>((ref) {
  final repository = ref.watch(databaseRepositoryProvider);
  return repository.watchAppointments();
});

final patientTreatmentsStreamProvider = StreamProvider.family<List<Treatment>, String>((ref, patientId) {
  final repository = ref.watch(databaseRepositoryProvider);
  return repository.watchTreatmentsForPatient(patientId);
});

final allTreatmentsStreamProvider = StreamProvider<List<Treatment>>((ref) {
  final repository = ref.watch(databaseRepositoryProvider);
  return repository.watchAllTreatments();
});

// Future Providers
final patientAppointmentsFutureProvider = FutureProvider.family<List<Appointment>, String>((ref, patientId) {
  final repository = ref.watch(databaseRepositoryProvider);
  return repository.getAppointmentsForPatient(patientId);
});

final dentistsStreamProvider = StreamProvider<List<Dentist>>((ref) {
  final repository = ref.watch(databaseRepositoryProvider);
  return repository.watchDentists();
});
