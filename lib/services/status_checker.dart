import 'dart:convert';
import 'package:http/http.dart' as http;

// --- CONFIGURAÇÃO DO TELEGRAM ---
const String telegramBotToken = '8596090068:AAHXhxiFsg2fIlWvInWAcsqUUOqXJFstVAA';
const String telegramChatId = '1992081447';

// Função que envia mensagens para o Telegram
Future<void> sendTelegramAlert(String message) async {
  final url = Uri.parse(
    'https://api.telegram.org/bot$telegramBotToken/sendMessage',
  );

  try {
    await http.post(url, body: {
      'chat_id': telegramChatId,
      'text': message,
    });
    print("🔔 Alerta enviado: $message");
  } catch (e) {
    print("Erro ao enviar mensagem para o Telegram: $e");
  }
}

// --- MODEL DO RESULTADO ---
class StatusCheckResult {
  final bool isOnline;
  final int latencyMs;
  final String status;

  StatusCheckResult({
    required this.isOnline,
    required this.latencyMs,
    required this.status,
  });
}

// --- CHECKER COM MEMÓRIA ---
class StatusChecker {
  // 🧠 MEMÓRIA: Guarda o último estado (url -> estavaOnline?)
  // Isso impede que a memória apague a cada verificação
  final Map<String, bool> _historicoStatus = {};

  Future<StatusCheckResult> checkStatus(String address) async {
    // 1. Preparação da URL
    String url = address;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }

    // Variáveis temporárias para armazenar o resultado desta verificação
    bool isOnlineAgora = false;
    int latency = 0;
    String statusText = 'Offline';

    // 2. Tenta acessar o site
    try {
      final startTime = DateTime.now();
      
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      
      final endTime = DateTime.now();
      latency = endTime.difference(startTime).inMilliseconds;

      if (response.statusCode >= 200 && response.statusCode < 400) {
        isOnlineAgora = true;
        statusText = 'Online';
      } else {
        isOnlineAgora = false; // Erro 404, 500, etc.
      }
    } catch (e) {
      isOnlineAgora = false; // Erro de DNS, Timeout, sem internet
      latency = 0;
    }

    // 3. LÓGICA DE ALERTA INTELIGENTE (Caiu vs Voltou)
    
    // Verifica se temos histórico desse site
    if (_historicoStatus.containsKey(url)) {
      bool estavaOnlineAntes = _historicoStatus[url]!;

      // CENÁRIO A: Estava OFF e agora ficou ON (VOLTOU)
      if (!estavaOnlineAntes && isOnlineAgora) {
        await sendTelegramAlert("✅ O site $address VOLTOU ao ar! (${latency}ms)");
      }
      
      // CENÁRIO B: Estava ON e agora ficou OFF (CAIU)
      if (estavaOnlineAntes && !isOnlineAgora) {
        await sendTelegramAlert("⚠️ O site $address ACABOU DE CAIR!");
      }
    } else {
      // Primeira vez monitorando: Se já começar offline, avisa
      if (!isOnlineAgora) {
        await sendTelegramAlert("❌ O site $address está OFFLINE (Primeira checagem)");
      }
    }

    // 4. Atualiza a memória para a próxima rodada
    _historicoStatus[url] = isOnlineAgora;

    // 5. Retorna o resultado para a tela
    return StatusCheckResult(
      isOnline: isOnlineAgora,
      latencyMs: latency,
      status: statusText,
    );
  }
}