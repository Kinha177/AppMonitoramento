import 'package:http/http.dart' as http;

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

class StatusChecker {
  Future<StatusCheckResult> checkStatus(String address) async {
    try {
      String url = address;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'http://$url';
      }

      final startTime = DateTime.now();
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 10));

      final endTime = DateTime.now();
      final latency = endTime.difference(startTime).inMilliseconds;

      if (response.statusCode >= 200 && response.statusCode < 400) {
        return StatusCheckResult(
          isOnline: true,
          latencyMs: latency,
          status: 'Online',
        );
      } else {
        return StatusCheckResult(
          isOnline: false,
          latencyMs: latency,
          status: 'Offline',
        );
      }
    } catch (e) {
      return StatusCheckResult(
        isOnline: false,
        latencyMs: 0,
        status: 'Offline',
      );
    }
  }
}
