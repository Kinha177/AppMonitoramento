import 'dart:async'; // Necessário para o Timer
import 'package:flutter/material.dart';
import 'status_checker.dart'; // Seu arquivo do StatusChecker

class MonitoramentoScreen extends StatefulWidget {
  @override
  _MonitoramentoScreenState createState() => _MonitoramentoScreenState();
}

class _MonitoramentoScreenState extends State<MonitoramentoScreen> {
  // Instância única do Checker (para manter a memória do que caiu/voltou)
  final StatusChecker _checker = StatusChecker();
  
  // Variável para controlar o Timer
  Timer? _timer;

  // Lista de sites para monitorar
  final List<String> _sites = [
    'google.com',
    'uol.com.br',
    'meusitequebrado.com'
  ];

  // Armazena os resultados para exibir na tela
  Map<String, StatusCheckResult> _resultados = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 1. Executa a primeira vez assim que abre a tela
    _verificarTodosOsSites();

    // 2. Configura o Timer para rodar a cada 60 segundos (1 minuto)
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _verificarTodosOsSites();
    });
  }

  @override
  void dispose() {
    // 3. MUITO IMPORTANTE: Cancela o timer se sair da tela
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verificarTodosOsSites() async {
    if (!mounted) return; // Segurança para não atualizar tela fechada

    setState(() {
      _isLoading = true;
    });

    for (var site in _sites) {
      // Chama seu StatusChecker (ele já tem a lógica do Telegram dentro)
      var resultado = await _checker.checkStatus(site);
      
      if (mounted) {
        setState(() {
          _resultados[site] = resultado;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monitoramento Automático"),
        actions: [
          // Ícone animado indicando se está atualizando
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              ),
            )
        ],
      ),
      body: ListView.builder(
        itemCount: _sites.length,
        itemBuilder: (context, index) {
          final url = _sites[index];
          final resultado = _resultados[url];

          // Se ainda não checou, mostra "Aguardando..."
          if (resultado == null) {
            return ListTile(
              title: Text(url),
              subtitle: const Text("Verificando..."),
              leading: const CircularProgressIndicator(),
            );
          }

          return ListTile(
            leading: Icon(
              resultado.isOnline ? Icons.check_circle : Icons.error,
              color: resultado.isOnline ? Colors.green : Colors.red,
            ),
            title: Text(url, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              resultado.isOnline 
                  ? "Online (${resultado.latencyMs}ms)" 
                  : "OFFLINE!",
              style: TextStyle(
                color: resultado.isOnline ? Colors.black : Colors.red,
              ),
            ),
            trailing: Text(resultado.status),
          );
        },
      ),
    );
  }
}