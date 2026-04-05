import 'package:flutter/material.dart';

void main() {
  runApp(const DrawerApp());
}

class DrawerApp extends StatelessWidget {
  const DrawerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const DrawerHomePage(),
      theme: ThemeData(useMaterial3: true),
    );
  }
}

class DrawerHomePage extends StatefulWidget {
  const DrawerHomePage({super.key});

  @override
  State<DrawerHomePage> createState() => _DrawerHomePageState();
}

class _DrawerHomePageState extends State<DrawerHomePage> {
  static const double drawerWidth = 260;
  static const double appShift = 110;
  static const Duration animDuration = Duration(milliseconds: 420);
  static const Cubic animCurve = Cubic(0.22, 1.0, 0.36, 1.0);

  bool isOpen = false;

  void toggleDrawer() {
    setState(() {
      isOpen = !isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // App content primeiro, para ficar atrás
          AnimatedPositioned(
            duration: animDuration,
            curve: animCurve,
            top: 0,
            bottom: 0,
            left: isOpen ? appShift : 0,
            right: isOpen ? -appShift : 0,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      color: Colors.white,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: toggleDrawer,
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            child: const IconMenu(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Minha tela Flutter',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overlay no meio
          AnimatedOpacity(
            duration: animDuration,
            curve: animCurve,
            opacity: isOpen ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !isOpen,
              child: GestureDetector(
                onTap: toggleDrawer,
                child: Container(
                  color: const Color.fromRGBO(0, 0, 0, 0.18),
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),

          // Drawer por cima de tudo
          AnimatedPositioned(
            duration: animDuration,
            curve: animCurve,
            top: 0,
            bottom: 0,
            left: isOpen ? 0 : -drawerWidth,
            width: drawerWidth,
            child: Container(
              padding: EdgeInsets.only(
                top: topPadding + 20,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F4F4),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.12),
                    blurRadius: 14,
                    offset: Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                  ),
                  SizedBox(height: 16),
                  Divider(height: 1, color: Color.fromRGBO(0, 0, 0, 0.08)),
                  _DrawerItem(title: 'Início'),
                  _DrawerItem(title: 'Perfil'),
                  _DrawerItem(title: 'Configurações'),
                  _DrawerItem(title: 'Sair'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String title;

  const _DrawerItem({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF222222),
        ),
      ),
    );
  }
}

class IconMenu extends StatelessWidget {
  const IconMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 18,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _line(),
          _line(),
          _line(),
        ],
      ),
    );
  }

  Widget _line() {
    return Container(
      width: 24,
      height: 2.5,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}