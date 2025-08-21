import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../services/bluetooth_service.dart';
import '../services/storage_service.dart'; // <-- necessário para zerar itens

class ConfigScreen extends StatefulWidget {
  static const route = '/config';
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {

  final _altCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  String? _addr;
  String? _name;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    _altCtrl.text = (prefs.getInt('cfg_altura') ?? 95).toString();
    _addr = BluetoothService.instance.currentAddress ??
        prefs.getString('last_address');
    _name =
        BluetoothService.instance.currentName ?? prefs.getString('last_name');
    _userCtrl.text = (prefs.getString('user_name') ?? 'Nome Responsável');
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final alt = int.tryParse(_altCtrl.text.trim()) ?? 30;
    await prefs.setInt('cfg_altura', alt);
    await prefs.setString(
      'user_name',
      _userCtrl.text.trim().isEmpty
          ? 'Resp pelo setor'
          : _userCtrl.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Configuração salva')));
  }

  Future<void> _pickAndConnect() async {
    final bt = BluetoothService.instance;
    final list = await bt.bondedDevices();
    if (list.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum dispositivo pareado')));
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
            leading: const Icon(Icons.bluetooth_rounded),
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
      final ok = await bt.connect(chosen.address, name: chosen.name);
      if (ok) {
        setState(() {
          _addr = chosen.address;
          _name = chosen.name;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_address', chosen.address);
        await prefs.setString('last_name', chosen.name ?? '(sem nome)');
      } else if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Falha ao conectar')));
      }
    }
  }

  Future<void> _disconnect() async {
    final bt = BluetoothService.instance;
    bt.disconnect();
    setState(() {
      _addr = null;
      _name = null;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Desconectado')));
  }

  Future<void> _confirmAndResetItems() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Zerar itens do usuário'),
        content: const Text(
            'Isto removerá os itens salvos por você e retornará uma nova lista com produtos padrão. '
            'Use apenas se tiver certeza, pois os itens podem ser perdidos '
            '\n\nDeseja continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Zerar')),
        ],
      ),
    );

    if (ok == true) {
      // deleteFile: true => apaga o arquivo; ao ler de novo, cai no assets
      await StorageService.resetUserItems();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Itens do usuário zerados')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final addrTxt = (_addr == null && _name == null)
        ? 'Nenhuma'
        : '${_name ?? '(sem nome)'} • ${_addr ?? ''}';

    return Scaffold(
      appBar: AppBar(title: const Text('Configuração')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== Etiqueta / Responsável =====
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detalhes da etiqueta',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: _altCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Salto após imprimir (pontos)'))),
                    ]),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _userCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Nome do responsável')),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                          onPressed: _save, child: const Text('Salvar')),
                    ),
                  ]),
            ),
          ),

          const SizedBox(height: 12),

          // ===== Impressora =====
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Impressora',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.print_rounded),
                      title: const Text('Impressora atual'),
                      subtitle: Text(addrTxt),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _disconnect,
                          icon: const Icon(Icons.link_off),
                          label: const Text('Desconectar'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _pickAndConnect,
                          icon: const Icon(Icons.link),
                          label: const Text('Conectar'),
                        ),
                      ],
                    ),
                    if (BluetoothService.instance.connected)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('Conectado',
                              style: TextStyle(color: Colors.green.shade700)),
                        ),
                      ),
                  ]),
            ),
          ),

          const SizedBox(height: 12),

          // ===== Manutenção (Zerar itens) =====
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dados do usuário',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_sweep_rounded),
                      label: const Text('Zerar itens (itens_usuario.json)'),
                      onPressed: _confirmAndResetItems,
                    ),
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}
