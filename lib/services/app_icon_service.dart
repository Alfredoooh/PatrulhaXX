// ════════════════════════════════════════════════════════════════
// app_icon_service.dart
// Coloca este ficheiro em: lib/services/app_icon_service.dart
// ════════════════════════════════════════════════════════════════

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ícones disponíveis para troca
enum AppIconVariant {
  classic,   // Fundo vermelho + texto Nuxxx branco (PREDEFINIDO)
  light,     // Fundo branco + texto Nuxxx vermelho
  original,  // Ícone original do app (squircle vermelho)
}

class AppIconService {
  static const _channel = MethodChannel('com.patrulhaxx/app_icon');
  static const _prefKey = 'selected_app_icon';

  // ── Retorna o ícone atualmente ativo ──────────────────────────
  static Future<AppIconVariant> getActiveIcon() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey) ?? 'classic';
      return _variantFromString(saved);
    } catch (_) {
      return AppIconVariant.classic;
    }
  }

  // ── Troca o ícone da launcher ─────────────────────────────────
  // NOTA: O Android fecha e reabre o app ao trocar — comportamento nativo.
  static Future<void> setIcon(AppIconVariant variant) async {
    final name = _variantToString(variant);
    try {
      await _channel.invokeMethod('setIcon', {'icon': name});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, name);
    } on PlatformException catch (e) {
      throw Exception('Erro ao trocar ícone: ${e.message}');
    }
  }

  static String _variantToString(AppIconVariant v) {
    switch (v) {
      case AppIconVariant.light:    return 'light';
      case AppIconVariant.original: return 'original';
      case AppIconVariant.classic:  return 'classic';
    }
  }

  static AppIconVariant _variantFromString(String s) {
    switch (s) {
      case 'light':    return AppIconVariant.light;
      case 'original': return AppIconVariant.original;
      default:         return AppIconVariant.classic;
    }
  }
}


// ════════════════════════════════════════════════════════════════
// EXEMPLO DE USO nas Definições do app:
// ════════════════════════════════════════════════════════════════
//
// import 'package:flutter/material.dart';
// import 'app_icon_service.dart';
//
// class IconPickerWidget extends StatefulWidget {
//   const IconPickerWidget({super.key});
//   @override State<IconPickerWidget> createState() => _IconPickerWidgetState();
// }
//
// class _IconPickerWidgetState extends State<IconPickerWidget> {
//   AppIconVariant _current = AppIconVariant.classic;
//
//   @override
//   void initState() {
//     super.initState();
//     AppIconService.getActiveIcon().then((v) => setState(() => _current = v));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: AppIconVariant.values.map((variant) {
//         final labels = {
//           AppIconVariant.classic:  'Classic',
//           AppIconVariant.light:    'Light',
//           AppIconVariant.original: 'Original',
//         };
//         return ListTile(
//           leading: Radio<AppIconVariant>(
//             value: variant,
//             groupValue: _current,
//             onChanged: (v) async {
//               if (v == null) return;
//               await AppIconService.setIcon(v);
//               setState(() => _current = v);
//               // App vai fechar e reabrir — comportamento nativo do Android
//             },
//           ),
//           title: Text(labels[variant] ?? ''),
//         );
//       }).toList(),
//     );
//   }
// }
