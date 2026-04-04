Agora com essa mesma animação quero que adicionem nesta tela um drawer menu e quero que na tela tenha textos qualquer  
  
import 'package:flutter/material.dart';  
import 'package:flutter/services.dart';  
  
void main() {  
  runApp(const MyApp());  
}  
  
class MyApp extends StatelessWidget {  
  const MyApp({super.key});  
  
  @override  
  Widget build(BuildContext context) {  
    return MaterialApp(  
      debugShowCheckedModeBanner: false,  
      home: const HomeScreen(),  
      theme: ThemeData(  
        useMaterial3: true,  
        fontFamily: 'Arial',  
      ),  
    );  
  }  
}  
  
class HomeScreen extends StatefulWidget {  
  const HomeScreen({super.key});  
  
  @override  
  State<HomeScreen> createState() => _HomeScreenState();  
}  
  
class _HomeScreenState extends State<HomeScreen>  
    with SingleTickerProviderStateMixin {  
  late final AnimationController _sheetController;  
  bool _sheetOpen = false;  
  
  @override  
  void initState() {  
    super.initState();  
    _sheetController = AnimationController(  
      vsync: this,  
      duration: const Duration(milliseconds: 320),  
      reverseDuration: const Duration(milliseconds: 320),  
    );  
  }  
  
  @override  
  void dispose() {  
    _sheetController.dispose();  
    super.dispose();  
  }  
  
  Future<void> _openSheet() async {  
    if (_sheetOpen) return;  
  
    setState(() {  
      _sheetOpen = true;  
    });  
  
    try {  
      await showModalBottomSheet<void>(  
        context: context,  
        isScrollControlled: true,  
        useSafeArea: false,  
        isDismissible: true,  
        enableDrag: true,  
        backgroundColor: Colors.transparent,  
        barrierColor: Colors.black.withOpacity(0.34),  
        transitionAnimationController: _sheetController,  
        builder: (context) {  
          final media = MediaQuery.of(context);  
  
          return Align(  
            alignment: Alignment.bottomCenter,  
            child: ConstrainedBox(  
              constraints: BoxConstraints(  
                maxWidth: 540,  
                minWidth: media.size.width,  
                maxHeight: media.size.height * 0.58,  
              ),  
              child: Material(  
                color: const Color(0xFFF5F5F7),  
                elevation: 0,  
                borderRadius: const BorderRadius.only(  
                  topLeft: Radius.circular(16),  
                  topRight: Radius.circular(16),  
                ),  
                clipBehavior: Clip.antiAlias,  
                child: SafeArea(  
                  top: false,  
                  child: Column(  
                    mainAxisSize: MainAxisSize.max,  
                    children: [  
                      const SizedBox(height: 10),  
                      Container(  
                        width: 40,  
                        height: 4,  
                        decoration: BoxDecoration(  
                          color: const Color(0xFF3C3C43).withOpacity(0.25),  
                          borderRadius: BorderRadius.circular(999),  
                        ),  
                      ),  
                      const SizedBox(height: 14),  
                      const Text(  
                        'iOS Paper Sheet',  
                        textAlign: TextAlign.center,  
                        style: TextStyle(  
                          fontSize: 18,  
                          fontWeight: FontWeight.w700,  
                          color: Color(0xFF111111),  
                        ),  
                      ),  
                      const SizedBox(height: 8),  
                      const Padding(  
                        padding: EdgeInsets.symmetric(horizontal: 20),  
                        child: Text(  
                          'Este é um modal real do Flutter, com animação sincronizada com a tela.',  
                          textAlign: TextAlign.center,  
                          style: TextStyle(  
                            fontSize: 15,  
                            height: 1.45,  
                            color: Color(0xB8000000),  
                          ),  
                        ),  
                      ),  
                      const SizedBox(height: 18),  
                      Expanded(  
                        child: SingleChildScrollView(  
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),  
                          child: Column(  
                            children: [  
                              Row(  
                                mainAxisAlignment: MainAxisAlignment.center,  
                                children: [  
                                  TextButton(  
                                    onPressed: () => Navigator.of(context).pop(),  
                                    style: TextButton.styleFrom(  
                                      backgroundColor: const Color(0xFFE9E9EE),  
                                      foregroundColor: const Color(0xFF111111),  
                                      padding: const EdgeInsets.symmetric(  
                                        horizontal: 18,  
                                        vertical: 12,  
                                      ),  
                                      shape: RoundedRectangleBorder(  
                                        borderRadius: BorderRadius.circular(12),  
                                      ),  
                                    ),  
                                    child: const Text('Fechar'),  
                                  ),  
                                  const SizedBox(width: 10),  
                                  TextButton(  
                                    onPressed: () {},  
                                    style: TextButton.styleFrom(  
                                      backgroundColor: const Color(0xFF0A84FF),  
                                      foregroundColor: Colors.white,  
                                      padding: const EdgeInsets.symmetric(  
                                        horizontal: 18,  
                                        vertical: 12,  
                                      ),  
                                      shape: RoundedRectangleBorder(  
                                        borderRadius: BorderRadius.circular(12),  
                                      ),  
                                    ),  
                                    child: const Text('Confirmar'),  
                                  ),  
                                ],  
                              ),  
                            ],  
                          ),  
                        ),  
                      ),  
                    ],  
                  ),  
                ),  
              ),  
            ),  
          );  
        },  
      );  
    } finally {  
      if (mounted) {  
        setState(() {  
          _sheetOpen = false;  
        });  
      }  
    }  
  }  
  
  @override  
  Widget build(BuildContext context) {  
    final media = MediaQuery.of(context);  
  
    return AnimatedBuilder(  
      animation: _sheetController,  
      builder: (context, child) {  
        final t = _sheetController.value;  
  
        final overlayStyle = t > 0.01  
            ? const SystemUiOverlayStyle(  
                statusBarColor: Colors.transparent,  
                statusBarIconBrightness: Brightness.light,  
                statusBarBrightness: Brightness.dark,  
              )  
            : const SystemUiOverlayStyle(  
                statusBarColor: Colors.transparent,  
                statusBarIconBrightness: Brightness.dark,  
                statusBarBrightness: Brightness.light,  
              );  
  
        return AnnotatedRegion<SystemUiOverlayStyle>(  
          value: overlayStyle,  
          child: Scaffold(  
            backgroundColor: Colors.black,  
            body: Stack(  
              children: [  
                Transform.translate(  
                  offset: Offset(0, 14 * t),  
                  child: Transform.scale(  
                    scale: 1 - (0.055 * t),  
                    alignment: Alignment.center,  
                    child: Container(  
                      width: media.size.width,  
                      height: media.size.height,  
                      decoration: BoxDecoration(  
                        color: Colors.white,  
                        borderRadius: BorderRadius.circular(18 * t),  
                        boxShadow: t > 0  
                            ? [  
                                BoxShadow(  
                                  color: Colors.black.withOpacity(0.18 * t),  
                                  blurRadius: 24,  
                                  offset: const Offset(0, 10),  
                                ),  
                              ]  
                            : [],  
                      ),  
                      child: SafeArea(  
                        child: Center(  
                          child: ElevatedButton(  
                            onPressed: _sheetOpen ? null : _openSheet,  
                            style: ElevatedButton.styleFrom(  
                              backgroundColor: const Color(0xFF111111),  
                              foregroundColor: Colors.white,  
                              elevation: 0,  
                              padding: const EdgeInsets.symmetric(  
                                horizontal: 22,  
                                vertical: 14,  
                              ),  
                              shape: RoundedRectangleBorder(  
                                borderRadius: BorderRadius.circular(14),  
                              ),  
                            ),  
                            child: Text(  
                              _sheetOpen ? 'A abrir...' : 'Reduzir tela',  
                            ),  
                          ),  
                        ),  
                      ),  
                    ),  
                  ),  
                ),  
              ],  
            ),  
          ),  
        );  
      },  
    );  
  }  
}