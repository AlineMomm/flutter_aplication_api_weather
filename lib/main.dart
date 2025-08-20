import 'package:flutter/material.dart';
import 'repositorio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  

  // var url = Uri.https('exemple.com', 'whatsit/create');
  // http.post(url, body: {'name': 'doodle', 'color': 'blue'}).then((value){
  //     if (kDebugMode) {
  //       print(value);
  //     }
  // });

  // iNÍCIO DO APP
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(

      home: WeatherPage(),
    );
  }
}


class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _controller = TextEditingController();
  final WeatherRepository _repo = WeatherRepository();

  String _resultado = "Buscando localização...";
  String? _icone;
  final List<String> _historico = [];

  @override
  void initState() {
    super.initState();
    _buscarCidadeAtual();
  }

  // Desafio 2: Detectar localização
  Future<void> _buscarCidadeAtual() async {
    bool servicoHabilitado;
    LocationPermission permissao;

    servicoHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicoHabilitado) {
      setState(() => _resultado = "Serviço de localização desativado.");
      return;
    }

    permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        setState(() => _resultado = "Permissão de localização negada.");
        return;
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      setState(() => _resultado = "Permissão negada permanentemente.");
      return;
    }

    final posicao = await Geolocator.getCurrentPosition();
    final lat = posicao.latitude;
    final lon = posicao.longitude;

    // Buscar cidade a partir da latitude e longitude
    final url = Uri.parse(
        "https://api.weatherapi.com/v1/current.json?key=${WeatherRepository.apiKey}&q=$lat,$lon&aqi=no");
    final resposta = await http.get(url);

    if (resposta.statusCode == 200) {
      final dados = jsonDecode(resposta.body);
      final cidadeAtual = dados['location']['name'];
      _buscar(cidadeAtual);
    } else {
      setState(() => _resultado = "Erro ao obter cidade atual.");
    }
  }

  // DESAFIO 1 E 3: Buscar clima e histórico
  void _buscar([String? cidadeForcada]) async {
    final cidade = cidadeForcada ?? _controller.text.trim();
    if (cidade.isEmpty) return;

    final dados = await _repo.buscarClima(cidade);
    if (dados != null) {
      setState(() {
        _resultado =
            "Cidade: ${dados['cidade']}\nTemp: ${dados['temp']}°C\nSensação: ${dados['sensacao']}°C\nVento: ${dados['vento']} km/h\nCondição: ${dados['condicao']}";
        _icone = dados['icone'];

        // adicionar no histórico
        if (!_historico.contains(dados['cidade'])) {
          _historico.insert(0, dados['cidade']);
          if (_historico.length > 5) {
            _historico.removeLast(); // mantém só 5 últimas
          }
        }
      });
    } else {
      setState(() {
        _resultado = "Erro ao buscar clima";
        _icone = null;
      });
    }
  }

  // TELA
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Weather App")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: "Digite a cidade",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _buscar(),
                  child: const Text("Buscar"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_icone != null)
              Image.network(_icone!, width: 64, height: 64),
            Text(
              _resultado,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // 🔹 Histórico
            if (_historico.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _historico.length,
                  itemBuilder: (context, index) {
                    final cidade = _historico[index];
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(cidade),
                      onTap: () => _buscar(cidade),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
