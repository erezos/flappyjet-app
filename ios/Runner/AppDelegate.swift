import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register native audio engine
    if #available(iOS 12.0, *) {
        NativeAudioEngine.register(with: registrar(forPlugin: "NativeAudioEngine")!)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
