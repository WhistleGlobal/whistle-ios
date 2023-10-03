//
//  WhistleApp.swift
//  Whistle
//
//  Created by 박상원 on 2023/08/23.
//

import GoogleSignIn
import KeychainSwift
import SwiftUI
import VideoPicker

// MARK: - WhistleApp

@main
struct WhistleApp: App {
  // MARK: Lifecycle
  // Layout Test
  init() {
    Font.registerFonts(fontName: "SF-Pro-Display-Semibold")
    Font.registerFonts(fontName: "SF-Pro-Text-Regular")
    Font.registerFonts(fontName: "SF-Pro-Text-Semibold")
    Font.registerFontsTTF(fontName: "SF-Pro")
    Font.registerFontsTTF(fontName: "Roboto-Medium")
  }

  // MARK: Internal

  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @StateObject var rootVM = RootViewModel(mainContext: PersistenceController.shared.viewContext)
  @StateObject var appleSignInViewModel = AppleSignInViewModel()
  @StateObject var userAuth = UserAuth()
  @StateObject var apiViewModel = APIViewModel()
  @StateObject var tabbarModel: TabbarModel = .init()
  @State var testBool = false
  @AppStorage("isAccess") var isAccess = false
  let keychain = KeychainSwift()
  @State private var pickerOptions = PickerOptionsInfo()
  var body: some Scene {
    WindowGroup {
      if isAccess {
        TabbarView()
          .environmentObject(apiViewModel)
          .environmentObject(userAuth)
          .environmentObject(tabbarModel)
          .task {
            if isAccess {
              appleSignInViewModel.userAuth.loadData { }
            }
          }
      } else {
        NavigationStack {
          SignInView()
            .environmentObject(apiViewModel)
            .environmentObject(userAuth)
            .environmentObject(tabbarModel)
        }
        .tint(.black)
      }
    }
  }
}

// MARK: - AppDelegate

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  @AppStorage("deviceToken") var deviceToken = ""

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?)
    -> Bool
  {
    // APNS 설정
    UNUserNotificationCenter.current().delegate = self
    UNUserNotificationCenter.current()
      .requestAuthorization(options: [.alert, .sound, .badge]) {
        [weak self] granted, _ in
        log("Permission granted: \(granted)")
      }
    // APNS 등록
    application.registerForRemoteNotifications()
    return true
  }

  func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    log("Failed to register for notifications: \(error.localizedDescription)")
  }

  // 성공시
  func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    log("Device Token: \(token)")
    self.deviceToken = token
    log("Device Token in appstorage: \(self.deviceToken)")
  }
}

public func log<T>(
  _ object: T?,
  filename: String = #file,
  line: Int = #line,
  funcName: String = #function)
{
  #if DEBUG
  if let obj = object {
    print("\(filename.components(separatedBy: "/").last ?? "")(\(line)) : \(funcName) : \(obj)")
  } else {
    print("\(filename.components(separatedBy: "/").last ?? "")(\(line)) : \(funcName) : nil")
  }
  #endif
}
