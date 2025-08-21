import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../services/storage_service.dart';
import '../services/bluetooth_service.dart';
import '../services/print_service.dart';
import '../widgets/product_card.dart';
import 'config_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Item> _items = [];
  bool _loading = true;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _load();
    _maybeAskPrinter();
  }

  Future<void> _load() async {
    final list = await StorageService.readAll();
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _maybeAskPrinter() async {
    final bt = BluetoothService.instance;

    // Se por algum motivo a tela inicial for aberta antes do main() terminar,
    // chamamos bootstrap de novo de forma idempotente.
    await bt.bootstrap();

    if (bt.connected) return; // já reconectou automático

    // Reconexão falhou ou não havia impressora salva → abre seletor
    final bonded = await bt.bondedDevices();
    if (bonded.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum dispositivo pareado')),
      );
      return;
    }

    final device = await _pickDevice(
      bonded
          .map<(String, String)>((e) => (e.name ?? '(sem nome)', e.address))
          .toList(),
    );

    if (device != null) {
      setState(() => _connecting = true);
      try {
        await bt.connect(device.$2, name: device.$1);
      } finally {
        if (mounted) setState(() => _connecting = false);
      }
    }
  }

  Future<(String, String)?> _pickDevice(List<(String, String)> list) async {
    return showModalBottomSheet<(String, String)>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (_, i) {
          final it = list[i];
          return ListTile(
            leading: const Icon(Icons.print_rounded),
            title: Text(it.$1),
            subtitle: Text(it.$2),
            onTap: () => Navigator.pop(context, it),
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: list.length,
      ),
    );
  }

  Future<void> _editItem(
      {Item? item, int? index, bool duplicate = false}) async {
    final nomeCtrl = TextEditingController(
        text:
            duplicate && item != null ? '${item.nome} (2)' : item?.nome ?? '');
    final diasCtrl = TextEditingController(text: item?.dias.toString() ?? '');
    Refrigeracao refType = item?.refrigeracao ?? Refrigeracao.ambiente;

    final res = await showDialog<Item>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return AlertDialog(
            title: Text(duplicate
                ? 'Duplicar produto'
                : (item == null ? 'Novo produto' : 'Editar produto')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Nome'),
                    controller: nomeCtrl,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Dias'),
                    controller: diasCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Refrigeracao>(
                    value: refType,
                    decoration:
                        const InputDecoration(labelText: 'Refrigeração'),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: Refrigeracao.ambiente,
                        child: Text('Ambiente'),
                      ),
                      DropdownMenuItem(
                        value: Refrigeracao.refrigerado,
                        child: Text('Refrigerado'),
                      ),
                      DropdownMenuItem(
                        value: Refrigeracao.congelado,
                        child: Text('Congelado'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => refType = v);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar')),
              FilledButton(
                onPressed: () {
                  final d = int.tryParse(diasCtrl.text.trim());
                  final n = nomeCtrl.text.trim();
                  if (n.isEmpty || d == null) return;
                  Navigator.pop(
                      context, Item(nome: n, dias: d, refrigeracao: refType));
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );

    if (res != null) {
      if (index == null || duplicate) {
        await StorageService.add(res);
      } else {
        await StorageService.update(index, res);
      }
      await _load();
    }
  }

  Future<void> _removeItem(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir produto'),
        content: const Text('Tem certeza que deseja excluir este produto?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (ok == true) {
      await StorageService.remove(index);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bt = BluetoothService.instance;
    final headerText = bt.connected
        ? 'Impressora: ${(bt.currentName ?? '(sem nome)')} • ${bt.currentAddress}'
        : _connecting
            ? 'Conectando à impressora...'
            : 'Nenhuma impressora conectada';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etiquetador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.pushNamed(context, ConfigScreen.route)
                .then((_) => setState(() {})),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editItem(),
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  // Cabeçalho de status da impressora
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(headerText,
                                  style:
                                      const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                        Icon(
                          bt.connected
                              ? Icons.print_rounded
                              : Icons.print_disabled_rounded,
                          color: bt.connected ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),

                  // Lista de cards
                  for (int i = 0; i < _items.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ProductCard(
                        item: _items[i],
                        onEdit: () => _editItem(item: _items[i], index: i),
                        onDuplicate: () => _editItem(
                            item: _items[i], index: i, duplicate: true),
                        onDelete: () => _removeItem(i),
                        onPrint: () => PrintService.printItem(_items[i]),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
