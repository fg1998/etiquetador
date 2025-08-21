import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'bluetooth_service.dart';
import '../models/item.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class PrintService {
  static final _bt = BluetoothService.instance;

  // ===== ESC/POS =====
  static void _raw(List<int> b) => _bt.sendRaw(b);
  static void _escCodePage(int n) => _raw([0x1B, 0x74, n]);
  static void _escPrint(String s, {bool lf = true}) {
    _raw(latin1.encode(s));
    if (lf) _raw([0x0A]);
  }

  //static void _escFeed(int n) => _raw([0x1B, 0x64, n]);
  static void _escInit() => _raw([0x1B, 0x40]);

  // Feed DOTS
  static void feedDots(int dots) {
    if (dots <= 0) return;
    var restante = dots;
    while (restante > 0) {
      final n = min(restante, 255);
      _raw([0x1B, 0x4A, n]);
      restante -= n;
    }
  }

  // RESET
  static void RESET_PRINTER() => _raw([0x1B, 0x40]);

  // Alinhamento
  static void TEXT_ALIGN_LEFT() => _raw([0x1B, 0x61, 0x00]);
  static void TEXT_ALIGN_CENTER() => _raw([0x1B, 0x61, 0x01]);
  static void TEXT_ALIGN_RIGHT() => _raw([0x1B, 0x61, 0x02]);

  // Peso da fonte
  static void TEXT_WEIGHT_NORMAL() => _raw([0x1B, 0x45, 0x00]);
  static void TEXT_WEIGHT_BOLD() => _raw([0x1B, 0x45, 0x01]);

  // Espaçamento de linha
  static void LINE_SPACING_24() => _raw([0x1B, 0x33, 0x18]);
  static void LINE_SPACING_30() => _raw([0x1B, 0x33, 0x1E]);

  // Fontes
  static void TEXT_FONT_A() => _raw([0x1B, 0x4D, 0x00]);
  static void TEXT_FONT_B() => _raw([0x1B, 0x4D, 0x01]);
  static void TEXT_FONT_C() => _raw([0x1B, 0x4D, 0x02]);
  static void TEXT_FONT_D() => _raw([0x1B, 0x4D, 0x03]);
  static void TEXT_FONT_E() => _raw([0x1B, 0x4D, 0x04]);

  // Tamanhos de texto
  static void TEXT_SIZE_NORMAL() => _raw([0x1D, 0x21, 0x00]);
  static void TEXT_SIZE_DOUBLE_HEIGHT() => _raw([0x1D, 0x21, 0x01]);
  static void TEXT_SIZE_DOUBLE_WIDTH() => _raw([0x1D, 0x21, 0x10]);
  static void TEXT_SIZE_BIG() => _raw([0x1D, 0x21, 0x11]);

  // Sublinhado
  static void TEXT_UNDERLINE_OFF() => _raw([0x1B, 0x2D, 0x00]);
  static void TEXT_UNDERLINE_ON() => _raw([0x1B, 0x2D, 0x01]);
  static void TEXT_UNDERLINE_LARGE() => _raw([0x1B, 0x2D, 0x02]);

  // Duplo strike
  static void TEXT_DOUBLE_STRIKE_OFF() => _raw([0x1B, 0x47, 0x00]);
  static void TEXT_DOUBLE_STRIKE_ON() => _raw([0x1B, 0x47, 0x01]);

  // Cor do texto
  static void TEXT_COLOR_BLACK() => _raw([0x1B, 0x72, 0x00]);
  static void TEXT_COLOR_RED() => _raw([0x1B, 0x72, 0x01]);

  // Reverse (inverter cor)
  static void TEXT_COLOR_REVERSE_OFF() => _raw([0x1D, 0x42, 0x00]);
  static void TEXT_COLOR_REVERSE_ON() => _raw([0x1D, 0x42, 0x01]);

  /// Imprime uma etiqueta para o item
  static Future<void> printItem(Item item) async {
    if (!_bt.connected) return;

    final prefs = await SharedPreferences.getInstance();

    _escInit();
    // Latin-1 costuma ir bem; se acentos falharem, tente 17 (CP858) ou 0 (CP437)
    _escCodePage(16);

    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final dataFutura = hoje.add(Duration(days: item.dias));
    final validadeStr = DateFormat('dd/MM/yyyy').format(dataFutura);
    final dataHojeStr = DateFormat('dd/MM/yyyy').format(hoje);

    final resp = (prefs.getString('user_name') ?? 'Resp pelo setor');
    final cfg_altura = (prefs.getInt('cfg_altura') ?? 95);

    // Cabeçalho
    TEXT_ALIGN_LEFT();
    TEXT_FONT_A();
    TEXT_WEIGHT_BOLD();
    TEXT_SIZE_DOUBLE_HEIGHT();
    _escPrint(item.nome);
    feedDots(30);

    _escPrint('Validade: $validadeStr');
    feedDots(20);

    TEXT_SIZE_NORMAL();

    _escPrint('Manipulação: $dataHojeStr');

    TEXT_WEIGHT_NORMAL();
    _escPrint('Manipulado por: $resp');

    _escPrint('Refrigeração: ' +
        (item.refrigeracao == Refrigeracao.congelado
            ? 'CONGELADO'
            : item.refrigeracao == Refrigeracao.refrigerado
                ? 'REFRIGERADO'
                : 'TEMP AMBIENTE'));

    feedDots(cfg_altura);
  }
}
