import 'package:flutter/material.dart';

class SiteModel {
  final String id;
  final String name;
  final String baseUrl;
  final String allowedDomain;
  final String searchUrl;
  final String? localIconAsset;
  Color primaryColor;

  SiteModel({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.allowedDomain,
    required this.searchUrl,
    this.localIconAsset,
    this.primaryColor = const Color(0xFF2A2A2A),
  });

  String get faviconUrl =>
      'https://www.google.com/s2/favicons?domain=$allowedDomain&sz=128';

  bool get hasLocalIcon => localIconAsset != null;

  String buildUrl({String? query}) {
    if (query != null && query.trim().isNotEmpty) {
      return searchUrl.replaceAll('{q}', Uri.encodeComponent(query.trim()));
    }
    return baseUrl;
  }
}

final List<SiteModel> kSites = [
  SiteModel(
    id: 'xvideos',
    name: 'XVideos',
    baseUrl: 'https://www.xvideos.com',
    allowedDomain: 'xvideos.com',
    searchUrl: 'https://www.xvideos.com/?k={q}',
    primaryColor: const Color(0xFFFF6600),
  ),
  SiteModel(
    id: 'xxx',
    name: 'XXX.com',
    baseUrl: 'https://www.xxx.com',
    allowedDomain: 'xxx.com',
    searchUrl: 'https://www.xxx.com/search?q={q}',
    primaryColor: const Color(0xFFAA0000),
  ),
  SiteModel(
    id: 'pornhub',
    name: 'PornHub',
    baseUrl: 'https://pt.pornhub.com',
    allowedDomain: 'pornhub.com',
    searchUrl: 'https://pt.pornhub.com/video/search?search={q}',
    localIconAsset: 'assets/icons/app1.png',
    primaryColor: const Color(0xFFFF9900),
  ),
  SiteModel(
    id: 'xnxx',
    name: 'XNXX',
    baseUrl: 'https://www.xnxx.com',
    allowedDomain: 'xnxx.com',
    searchUrl: 'https://www.xnxx.com/search/{q}',
    primaryColor: const Color(0xFF006600),
  ),
  SiteModel(
    id: 'tikporn',
    name: 'Tik Porn',
    baseUrl: 'https://tik.porn',
    allowedDomain: 'tik.porn',
    searchUrl: 'https://tik.porn/?s={q}',
    primaryColor: const Color(0xFF0044DD),
  ),
  SiteModel(
    id: 'bangbros',
    name: 'Bang Bros',
    baseUrl: 'https://bangbros.com',
    allowedDomain: 'bangbros.com',
    searchUrl: 'https://bangbros.com/video?q={q}',
    primaryColor: const Color(0xFFDD2200),
  ),
  SiteModel(
    id: 'xhamster',
    name: 'xHamster',
    baseUrl: 'https://xhamster.com',
    allowedDomain: 'xhamster.com',
    searchUrl: 'https://xhamster.com/search/{q}',
    primaryColor: const Color(0xFFFF5500),
  ),
  SiteModel(
    id: 'redtube',
    name: 'RedTube',
    baseUrl: 'https://www.redtube.com.br',
    allowedDomain: 'redtube.com',
    searchUrl: 'https://www.redtube.com.br/?search={q}',
    primaryColor: const Color(0xFFCC0000),
  ),
  SiteModel(
    id: 'youxxx',
    name: 'YouX',
    baseUrl: 'https://www.youx.xxx/videos/',
    allowedDomain: 'youx.xxx',
    searchUrl: 'https://www.youx.xxx/search/{q}',
    primaryColor: const Color(0xFF7700CC),
  ),
  SiteModel(
    id: 'pornpics',
    name: 'PornPics',
    baseUrl: 'https://www.pornpics.com/pt/',
    allowedDomain: 'pornpics.com',
    searchUrl: 'https://www.pornpics.com/search/?q={q}',
    primaryColor: const Color(0xFFCC0055),
  ),
];
