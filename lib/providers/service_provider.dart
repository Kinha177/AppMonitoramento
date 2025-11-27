import 'package:flutter/material.dart';
import '../models/service_model.dart';
// ATENÇÃO: Certifique-se de ter criado o arquivo service_log_model.dart ou remova esta linha e a lógica de logs se não estiver usando.
import '../models/service_log_model.dart'; 
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
    await _checkAndSave(service);
    await loadServices(service.userId);
  }

  // --- Método essencial para o Dashboard ---
  Future<void> checkAllStatuses() async {
    if (_services.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    List<Future> tasks = [];
    for (var service in _services) {
      tasks.add(_checkAndSave(service));
    }

    await Future.wait(tasks);

    if (_services.isNotEmpty) {
      await loadServices(_services.first.userId);
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkAndSave(ServiceModel service) async {
    try {
      final result = await _statusChecker.checkStatus(service.address);
      
      final updatedService = service.copyWith(
        lastStatus: result.status,
        lastLatencyMs: result.latencyMs,
      );
      
      await _repository.updateService(updatedService);

      // Se você não tiver a tabela de logs configurada no banco,
      // comente o bloco abaixo para evitar erros
      if (service.id != null) {
        final log = ServiceLogModel(
          serviceId: service.id!,
          status: result.status,
          latencyMs: result.latencyMs,
          checkedAt: DateTime.now().toIso8601String(),
        );
        await _repository.addLog(log);
      }
    } catch (e) {
      print("Erro ao verificar ${service.name}: $e");
    }
  }

  Future<StatusCheckResult> checkStatus(String address) async {
    return await _statusChecker.checkStatus(address);
  }

  Future<List<ServiceLogModel>> getServiceLogs(int serviceId) async {
    return await _repository.getLogs(serviceId);
  }
}