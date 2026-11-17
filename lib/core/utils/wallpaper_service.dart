/// Opens Android's preview for the Calm Attack live wallpaper.
///
/// The wallpaper itself is native Android code
/// (android/.../CalmWallpaperService.kt). It isn't available on iPhone or
/// the web, so the button is shown only on Android.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CalmWallpaper {
  static const _channel = MethodChannel('calm_attack/wallpaper');

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Returns true if Android's wallpaper screen opened.
  static Future<bool> openPreview() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('openPreview') ?? false;
    } on PlatformException {
      return false;
    }
  }
}
