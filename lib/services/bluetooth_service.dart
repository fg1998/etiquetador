import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ConnectStatus {
  connected,
  alreadyConnected,
  timeout,
  deviceOffOrUnreachable,
  bluetoothOff,
  permissionDenied,
  unknownError,
}

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
    // Android 12+ usa BLUETOOTH_CONNECT/SCAN; anteriores podem pedir location.
    final perms = <Permission>[
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location, // safe fallback p/ Android < 12
    ];

    for (final p in perms) {
      final s = await p.status;
      if (!s.isGranted) {
        final rs = await p.request();
        if (!rs.isGranted) {
          throw PlatformException(code: 'permission_denied', message: 'Permissão $p negada');
        }
      }
    }

    // Garantir que o BT esteja ligado
    final inst = FlutterBluetoothSerial.instance;
    try {
      final state = await inst.state;
      if (state != BluetoothState.STATE_ON) {
        final enabled = await inst.requestEnable();
        if (enabled != true) {
          throw PlatformException(code: 'bluetooth_off', message: 'Bluetooth desligado');
        }
      }
    } catch (_) {
      // Ignora exceções em plataformas não-Android
    }
  }

  /// Tenta preparar o serviço e reconectar na última impressora salva.
  /// Retorna true se reconectou; false caso contrário.
  Future<bool> bootstrap() async {
    try {
      await _ensurePermissions();
    } on PlatformException {
      // sem permissões ou BT off – deixa a UI decidir
      return false;
    }

    // Se já estamos conectados, mantém.
    if (connected) return true;

    final prefs = await SharedPreferences.getInstance();
    final addr = prefs.getString(_kLastAddress);
    final name = prefs.getString(_kLastName);

    if (addr != null && addr.isNotEmpty) {
      final status = await connect(addr, name: name);
      if (status == ConnectStatus.connected || status == ConnectStatus.alreadyConnected) {
        return true;
      }
      // Falhou na reconexão; mantém desconectado para a UI abrir o seletor.
      return false;
    }
    return false;
  }

  Future<List<BluetoothDevice>> bondedDevices() async {
    await _ensurePermissions();
    return FlutterBluetoothSerial.instance.getBondedDevices();
  }

  /// Conecta e **salva** o endereço/nome para futuras reconexões.
  /// Nunca lança exceção; retorna um ConnectStatus para a UI.
  Future<ConnectStatus> connect(String address, {String? name, Duration timeout = const Duration(seconds: 8)}) async {
    try {
      await _ensurePermissions();
    } on PlatformException catch (e) {
      if (e.code == 'permission_denied') return ConnectStatus.permissionDenied;
      if (e.code == 'bluetooth_off') return ConnectStatus.bluetoothOff;
      return ConnectStatus.unknownError;
    }

    // Se já estiver conectado ao mesmo endereço, mantém.
    if (connected && currentAddress == address) {
      return ConnectStatus.alreadyConnected;
    }

    // Fecha conexão anterior, se houver.
    await _rx?.cancel();
    _rx = null;
    await _conn?.close();
    _conn = null;

    try {
      // Protege com timeout para não travar quando o dispositivo estiver desligado.
      final c = await BluetoothConnection.toAddress(address).timeout(timeout);
      _conn = c;
      currentAddress = address;
      if (name != null && name.isNotEmpty) {
        currentName = name;
      }

      // Listener opcional de entrada
      _rx = _conn!.input?.listen(
        (data) {
          // print('RX(${data.length}): $data');
        },
        onDone: () {
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

      return ConnectStatus.connected;
    } on TimeoutException {
      // Garantir limpeza do socket parcial
      await _safeClose();
      return ConnectStatus.timeout;
    } on PlatformException catch (e) {
      // Erros mais comuns quando o dispositivo está desligado/fora de alcance
      final msg = (e.message ?? '').toLowerCase();
      if (e.code == 'connect_error' ||
          msg.contains('read failed') ||
          msg.contains('socket') ||
          msg.contains('timeout')) {
        await _safeClose();
        return ConnectStatus.deviceOffOrUnreachable;
      }
      await _safeClose();
      return ConnectStatus.unknownError;
    } catch (_) {
      await _safeClose();
      return ConnectStatus.unknownError;
    }
  }

  Future<void> _safeClose() async {
    try {
      await _rx?.cancel();
    } catch (_) {}
    _rx = null;
    try {
      await _conn?.close();
    } catch (_) {}
    _conn = null;
  }

  /// Desconecta (não apaga prefs; a UI decide se quer "esquecer").
  Future<void> disconnect() => _safeClose();

  /// "Esquecer" impressora salva (opcional: chamar na tela de Config).
  Future<void> forgetSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastAddress);
    await prefs.remove(_kLastName);
    currentAddress = null;
    currentName = null;
  }

  /// Envia bytes crus para a impressora (no-op se desconectado).
  void sendRaw(List<int> bytes) {
    final c = _conn;
    if (c == null || !c.isConnected) return;
    c.output.add(Uint8List.fromList(bytes));
    // opcional: c.output.allSent;
  }
}
