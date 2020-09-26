import UIKit
import SafariServices
import UserNotifications

enum Identifiers {
  static let viewAction = "VIEW_IDENTIFIER"
  static let newsCategory = "NEWS_CATEGORY"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    UITabBar.appearance().barTintColor = UIColor.themeGreenColor
    UITabBar.appearance().tintColor = UIColor.white
    //get deviceToken
    registerForPushNotifications()
    
    //app wasn’t running and user launches it by tapping the push notification
    // Check if launched from notification
    let notificationOption = launchOptions?[.remoteNotification]
    if let notification = notificationOption as? [String: AnyObject],
      let aps = notification["aps"] as? [String: AnyObject] {
      NewsItem.makeNewsItem(aps)
      (window?.rootViewController as? UITabBarController)?.selectedIndex = 1
    }
    //actionable notification
    UNUserNotificationCenter.current().delegate = self
    return true
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    guard let aps = userInfo["aps"] as? [String: AnyObject] else {
      completionHandler(.failed)
      return
    }
    //NewsItem.makeNewsItem(aps)
    //Silent notification
    if aps["content-available"] as? Int == 1 {
      let podcastStore = PodcastStore.sharedStore
      podcastStore.refreshItems { didLoadNewItems in
        completionHandler(didLoadNewItems ? .newData : .noData)
      }
    } else  {
      NewsItem.makeNewsItem(aps)
      completionHandler(.newData)
    }
  }
  
  func registerForPushNotifications() {
    let opt:UNAuthorizationOptions = [.alert, .sound, .badge]
    UNUserNotificationCenter.current().requestAuthorization(options: opt) {
        granted, error in
      print("Today is Ssturday")
        print("Permission granted: \(granted)")
        guard granted else { return }
        //actionable notification
        let viewAction = UNNotificationAction(
          identifier: Identifiers.viewAction, title: "View",
          options: [.foreground])
        let newsCategory = UNNotificationCategory(
          identifier: Identifiers.newsCategory, actions: [viewAction],
          intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([newsCategory])
        
        self.getNotificationSettings()
    }
  }
  func getNotificationSettings() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      print("Notification settings: \(settings)")
      
      guard settings.authorizationStatus == .authorized else { return }
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenParts = deviceToken.map {
      data in
      String(format: "%02.2hhx", data)
    }
    let token = tokenParts.joined()
    print("Device Token: \(token)")
  }

  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register: \(error)")
  }
}
//actionable notification
extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    if let aps = userInfo["aps"] as? [String: AnyObject], let newsItem = NewsItem.makeNewsItem(aps) {
      (window?.rootViewController as? UITabBarController)?.selectedIndex = 1
      if response.actionIdentifier == Identifiers.viewAction,
        let url = URL(string: newsItem.link) {
        let safari = SFSafariViewController(url: url)
        window?.rootViewController?.present(safari, animated: true,
                                            completion: nil)
      }
    }
    completionHandler()
  }
}
