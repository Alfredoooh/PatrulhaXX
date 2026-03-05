// ==================== MainActivity.kt ====================
// Localização: android/app/src/main/kotlin/com/write/app/MainActivity.kt

package com.write.app

import android.os.Bundle
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Habilita depuração do WebView (apenas para desenvolvimento - remova em produção)
        // WebView.setWebContentsDebuggingEnabled(true)
        
        // Melhora a qualidade de renderização do WebView
        try {
            WebView.enableSlowWholeDocumentDraw()
        } catch (e: Exception) {
            // Ignora se o método não estiver disponível (API antiga)
        }
    }
}