import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/debug_logger.dart';

/// Google UMP consent. Ads wait until this finishes.
class ConsentManager {
  static final ConsentManager _instance = ConsentManager._();
  factory ConsentManager() => _instance;
  ConsentManager._();

  bool _ready = false;
  bool get canRequestAds => _ready;

  Future<void> gatherConsent() async {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((error) {
            if (error != null) {
              safePrint('📜 Consent form error: ${error.message}');
            }
          });
        } catch (e) {
          safePrint('📜 Consent form failed: $e');
        }
        _ready = await ConsentInformation.instance.canRequestAds();
        if (!completer.isCompleted) completer.complete();
      },
      (error) {
        safePrint('📜 Consent info update failed: ${error.message}');
        _ready = true;
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future.timeout(const Duration(seconds: 8), onTimeout: () {
      _ready = true;
    });
  }
}
