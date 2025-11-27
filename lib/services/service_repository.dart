import '../database/app_database.dart';
import '../models/service_model.dart';
import '../models/service_log_model.dart'; // Importe o novo modelo

class ServiceRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<int> addService(ServiceModel service) async {
    return await _db.createService(service);
  }

  Future<List<ServiceModel>> getServices(int userId) async {
    return await _db.getServicesByUserId(userId);
  }

  Future<ServiceModel?> getServiceById(int id) async {
    return await _db.getServiceById(id);
  }

  Future<void> updateService(ServiceModel service) async {
    await _db.updateService(service);
  }

  Future<void> deleteService(int id) async {
    await _db.deleteService(id);
  }

  // --- Novos Métodos ---
  Future<void> addLog(ServiceLogModel log) async {
    await _db.insertLog(log);
  }

  Future<List<ServiceLogModel>> getLogs(int serviceId) async {
    return await _db.getLogsByServiceId(serviceId);
  }
}