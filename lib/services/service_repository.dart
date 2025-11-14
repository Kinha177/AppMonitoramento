import '../database/app_database.dart';
import '../models/service_model.dart';

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
}
