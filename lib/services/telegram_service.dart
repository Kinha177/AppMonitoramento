import 'package:http/http.dart' as http;

class TelegramService {
  final String botToken = '8596090068:AAHXhxiFsg2fIlWvInWAcsqUUOqXJFstVAA';
  final String chatId = '1992081447';

  Future<void> enviarAlerta(String mensagem) async {
    final url = Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');
    
    try {
      await http.post(
        url,
        body: {
          'chat_id': chatId,
          'text': "🚨 ALERTA MONITA AÍ 🚨\n\n$mensagem",
        },
      );
      print("Alerta enviado para o Telegram!");
    } catch (e) {
      print("Erro ao enviar telegram: $e");
    }
  }
}