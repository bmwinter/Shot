//
//  AppDelegate.swift
//  Shot
//
//  Created by Brendan Winter on 1/6/17.
//  Copyright © 2017 TechFi Apps. All rights reserved.
//

import UIKit
import Material
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    let baseURL = "https://www.techfiapps.com/api"
    var isPostViewControllerActive = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: Screen.bounds)
        
        //enable push notifications on iOS 9 & 10
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in }
            application.registerForRemoteNotifications()
        }
        else { // only iOS 9 since thats the deployment target
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
        
        // set token for registration
        let prefs = UserDefaults.standard
        prefs.setValue("", forKey: "token")
                
        // open signup or posts page
        if let loggedIn = prefs.string(forKey: "loggedIn") { // not signed up
            if (loggedIn == "true") {
                // open image stack
                window!.rootViewController = ShotPageTabBarController(viewControllers: [PostsViewController(), GroupsTableViewController(), FriendsTableViewController()], selectedIndex: 0)
            } else {
                prefs.setValue("false", forKey: "loggedIn")
                window!.rootViewController = ShotPageTabBarController(viewControllers: [SignupViewController()], selectedIndex: 0)
            }
        } else{ // first time
            prefs.setValue("false", forKey: "loggedIn")
            window!.rootViewController = ShotPageTabBarController(viewControllers: [SignupViewController()], selectedIndex: 0)
        }
        window!.makeKeyAndVisible()
        
        return true
    }

    class func getAppDelegate() -> AppDelegate {
        
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        let prefs = UserDefaults.standard
        prefs.setValue(deviceTokenString, forKey: "token")
    }
    
    private func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        
        let alertController = UIAlertController(title: "Message", message:
            "You have received a new image!", preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction(title: "Okay", style: .cancel)
        alertController.addAction(cancelAction)
        self.window!.rootViewController?.present(alertController, animated: true, completion: nil)
        
        let localNotification:UILocalNotification = UILocalNotification()
        localNotification.alertAction = "Shot"
        localNotification.alertBody = "You have received a new image!"
        localNotification.fireDate = NSDate(timeIntervalSinceNow: 0) as Date
        UIApplication.shared.scheduleLocalNotification(localNotification)
    }
}
