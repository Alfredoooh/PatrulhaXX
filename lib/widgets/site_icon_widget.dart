import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/site_model.dart';
import '../services/favicon_service.dart';

class SiteIconWidget extends StatefulWidget {
  final SiteModel site;
  final double size;
  final bool showShadow;

  const SiteIconWidget({
    super.key,
    required this.site,
    this.size = 56,
    this.showShadow = true,
  });

  @override
  State<SiteIconWidget> createState() => _SiteIconWidgetState();
}

class _SiteIconWidgetState extends State<SiteIconWidget> {
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.site.hasLocalIcon) return;
    final path = await FaviconService.instance.getLocalPath(widget.site);
    if (mounted) setState(() => _localPath = path);
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;

    Widget iconContent;

    if (widget.site.hasLocalIcon) {
      iconContent = Image.asset(
        widget.site.localIconAsset!,
        width: s,
        height: s,
        fit: BoxFit.cover,
      );
    } else if (_localPath != null && File(_localPath!).existsSync()) {
      iconContent = Image.file(
        File(_localPath!),
        width: s,
        height: s,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(s),
      );
    } else {
      iconContent = CachedNetworkImage(
        imageUrl: widget.site.faviconUrl,
        width: s,
        height: s,
        fit: BoxFit.cover,
        placeholder: (_, __) => _fallback(s),
        errorWidget: (_, __, ___) => _fallback(s),
      );
    }

    return Container(
      width: s,
      height: s,
      // Sem boxShadow colorido — ícones limpos sem gradiente
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: ClipOval(child: iconContent),
    );
  }

  Widget _fallback(double s) => Container(
        width: s,
        height: s,
        color: widget.site.primaryColor,
        child: Center(
          child: Text(
            widget.site.name[0].toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: s * 0.42,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
}
