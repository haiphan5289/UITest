//
//  AppDelegate.swift
//  GooDic
//
//  Created by ttvu on 5/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import FirebaseMessaging
import AppsFlyerLib
import GooidSDK
import AppTrackingTransparency
import AdSupport
//#if DEBUG
//import RxSwift
//#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var appCoordinator: AppCoordinator?
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        #if DEBUG
//        var lastResources: Int = 0
//        _ = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
//            .subscribe(onNext: { (_) in
//                let increase = Int(Resources.total) - lastResources
//                lastResources = Int(Resources.total)
//                if increase != 0 {
//                    print("Resource change \(lastResources) \(increase )")
//                } else {
//                    print("Resource \(lastResources)")
//                }
//            })
//        #endif
        
        // Firebase configure
        FirebaseApp.configure()
        
        
        //Set default connect to Firebase Staging
//        if let configFile = Bundle.main.path(forResource: "GoogleService-Info_stage", ofType: "plist"),
//           let options = FirebaseOptions(contentsOfFile: configFile) {
//            FirebaseApp.configure(options: options)
//        }
        
        // Notification with Firebase
        Messaging.messaging().delegate = self
        
        // Disable in-app messaging, we are going to enable it after openning home view
        InAppMessaging.inAppMessaging().messageDisplaySuppressed = true
        
        // Inject GooServices
        GooServices.shared.add({ DatabaseService(gateway: DatabaseCoreDataGateway()) })
        
//        GooServices.shared.add({ RemoteConfigService(gateway: RemoteConfigLocalGateway()) })
//        GooServices.shared.add({ IdiomService(gateway: IdiomLocalGateway()) })
//        GooServices.shared.add({ ThesaurusService(gateway: ThesaurusLocalGateway()) })
//        GooServices.shared.add({ DictionaryService(gateway: DictionaryLocalGateway()) })
//        GooServices.shared.add({ SuggestionSearchService(gateway: SuggestionSearchLocalGateway()) })
//        GooServices.shared.add({ CloudService(gateway: CloudMockDataGateway()) })
        
        GooServices.shared.add({ RemoteConfigService(gateway: RemoteConfigFirestoreGateway()) })
        GooServices.shared.add({ IdiomService(gateway: IdiomGooGateway()) })
        GooServices.shared.add({ ThesaurusService(gateway: ThesaurusGooGateway()) })
        GooServices.shared.add({ DictionaryService(gateway: DictionaryGooGateway()) })
        GooServices.shared.add({ SuggestionSearchService(gateway: SuggestionSearchGooGateway()) })
        GooServices.shared.add({ AuthenticationService(gateway: AuthenticationGooIDGateway()) })
        GooServices.shared.add({ CloudService(gateway: CloudGooGateway()) })
        
        if #available(iOS 15, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(requestTracking), name: UIApplication.didBecomeActiveNotification, object: nil)
        } else if #available(iOS 14, *) {
            self.requestIDFA { (status) in
                print(status)

                DispatchQueue.main.async {
                    self.requestNotification()
                    application.registerForRemoteNotifications()
                }
            }
        } else {
            // Register Notification
            requestNotification()
            application.registerForRemoteNotifications()
        }
        
        // setup AppsFlyer
        AppsFlyerLib.shared().appsFlyerDevKey = GlobalConstant.appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = GlobalConstant.appleAppID
        AppsFlyerLib.shared().delegate = self
//        #if DEBUG
//        AppsFlyerLib.shared().isDebug = true
//        #endif
        
        // launching on iOS 12
        guard #available(iOS 13.0, *) else {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            appCoordinator = AppCoordinator(window: window!)
            appCoordinator?.prepare()
                .start()
            
            PremiumProduct.store.start()
            return GooidSDK.sharedInstance.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
        
        PremiumProduct.store.start()
        
//        if CommandLine.arguments.contains("--libiScreenshots") {
//          // We are in testing mode, make arrangements
//          configStore = ScreenshotsConfigStore()
//          configStore.dataPointsManager.makeExampleData()
//        }
        
        return GooidSDK.sharedInstance.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // in iOS 12
    func applicationWillEnterForeground(_ application: UIApplication) {
        // reset badge number
        application.applicationIconBadgeNumber = 0
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Start the SDK (start the IDFA timeout set above, for iOS 14 or later)
        AppsFlyerLib.shared().start()
        
        GooidSDK.sharedInstance.applicationDidBecomeActive(application)
    }
    
    // MARK: UISceneSession Lifecycle
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    @objc func sendLaunch(app: Any) {
        AppsFlyerLib.shared().start()
    }
    
    // Open Deeplinks
    // Open URI-scheme for iOS 8 and below
    private func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: restorationHandler)
        return true
    }
    
    // Open URI-scheme for iOS 9 and above
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        AppsFlyerLib.shared().handleOpen(url, sourceApplication: sourceApplication, withAnnotation: annotation)
        
        return GooidSDK.sharedInstance.application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    // Report Push Notification attribution data for re-engagement
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        AppsFlyerLib.shared().handleOpen(url, options: options)
        return true
    }

    // Reports app open from deep link for iOS 10 or later
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        return true
    }
    
    @available(iOS 14, *)
    func requestIDFA(_ complete: ((ATTrackingManager.AuthorizationStatus) -> Void)? = nil) {
        ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
            complete?(status)
        })
    }
    
    func requestNotification() {
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { _, _ in })
    }
    
    @objc @available(iOS 15, *)
    private func requestTracking() {
        self.requestIDFA { (status) in
            print(status)

            DispatchQueue.main.async {
                self.requestNotification()
                UIApplication.shared.registerForRemoteNotifications()
            }
            NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        }
    }
}

// MARK: - Notification
extension AppDelegate {
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        AppsFlyerLib.shared().handlePushNotification(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
        
        AppsFlyerLib.shared().handlePushNotification(userInfo)
    }
    // [END receive_message]
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved: \(deviceToken)")
        
        // With swizzling disabled you must set the APNs token here.
        // Messaging.messaging().apnsToken = deviceToken
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([[.alert, .sound, .badge]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        if let uri = userInfo["URI"] as? String {
            var coord: AppCoordinator? = nil
            if #available(iOS 13.0, *) {
                coord = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.appCoordinator
            } else {
                coord = appCoordinator
            }
            
            coord?.toDynamicView(description: uri, entryAction: .schemeUriNormal)
        }
        
        completionHandler()
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
}

// MARK: - AppsFlyerLibDelegate
extension AppDelegate: AppsFlyerLibDelegate {
    
    // Handle Organic/Non-organic installation
    func onConversionDataSuccess(_ installData: [AnyHashable: Any]) {
        print("onConversionDataSuccess data:")
        for (key, value) in installData {
            print(key, ":", value)
        }
        if let status = installData["af_status"] as? String {
            if (status == "Non-organic") {
                if let sourceID = installData["media_source"],
                   let campaign = installData["campaign"] {
                    print("This is a Non-Organic install. Media source: \(sourceID)  Campaign: \(campaign)")
                }
            } else {
                print("This is an organic install.")
            }
            if let is_first_launch = installData["is_first_launch"] as? Bool,
               is_first_launch {
                print("First Launch")
            } else {
                print("Not First Launch")
            }
        }
    }
    
    func onConversionDataFail(_ error: Error) {
        print(error)
    }
    
    //Handle Deep Link
    func onAppOpenAttribution(_ attributionData: [AnyHashable : Any]) {
        //Handle Deep Link Data
        print("onAppOpenAttribution data:")
        for (key, value) in attributionData {
            print(key, ":",value)
        }
    }
    
    func onAppOpenAttributionFailure(_ error: Error) {
        print(error)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        PremiumProduct.store.end()
    }
}

extension AppDelegate: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        GooidSDK.sharedInstance.sign(signIn, didSignInFor: user, withError: error)
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        GooidSDK.sharedInstance.sign(signIn, didDisconnectWith: user, withError: error)
    }
}
