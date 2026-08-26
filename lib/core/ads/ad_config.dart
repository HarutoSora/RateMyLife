/// AdMob ad unit IDs. The app ID itself lives in
/// `android/app/src/main/AndroidManifest.xml` (the SDK reads it from
/// there at startup, not from Dart).
class AdConfig {
  const AdConfig._();

  // TEMP: Google's official test banner ID, kept in place until the
  // real ad unit starts filling — AdMob is still reviewing this
  // brand-new app (real ID gets "no fill", error 3). Swap back to
  // 'ca-app-pub-9503065477167980/6128827983' once it starts serving.
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String rewardedAdUnitId = 'ca-app-pub-9503065477167980/8483528580';
  static const String interstitialAdUnitId = 'ca-app-pub-9503065477167980/6187899707';
}
