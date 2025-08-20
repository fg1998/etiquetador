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

  bool get connected => _conn != null;

  Future<void> bootstrap() async {
    await _ensurePermissions();
    await maybeReconnect();
  }

  Future<void> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse, // para Android <= 11
    ].request();

    if (statuses[Permission.bluetoothConnect]?.isGranted != true ||
        statuses[Permission.bluetoothScan]?.isGranted != true) {
      if (statuses[Permission.bluetoothConnect]?.isPermanentlyDenied == true ||
          statuses[Permission.bluetoothScan]?.isPermanentlyDenied == true) {
        await openAppSettings();
      }
      return;
    }
    final state = await FlutterBluetoothSerial.instance.state;
    if (state == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }
  }

  Future<void> maybeReconnect() async {
    final prefs = await SharedPreferences.getInstance();
    final addr = prefs.getString('last_address');
    final name = prefs.getString('last_name');
    if (addr != null) {
      await connect(addr, name: name);
    }
  }

  Future<List<BluetoothDevice>> bondedDevices() async =>
      FlutterBluetoothSerial.instance.getBondedDevices();

  Future<bool> connect(String address, {String? name}) async {
    try {
      final c = await BluetoothConnection.toAddress(address);
      _conn = c;
      currentAddress = address;
      if (name != null && name.isNotEmpty) {
        currentName = name;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_address', address);
      if (currentName != null && currentName!.isNotEmpty) {
        await prefs.setString('last_name', currentName!);
      }

      _rx?.cancel();
      _rx = c.input?.listen((_) {}, onDone: disconnect, onError: (_) => disconnect());
      return true;
    } catch (e) {
      disconnect();
      return false;
    }
  }

  void disconnect() {
    _rx?.cancel();
    _rx = null;
    _conn?.close();
    _conn = null;
  }

  void sendRaw(List<int> bytes) {
    if (_conn != null) {
      _conn!.output.add(Uint8List.fromList(bytes));
      _conn!.output.allSent;
    }
  }
}