import 'package:flutter/material.dart';
import '../services/favicon_service.dart';
import '../services/download_service.dart';
import '../services/lock_service.dart';
import 'lock_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _lockEnabled = false;

  @override
  void initState() {
    super.initState();
    LockService.instance.isEnabled().then((v) {
      if (mounted) setState(() => _lockEnabled = v);
    });
  }

  void _toggleLock(bool value) {
    _verifyPin(onSuccess: () async {
      await LockService.instance.setEnabled(value);
      if (mounted) setState(() => _lockEnabled = value);
      _snack(value ? 'Bloqueio ativado' : 'Bloqueio desativado');
    });
  }

  void _verifyPin({required VoidCallback onSuccess}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PinSheet(child: LockScreen(
        mode: LockMode.unlock,
        onUnlocked: () { Navigator.pop(context); onSuccess(); },
      )),
    );
  }

  void _changePin() {
    _verifyPin(onSuccess: () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PinSheet(child: LockScreen(
          mode: LockMode.setNew,
          onPinSet: (pin) async {
            await LockService.instance.setPin(pin);
            if (mounted) { Navigator.pop(context); _snack('PIN alterado'); }
          },
        )),
      );
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1C1C1C),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0C0C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Definições',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _section('Segurança', [
            _switchTile(
              icon: Icons.lock_outline_rounded,
              title: 'Bloquear app',
              subtitle: _lockEnabled ? 'PIN obrigatório ao abrir' : 'App abre sem PIN',
              value: _lockEnabled,
              onChanged: _toggleLock,
            ),
            if (_lockEnabled) ...[
              _divider(),
              _tile(icon: Icons.key_rounded, title: 'Alterar PIN',
                  subtitle: 'Define um novo código', onTap: _changePin),
            ],
          ]),
          const SizedBox(height: 12),
          _section('Privacidade', [
            _tile(
              icon: Icons.refresh_rounded,
              title: 'Recarregar ícones',
              subtitle: 'Baixa novamente os favicons',
              onTap: () async {
                await FaviconService.instance.clearAll();
                await FaviconService.instance.preloadAll();
                if (context.mounted) _snack('Ícones recarregados');
              },
            ),
            _divider(),
            _tile(
              icon: Icons.delete_outline_rounded,
              title: 'Limpar downloads',
              subtitle: 'Apaga todos os ficheiros baixados',
              onTap: () => _confirmClear(context),
            ),
          ]),
          const SizedBox(height: 12),
          _section('Sobre', [
            _tile(
              icon: Icons.shield_outlined,
              title: 'patrulhaXX',
              subtitle: 'Versão 1.0.0 · Navegação privada',
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
        child: Text(title.toUpperCase(),
            style: TextStyle(color: Colors.white.withOpacity(0.3),
                fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
      ),
      Container(
        decoration: BoxDecoration(color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(14)),
        child: Column(children: children),
      ),
    ]);
  }

  Widget _divider() =>
      Divider(height: 1, color: Colors.white.withOpacity(0.06), indent: 16, endIndent: 16);

  Widget _tile({required IconData icon, required String title,
      required String subtitle, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(icon, color: Colors.white60, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white,
                  fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(
                  color: Colors.white.withOpacity(0.35), fontSize: 12)),
            ])),
            Icon(Icons.chevron_right_rounded, color: Colors.white12, size: 18),
          ]),
        ),
      ),
    );
  }

  Widget _switchTile({required IconData icon, required String title,
      required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, color: Colors.white60, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white,
              fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(
              color: Colors.white.withOpacity(0.35), fontSize: 12)),
        ])),
        Switch(
          value: value, onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFF4A9EFF),
          inactiveThumbColor: Colors.white38,
          inactiveTrackColor: Colors.white12,
        ),
      ]),
    );
  }

  void _confirmClear(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white12,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Limpar downloads?',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Todos os ficheiros serão apagados permanentemente.',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(height: 46,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(23)),
                child: const Center(child: Text('Cancelar',
                    style: TextStyle(color: Colors.white70)))),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                for (final item in DownloadService.instance.items.toList()) {
                  await DownloadService.instance.delete(item.id);
                }
                if (context.mounted) _snack('Downloads limpos');
              },
              child: Container(height: 46,
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(23)),
                child: const Center(child: Text('Apagar tudo',
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)))),
            )),
          ]),
        ]),
      ),
    );
  }
}

class _PinSheet extends StatelessWidget {
  final Widget child;
  const _PinSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF0C0C0C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: child,
      ),
    );
  }
}
