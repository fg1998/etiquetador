import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'bluetooth_service.dart';
import '../models/item.dart';
import 'package:intl/intl.dart';

class PrintService {
  static final _bt = BluetoothService.instance;

  // ===== ESC/POS =====
  static void _raw(List<int> b) => _bt.sendRaw(b);
  static void _escInit() => _raw([0x1B, 0x40]);
  static void _escAlign(int m) => _raw([0x1B, 0x61, m.clamp(0, 2)]);
  static void _escBold(bool on) => _raw([0x1B, 0x45, on ? 1 : 0]);
  static void _escSize(int w, int h) {
    final v = (((w.clamp(1, 8) - 1) << 4) | (h.clamp(1, 8) - 1));
    _raw([0x1D, 0x21, v]);
  }
  static void _escCodePage(int n) => _raw([0x1B, 0x74, n]);
  static void _escPrint(String s, {bool lf = true}) {
    _raw(latin1.encode(s));
    if (lf) _raw([0x0A]);
  }
  static void _escFeed(int n) => _raw([0x1B, 0x64, n]);

  /// Imprime uma etiqueta para o item
  static Future<void> printItem(Item item) async {
    if (!_bt.connected) return;

    final prefs = await SharedPreferences.getInstance();
    final largura = prefs.getInt('cfg_largura') ?? 48; // mm (indicativo)
    final altura  = prefs.getInt('cfg_altura')  ?? 30;

    _escInit();
    // Latin-1 costuma ir bem; se acentos falharem, tente 17 (CP858) ou 0 (CP437)
    _escCodePage(16);

    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final dataFutura = hoje.add(Duration(days: item.dias));   
    final validadeStr = DateFormat('dd/MM/yyyy').format(dataFutura);
    final dataHojeStr = DateFormat('dd/MM/yyyy').format(hoje);

    // Cabeçalho
    _escAlign(0);
    _escBold(true);
    _escSize(1, 2);
    _escPrint(item.nome);
    _escPrint('Validade: $validadeStr');
    _escBold(false);
    _escSize(1, 1);
    
   

    _escAlign(0);
    
    _escPrint('Manipulação: $dataHojeStr');
    _escPrint('Refrigeração: ${item.refrigeracao ? "SIM" : "NÃO"}');

    // Espaço proporcional “fake” só pra dar respiro
    final feeds = (altura / 10).clamp(1, 6).toInt();
    _escFeed(feeds);
    // _raw([0x1D, 0x56, 1]); // corte se tiver guilhotina
  }
}
