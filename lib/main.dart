import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/storage_service.dart';
import 'services/bluetooth_service.dart';
import 'screens/home_screen.dart';
import 'screens/config_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 1ª execução: copia itens.json -> itens_usuario.json
  await StorageService.ensureUserJson();
  // tenta preparar/reconectar BT para a tela inicial já saber o estado
  await BluetoothService.instance.bootstrap();
  runApp(const EtiquetadorApp());
}

class EtiquetadorApp extends StatelessWidget {
  const EtiquetadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xfff7f8fb),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff2d7df6),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        // opcional:
        // surfaceTintColor: Colors.transparent, // evita “sombra” azul no M3
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Etiquetador',
      theme: theme,
      routes: {
        '/': (_) => const HomeScreen(),
        ConfigScreen.route: (_) => const ConfigScreen(),
      },
    );
  }
}
