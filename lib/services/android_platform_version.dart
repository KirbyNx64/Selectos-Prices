import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AndroidPlatformVersion {
  AndroidPlatformVersion._();

  static const _channel = MethodChannel(
    'com.kirby.selectos_prices/platform_version',
  );

  static int? _sdkInt;

  static bool get isAndroid16OrNewer {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    // En pruebas o si el canal falla, usamos el comportamiento conservador
    // que nunca permite cerrar la app junto con el teclado.
    return (_sdkInt ?? 36) >= 36;
  }

  static Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      _sdkInt = await _channel.invokeMethod<int>('getSdkInt');
    } on PlatformException {
      _sdkInt = 36;
    } on MissingPluginException {
      _sdkInt = 36;
    }
  }
}
