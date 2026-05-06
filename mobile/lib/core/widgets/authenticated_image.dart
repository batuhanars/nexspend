import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../di/injection.dart';
import '../network/api_client.dart';

/// JWT korumalı resim endpoint'lerinden bytes çeken ve in-memory cache ile
/// ikinci yüklemede ağa çıkmadan render eden widget. ApiClient (Dio) üzerinden
/// gittiği için Authorization header'ı ve 401 → refresh akışı otomatik çalışır.
class AuthenticatedImage extends StatefulWidget {
  const AuthenticatedImage({
    super.key,
    required this.urlPath,
    this.cacheKey,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  /// Dio baseUrl'ine relatif path, örn. `/api/users/me/avatar`.
  final String urlPath;

  /// Cache busting anahtarı. Aynı urlPath farklı içerik servis ettiğinde
  /// (örn. avatar yenileme) farklı bir cacheKey ile widget yeniden yüklenir.
  final String? cacheKey;

  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  static final Map<String, Uint8List> _cache = {};
  late Future<Uint8List> _future;

  String get _key => widget.cacheKey ?? widget.urlPath;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(AuthenticatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urlPath != widget.urlPath ||
        oldWidget.cacheKey != widget.cacheKey) {
      _future = _load();
    }
  }

  Future<Uint8List> _load() async {
    final cached = _cache[_key];
    if (cached != null) return cached;

    final response = await getIt<ApiClient>().dio.get<List<int>>(
      widget.urlPath,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Empty image response');
    }
    final bytes = Uint8List.fromList(data);
    _cache[_key] = bytes;
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.placeholder ?? const SizedBox.shrink();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return widget.errorWidget ?? const SizedBox.shrink();
        }
        return Image.memory(
          snapshot.data!,
          fit: widget.fit,
          gaplessPlayback: true,
        );
      },
    );
  }
}
