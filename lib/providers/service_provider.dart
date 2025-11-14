import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../services/service_repository.dart';
import '../services/status_checker.dart';

class ServiceProvider with ChangeNotifier {
  final ServiceRepository _repository = ServiceRepository();
  final StatusChecker _statusChecker = StatusChecker();
  List<ServiceModel> _services = [];
  bool _isLoading = false;

  List<ServiceModel> get services => _services;
  bool get isLoading => _isLoading;

  Future<void> loadServices(int userId) async {
    _isLoading = true;
    notifyListeners();

    _services = await _repository.getServices(userId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addService(ServiceModel service) async {
    await _repository.addService(service);
    await loadServices(service.userId);
  }

  Future<void> updateService(ServiceModel service) async {
    await _repository.updateService(service);
    await loadServices(service.userId);
  }

  Future<void> deleteService(int id, int userId) async {
    await _repository.deleteService(id);
    await loadServices(userId);
  }

  Future<ServiceModel?> getServiceById(int id) async {
    return await _repository.getServiceById(id);
  }

  Future<void> checkServiceStatus(ServiceModel service) async {
    final result = await _statusChecker.checkStatus(service.address);
    final updatedService = service.copyWith(
      lastStatus: result.status,
      lastLatencyMs: result.latencyMs,
    );
    await _repository.updateService(updatedService);
    await loadServices(service.userId);
  }

  Future<StatusCheckResult> checkStatus(String address) async {
    return await _statusChecker.checkStatus(address);
  }
}
