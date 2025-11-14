import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_model.dart';
import '../providers/auth_provider.dart';
import '../providers/service_provider.dart';
import '../services/ip_api_service.dart';
import '../services/status_checker.dart';
import 'add_edit_service_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceModel service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final IpApiService _ipApiService = IpApiService();
  IpApiData? _ipData;
  bool _isLoadingIpData = true;
  bool _isCheckingStatus = false;
  StatusCheckResult? _statusResult;

  @override
  void initState() {
    super.initState();
    _loadIpData();
    _checkStatus();
  }

  Future<void> _loadIpData() async {
    setState(() {
      _isLoadingIpData = true;
    });

    final data = await _ipApiService.getIpInfo(widget.service.address);

    if (mounted) {
      setState(() {
        _ipData = data;
        _isLoadingIpData = false;
      });
    }
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isCheckingStatus = true;
    });

    final serviceProvider =
        Provider.of<ServiceProvider>(context, listen: false);
    final result = await serviceProvider.checkStatus(widget.service.address);
    await serviceProvider.checkServiceStatus(widget.service);

    if (mounted) {
      setState(() {
        _statusResult = result;
        _isCheckingStatus = false;
      });
    }
  }

  Future<void> _deleteService() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este serviço?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final serviceProvider =
          Provider.of<ServiceProvider>(context, listen: false);
      final userId = await authProvider.getCurrentUserId();

      if (userId != null) {
        await serviceProvider.deleteService(widget.service.id!, userId);
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço excluído com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _statusResult?.isOnline ?? widget.service.lastStatus == 'Online';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Serviço'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (_) => AddEditServiceScreen(service: widget.service),
                ),
              )
                  .then((_) {
                setState(() {});
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteService,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _checkStatus();
          await _loadIpData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(
                          isOnline ? Icons.check_circle : Icons.cancel,
                          color: isOnline ? Colors.green : Colors.red,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.service.name,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.service.address,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status do Serviço',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (_isCheckingStatus)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        'Status',
                        _statusResult?.status ?? widget.service.lastStatus,
                        isOnline ? Colors.green : Colors.red,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Latência',
                        _statusResult != null
                            ? '${_statusResult!.latencyMs}ms'
                            : '${widget.service.lastLatencyMs}ms',
                        null,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isCheckingStatus ? null : _checkStatus,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Verificar Status'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informações de Localização',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const Divider(height: 24),
                      if (_isLoadingIpData)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_ipData != null && _ipData!.status == 'success')
                        Column(
                          children: [
                            _buildInfoRow('País', _ipData!.country, null),
                            const SizedBox(height: 12),
                            _buildInfoRow('Cidade', _ipData!.city, null),
                            const SizedBox(height: 12),
                            _buildInfoRow('Provedor', _ipData!.isp, null),
                          ],
                        )
                      else
                        Center(
                          child: Text(
                            'Não foi possível obter informações de localização',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color? valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}
