import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/bluetooth_service.dart';

class ConfigScreen extends StatefulWidget {
  static const route = '/config';
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _largCtrl = TextEditingController();
  final _altCtrl  = TextEditingController();
  String? _addr;
  String? _name;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _largCtrl.text = (prefs.getInt('cfg_largura') ?? 48).toString();
    _altCtrl.text  = (prefs.getInt('cfg_altura')  ?? 30).toString();
    _addr = prefs.getString('last_address');
    setState(() {});
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final larg = int.tryParse(_largCtrl.text.trim()) ?? 48;
    final alt  = int.tryParse(_altCtrl.text.trim())  ?? 30;
    await prefs.setInt('cfg_largura', larg);
    await prefs.setInt('cfg_altura', alt);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuração salva')));
  }

  Future<void> _selectPrinter() async {
    final bt = BluetoothService.instance;
    final list = await bt.bondedDevices();
    if (list.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum dispositivo pareado')));
      return;
    }

    final chosen = await showModalBottomSheet<BluetoothDevice>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (_, i) {
          final d = list[i];
          return ListTile(
            leading: const Icon(Icons.print_rounded),
            title: Text(d.name?.isNotEmpty == true ? d.name! : '(sem nome)'),
            subtitle: Text(d.address),
            onTap: () => Navigator.pop(context, d),
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: list.length,
      ),
    );

    if (chosen != null) {
      final ok = await bt.connect(chosen.address);
      if (ok) {
        setState(() {
          _addr = chosen.address;
          _name = chosen.name;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao conectar')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final addrTxt = _addr == null ? 'Nenhuma' : (_name ?? '(sem nome)') + ' • ' + _addr!;
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Etiqueta', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: _largCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Largura (mm)'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _altCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Altura (mm)'))),
                ]),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: _save, child: const Text('Salvar')),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Impressora', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.print_rounded),
                  title: const Text('Selecionar impressora'),
                  subtitle: Text(addrTxt),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectPrinter,
                ),
                if (BluetoothService.instance.connected)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('Conectado', style: TextStyle(color: Colors.green.shade700)),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
