// ignore_for_file: uri_does_not_exist, avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

void enterWebFullscreen() {
  try {
    js_util.callMethod(js_util.globalThis, '_enterFullscreen', []);
  } catch (_) {}
}

void exitWebFullscreen() {
  try {
    js_util.callMethod(js_util.globalThis, '_exitFullscreen', []);
  } catch (_) {}
}
