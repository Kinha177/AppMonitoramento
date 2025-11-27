import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Adicione intl no pubspec.yaml se quiser formatar data bonita, senão use substring
import '../models/service_model.dart';
import '../models/service_log_model.dart';
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

class _ServiceDetailScreenState extends State<ServiceDetailScreen> with SingleTickerProviderStateMixin {
  final IpApiService _ipApiService = IpApiService();
  IpApiData? _ipData;
  bool _isLoadingIpData = true;
  bool _isCheckingStatus = false;
  StatusCheckResult? _statusResult;
  
  // Variáveis para os logs e abas
  late TabController _tabController;
  List<ServiceLogModel> _logs = [];
  bool _isLoadingLogs = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 Abas: Geral e Histórico
    _loadIpData();
    _checkStatus();
    _loadLogs(); // Carregar histórico ao iniciar
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadIpData() async {
    // ... (mesmo código original)
    setState(() { _isLoadingIpData = true; });
    final data = await _ipApiService.getIpInfo(widget.service.address);
    if (mounted) {
      setState(() {
        _ipData = data;
        _isLoadingIpData = false;
      });
    }
  }

  Future<void> _checkStatus() async {
    setState(() { _isCheckingStatus = true; });
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    
    final result = await serviceProvider.checkStatus(widget.service.address);
    // Isso aqui já salva o log dentro do provider conforme alteramos antes
    await serviceProvider.checkServiceStatus(widget.service); 

    if (mounted) {
      setState(() {
        _statusResult = result;
        _isCheckingStatus = false;
      });
      _loadLogs(); // Recarrega os logs após verificar o status
    }
  }

  Future<void> _loadLogs() async {
    setState(() { _isLoadingLogs = true; });
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    if (widget.service.id != null) {
      final logs = await serviceProvider.getServiceLogs(widget.service.id!);
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoadingLogs = false;
        });
      }
    }
  }

  Future<void> _deleteService() async {
    // ... (mesmo código original de delete)
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
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      final userId = await authProvider.getCurrentUserId();

      if (userId != null) {
        await serviceProvider.deleteService(widget.service.id!, userId);
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serviço excluído com sucesso'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcula Uptime simples baseado nos logs carregados
    int onlineCount = _logs.where((l) => l.status == 'Online').length;
    double uptime = _logs.isEmpty ? 0 : (onlineCount / _logs.length) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Serviço'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Visão Geral'),
            Tab(text: 'Histórico'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AddEditServiceScreen(service: widget.service)),
              ).then((_) { setState(() {}); });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteService,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ABA 1: VISÃO GERAL (Código original com pequenas melhorias)
          RefreshIndicator(
            onRefresh: () async { await _checkStatus(); await _loadIpData(); },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildDetailsCard(uptime),
                  const SizedBox(height: 16),
                  _buildLocationCard(),
                ],
              ),
            ),
          ),

          // ABA 2: HISTÓRICO (DASHBOARD DE TEMPO)
          RefreshIndicator(
            onRefresh: _loadLogs,
            child: _isLoadingLogs 
              ? const Center(child: CircularProgressIndicator())
              : _logs.isEmpty 
                ? const Center(child: Text("Nenhum histórico registrado."))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final date = DateTime.parse(log.checkedAt);
                      final formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                      final isOnline = log.status == 'Online';

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            isOnline ? Icons.check_circle : Icons.error,
                            color: isOnline ? Colors.green : Colors.red,
                          ),
                          title: Text(log.status),
                          subtitle: Text(formattedDate),
                          trailing: Text("${log.latencyMs}ms"),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final isOnline = _statusResult?.isOnline ?? widget.service.lastStatus == 'Online';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                isOnline ? Icons.check_circle : Icons.cancel,
                color: isOnline ? Colors.green : Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.service.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.service.address, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(double uptime) {
    final isOnline = _statusResult?.isOnline ?? widget.service.lastStatus == 'Online';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status do Serviço', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (_isCheckingStatus) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Status', _statusResult?.status ?? widget.service.lastStatus, isOnline ? Colors.green : Colors.red),
            const SizedBox(height: 12),
            _buildInfoRow('Latência', _statusResult != null ? '${_statusResult!.latencyMs}ms' : '${widget.service.lastLatencyMs}ms', null),
            const SizedBox(height: 12),
            _buildInfoRow('Uptime (Histórico)', '${uptime.toStringAsFixed(1)}%', uptime > 90 ? Colors.green : Colors.orange), // NOVO
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
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Localização', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            if (_isLoadingIpData)
              const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
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
              Center(child: Text('Não foi possível obter localização', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color? valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}