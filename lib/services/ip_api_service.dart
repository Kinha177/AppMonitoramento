import 'dart:convert';
import 'package:http/http.dart' as http;

class IpApiData {
  final String country;
  final String city;
  final String isp;
  final String status;

  IpApiData({
    required this.country,
    required this.city,
    required this.isp,
    required this.status,
  });

  factory IpApiData.fromJson(Map<String, dynamic> json) {
    return IpApiData(
      country: json['country'] ?? 'Desconhecido',
      city: json['city'] ?? 'Desconhecido',
      isp: json['isp'] ?? 'Desconhecido',
      status: json['status'] ?? 'fail',
    );
  }
}

class IpApiService {
  Future<IpApiData?> getIpInfo(String address) async {
    try {
      String ip = address;

      ip = ip.replaceAll('http://', '').replaceAll('https://', '');

      if (ip.contains('/')) {
        ip = ip.split('/').first;
      }

      if (ip.contains(':')) {
        ip = ip.split(':').first;
      }

      final url = 'http://ip-api.com/json/$ip';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return IpApiData.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
