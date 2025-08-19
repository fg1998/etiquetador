import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import '../models/item.dart';

class StorageService {
  static const _userFile = 'itens_usuario.json';
  static const _bundleFile = 'assets/itens.json';

  static Future<File> _userFileHandle() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_userFile');
    // (Documents é persistente entre updates e oculto do usuário)
  }

  /// Copia o template na primeira execução
  static Future<void> ensureUserJson() async {
    final f = await _userFileHandle();
    if (!await f.exists()) {
      final raw = await rootBundle.loadString(_bundleFile);
      await f.writeAsString(raw, flush: true);
    }
  }

  static Future<List<Item>> readAll() async {
    final f = await _userFileHandle();
    final raw = await f.readAsString();
    final list = json.decode(raw) as List;
    return list.map((e) => Item.fromJson(e)).toList();
  }

  static Future<void> writeAll(List<Item> items) async {
    final f = await _userFileHandle();
    final raw = json.encode(items.map((e) => e.toJson()).toList());
    await f.writeAsString(raw, flush: true);
  }

  static Future<void> add(Item item) async {
    final items = await readAll();
    items.add(item);
    await writeAll(items);
  }

  static Future<void> update(int index, Item item) async {
    final items = await readAll();
    if (index >= 0 && index < items.length) {
      items[index] = item;
      await writeAll(items);
    }
  }

  static Future<void> remove(int index) async {
    final items = await readAll();
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      await writeAll(items);
    }
  }
}
