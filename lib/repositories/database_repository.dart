import '../models/patient.dart';
import '../models/appointment.dart';
import '../models/treatment.dart';
import '../models/dentist.dart';

abstract class DatabaseRepository {
  // Patients
  Stream<List<Patient>> watchPatients();
  Future<List<Patient>> getPatients();
  Future<String> addPatient(Patient patient);
  Future<void> updatePatient(Patient patient);
  Future<Patient?> getPatientById(String id);

  // Appointments
  Stream<List<Appointment>> watchAppointments();
  Future<List<Appointment>> getAppointmentsForPatient(String patientId);
  Future<void> addAppointment(Appointment appointment);
  Future<void> updateAppointment(Appointment appointment);
  Future<void> deleteAppointment(String id);

  // Treatments
  Stream<List<Treatment>> watchTreatmentsForPatient(String patientId);
  Future<List<Treatment>> getTreatmentsForPatient(String patientId);
  Future<void> addTreatment(Treatment treatment);
  Future<void> updateTreatment(Treatment treatment);
  Future<void> deleteTreatment(String id, String patientId);

  // Dentists
  Stream<List<Dentist>> watchDentists();
  Future<List<Dentist>> getDentists();
  Future<void> addDentist(Dentist dentist);
  Future<void> updateDentist(Dentist dentist);
  Future<void> deleteDentist(String id);
}
