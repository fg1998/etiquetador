import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothService {
  BluetoothService._();
  static final instance = BluetoothService._();

  BluetoothConnection? _conn;
  StreamSubscription<Uint8List>? _rx;

  String? currentAddress;
  String? currentName;

  // ======= Chaves de preferência =======
  static const _kLastAddress = 'last_address';
  static const _kLastName = 'last_name';

  // ======= Estado =======
  bool get connected => (_conn?.isConnected ?? false);

  // ======= Permissões + enable BT =======
  Future<void> _ensurePermissions() async {
    // Android 12+ precisa de BLUETOOTH_CONNECT/SCAN; anteriores usavam location.
    final perms = <Permission>[
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    for (final p in perms) {
      final s = await p.status;
      if (!s.isGranted) {
        await p.request();
      }
    }

    // Garantir que o BT esteja ligado
    final inst = FlutterBluetoothSerial.instance;
    try {
      final state = await inst.state;
      if (state != BluetoothState.STATE_ON) {
        await inst.requestEnable();
      }
    } catch (_) {
      // Ignora exceção de plataformas não-Android
    }
  }

  /// Tenta preparar o serviço e reconectar na última impressora salva.
  Future<void> bootstrap() async {
    await _ensurePermissions();

    final prefs = await SharedPreferences.getInstance();
    final addr = prefs.getString(_kLastAddress);
    final name = prefs.getString(_kLastName);

    // Se já estamos conectados, mantém.
    if (connected) return;

    if (addr != null && addr.isNotEmpty) {
      try {
        await connect(addr, name: name);
      } catch (e) {
        // Falhou na reconexão; deixa desconectado para a UI abrir o seletor.
        // print('Falha ao reconectar em $addr: $e');
        disconnect();
      }
    }
  }

  Future<List<BluetoothDevice>> bondedDevices() async {
    await _ensurePermissions();
    return FlutterBluetoothSerial.instance.getBondedDevices();
  }

  /// Conecta e **salva** o endereço/nome para futuras reconexões.
  Future<bool> connect(String address, {String? name}) async {
    await _ensurePermissions();

    // Se já estiver conectado ao mesmo endereço, mantém.
    if (connected && currentAddress == address) {
      return true;
    }

    // Fecha conexão anterior, se houver.
    await _rx?.cancel();
    _rx = null;
    await _conn?.close();
    _conn = null;

    final c = await BluetoothConnection.toAddress(address);
    _conn = c;
    currentAddress = address;
    if (name != null && name.isNotEmpty) {
      currentName = name;
    }

    // Leitura (se quiser depurar recebimento; manter opcional)
    _rx = _conn!.input?.listen(
      (data) {
        // print('RX(${data.length}): $data');
      },
      onDone: () {
        // Conexão encerrada pelo remoto
        _conn = null;
      },
      onError: (_) {
        _conn = null;
      },
      cancelOnError: true,
    );

    // Salva prefs para reconectar na próxima execução
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastAddress, address);
    if ((name ?? '').isNotEmpty) {
      await prefs.setString(_kLastName, name!);
    }

    return true;
  }

  /// Desconecta (não apaga prefs; a UI decide se quer "esquecer").
  void disconnect() {
    _rx?.cancel();
    _rx = null;
    _conn?.close();
    _conn = null;
  }

  /// "Esquecer" impressora salva (opcional: chamar na tela de Config).
  Future<void> forgetSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastAddress);
    await prefs.remove(_kLastName);
    currentAddress = null;
    currentName = null;
  }

  /// Envia bytes crus para a impressora.
  void sendRaw(List<int> bytes) {
    final c = _conn;
    if (c == null || !c.isConnected) return;
    c.output.add(Uint8List.fromList(bytes));
    // Opcional: aguardar flush → c.output.allSent;
  }
}
