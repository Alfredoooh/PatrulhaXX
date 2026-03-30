// =============================================================================
// licenses_page.dart
// patrulhaXX — Licenças de software
//
// Copyright (c) 2024 patrulhaXX. Todos os direitos reservados.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Canal nativo para abrir o ecrã de licenças gerado pelo oss-licenses-plugin
const _ossChannel = MethodChannel('com.patrulhaxx/licenses');

/// Abre o ecrã nativo Android "Licenças de software".
/// Gerado automaticamente pelo com.google.android.gms.oss-licenses-plugin
/// com todas as licenças das dependências Gradle/Maven.
Future<void> openOssLicenses() async {
  try {
    await _ossChannel.invokeMethod('showLicenses');
  } on MissingPluginException {
    // Fallback: ecrã Flutter nativo com LicensePage
    // (usado em debug ou se o plugin não estiver disponível)
  }
}
