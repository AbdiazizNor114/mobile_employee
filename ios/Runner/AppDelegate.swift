import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var apnsChannel: FlutterMethodChannel?
  private var pendingApnsResult: FlutterResult?
  private var latestApnsToken: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ShaqoNetApnsPlugin") {
      apnsChannel = FlutterMethodChannel(
        name: "shaqonet/apns",
        binaryMessenger: registrar.messenger()
      )
      apnsChannel?.setMethodCallHandler { [weak self] call, result in
        guard call.method == "registerForRemoteNotifications" else {
          result(FlutterMethodNotImplemented)
          return
        }
        self?.registerForRemoteNotifications(result: result)
      }
    }
  }

  private func registerForRemoteNotifications(result: @escaping FlutterResult) {
    if let token = latestApnsToken {
      result(token)
      return
    }

    pendingApnsResult = result
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
      if let error = error {
        DispatchQueue.main.async {
          self?.pendingApnsResult?(
            FlutterError(
              code: "APNS_PERMISSION_FAILED",
              message: error.localizedDescription,
              details: nil
            )
          )
          self?.pendingApnsResult = nil
        }
        return
      }

      guard granted else {
        DispatchQueue.main.async {
          self?.pendingApnsResult?(
            FlutterError(
              code: "APNS_PERMISSION_DENIED",
              message: "Notifications permission was denied.",
              details: nil
            )
          )
          self?.pendingApnsResult = nil
        }
        return
      }

      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    latestApnsToken = token
    pendingApnsResult?(token)
    pendingApnsResult = nil
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    pendingApnsResult?(
      FlutterError(
        code: "APNS_REGISTRATION_FAILED",
        message: error.localizedDescription,
        details: nil
      )
    )
    pendingApnsResult = nil
  }
}
