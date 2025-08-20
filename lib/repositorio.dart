import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherRepository {
  static const String apiKey = '2172b64e833f45c8860220027252102';

  Future<Map<String, dynamic>?> buscarClima(String cidade) async {
    final url = Uri.parse(
        'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$cidade&aqi=yes');

    final resposta = await http.get(url);

    if (resposta.statusCode == 200) {
      final dados = jsonDecode(resposta.body);
      return {
        "cidade": dados['location']['name'],
        "temp": dados['current']['temp_c'],
        "condicao": dados['current']['condition']['text'],
        "icone": "https:${dados['current']['condition']['icon']}",
        "sensacao": dados['current']['feelslike_c'],
        "vento": dados['current']['wind_kph'],
      };
    } else {
      return null;
    }
  }
}



