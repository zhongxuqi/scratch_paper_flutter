import UIKit
import Flutter
import AuthenticationServices

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UMCommonSwift.initWithAppkey(appKey: "56ecff3ce0f55ac331000a80", channel: "ios")
        UMAnalyticsSwift.setCrashReportEnabled(value: true)
        UMAnalyticsSwift.setAutoPageEnabled(value: true)
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
