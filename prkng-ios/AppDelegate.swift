//
//  AppDelegate.swift
//  prkng-ios
//
//  Created by Cagdas Altinkaya on 26/01/15.
//  Copyright (c) 2015 PRKNG. All rights reserved.
//

import UIKit
import MessageUI
import Fabric
import Crashlytics
import GoogleMaps

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, PRKDialogViewControllerDelegate, MFMailComposeViewControllerDelegate {

    var window: UIWindow?
    var locationManager = CLLocationManager()


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {
        
//        //register for background location usage for updates
        locationManager.delegate = self
        if Settings.iOS8OrLater() {
            locationManager.requestAlwaysAuthorization()
        }
        
        //send analytics on the location manager status
        let currentLocationManagerStatus = CLLocationManager.authorizationStatus()
        if Settings.getLastLocationManagerStatus() != currentLocationManagerStatus {
            AnalyticsOperations.locationPermission(currentLocationManagerStatus, completion: { (completed) -> Void in
                if completed {
                    Settings.setLastLocationManagerStatus(currentLocationManagerStatus)
                }
            })
        }
        locationManager.startUpdatingLocation()
        
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        RMConfiguration.sharedInstance().accessToken = "pk.eyJ1IjoiYXJuYXVkc3B1aGxlciIsImEiOiJSaEctSlVnIn0.R8cfngN9KkHYZx54JQdgJA"
        MBXMapKit.setAccessToken("pk.eyJ1IjoiYXJuYXVkc3B1aGxlciIsImEiOiJSaEctSlVnIn0.R8cfngN9KkHYZx54JQdgJA")
//        MGLAccountManager.setAccessToken("pk.eyJ1IjoiYXJuYXVkc3B1aGxlciIsImEiOiJSaEctSlVnIn0.R8cfngN9KkHYZx54JQdgJA")
        GMSServices.provideAPIKey("AIzaSyAjtDb1VW1rnICr_JMFPmzWi3pMshLusA8")

//        Crashlytics.startWithAPIKey("0a552ed905e273700bb769724c451c706ceb78cb")
        Fabric.with([Crashlytics()])
        
        //google analytics setup...
        // Optional: automatically send uncaught exceptions to Google Analytics.
        GAI.sharedInstance().trackUncaughtExceptions = true
        // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
        GAI.sharedInstance().dispatchInterval = 20;
        // Optional: set Logger to VERBOSE for debug information.
        GAI.sharedInstance().logger.logLevel = GAILogLevel.Error
        // Initialize tracker. Replace with your tracking ID.
        GAI.sharedInstance().trackerWithTrackingId("UA-63856349-1")
        
        //configure cocoa lumberjack for logging
        DDLog.addLogger(DDASLLogger.sharedInstance())
        DDLog.addLogger(DDTTYLogger.sharedInstance())

        let fileLogger = DDFileLogger()
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.addLogger(fileLogger)
        let filePath = fileLogger.currentLogFileInfo().filePath
        DDLoggerWrapper.logInfo(String(format: "log file at: %@", filePath))
        Settings.setLogFilePath(filePath)

        configureGlobals()
        loadInitialViewController()
        
        //configure IQKeyboardManager
        IQKeyboardManager.sharedManager().considerToolbarPreviousNextInViewClass(PRKInputForm)
        IQKeyboardManager.sharedManager().enableAutoToolbar = false
//        IQKeyboardManager.sharedManager().disableToolbarInViewControllerClass(FilterViewController)
        IQKeyboardManager.sharedManager().shouldShowTextFieldPlaceholder = false

        // Override point for customization after application launch.
        
        //
        //notification set up
        //
        if Settings.iOS8OrLater() {
            let yesAction = UIMutableUserNotificationAction()
            yesAction.identifier = "yes"
            yesAction.title = "yes".localizedString
            yesAction.activationMode = .Background
            yesAction.authenticationRequired = false
            
            let noAction = UIMutableUserNotificationAction()
            noAction.identifier = "no"
            noAction.title = "no".localizedString
            noAction.activationMode = .Background
            noAction.authenticationRequired = false
            
            let category = UIMutableUserNotificationCategory()
            category.identifier = "prkng_check_out_monitor"
            category.setActions([yesAction, noAction], forContext: UIUserNotificationActionContext.Default)
            
            if(UIApplication.instancesRespondToSelector(Selector("registerUserNotificationSettings:"))){
                application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Sound | .Alert | .Badge, categories: NSSet(object: category) as Set<NSObject>))
            }
        }

        if Settings.iOS8OrLater() {
            application.registerForRemoteNotifications()
            //the types are registered above with registerUserNotificationSettings
        } else {
            application.registerForRemoteNotificationTypes(.Badge | .Sound | .Badge | .Alert)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardDidShowNotification, object: nil)
        
        //removes lag when opening the keyboard for the first time on certain devices
        let lagFreeField = UITextField()
        self.window?.addSubview(lagFreeField)
        lagFreeField.becomeFirstResponder()
        lagFreeField.resignFirstResponder()
        lagFreeField.removeFromSuperview()
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
        
        if let tabController = window?.rootViewController as? TabController {
            tabController.updateTabBar()
            
            if Settings.shouldPromptUserToRateApp() {
                let dialogVC = PRKDialogViewController(titleIconName: "icon_review", headerImageName: "review_header", titleText: "review_title_text".localizedString, subTitleText: "review_message_text".localizedString, messageText: "", buttonLabels: ["review_rate_us".localizedString, "review_feedback".localizedString, "dismiss".localizedString])
                dialogVC.delegate = self
                dialogVC.showOnViewController(tabController)
            }

        }
        
        if let data = NSUserDefaults.standardUserDefaults().objectForKey("prkng_check_out_monitor_notification") as? NSData {
            let alert = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! UILocalNotification
            UIApplication.sharedApplication().presentLocalNotificationNow(alert)
        }

    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        
        if (url.scheme?.lowercaseString == "fb1043720578978201") {
            return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
        } else  {
            return GPPURLHandler.handleURL(url, sourceApplication: sourceApplication, annotation: annotation)
        }        
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        var characterSet: NSCharacterSet = NSCharacterSet( charactersInString: "<>" )
        
        var deviceTokenString: String = ( deviceToken.description as NSString )
            .stringByTrimmingCharactersInSet( characterSet )
            .stringByReplacingOccurrencesOfString( " ", withString: "" ) as String
        
        DDLoggerWrapper.logInfo(String(format: "Did Register for Remote Notifications with Device Token (%@), stringified: %@", deviceToken, deviceTokenString))
        
        UserOperations.hello(deviceTokenString) { (completed) -> Void in
        }

    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        DDLoggerWrapper.logError(String(format: "Did Fail to Register for Remote Notifications.\n Error: %@, %@", error, error.localizedDescription))
        UserOperations.hello(nil) { (completed) -> Void in
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        DDLoggerWrapper.logInfo(String(format: "Received a remote notification."))
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        
        let identifier = notification.userInfo != nil ? (notification.userInfo as! [NSObject:String])["identifier"]! : ""
        
        if identifier == "regular_app_notification" {
            let alert = UIAlertView()
            alert.message = notification.alertBody
            alert.addButtonWithTitle("OK")
            alert.show()
            Settings.cancelNotification()
        } else if identifier == "prkng_check_out_monitor" {

            //present the custom dialog
            let spotName = Settings.checkedInSpot()?.name ?? ""
            
            let dialogVC = PRKDialogViewController(titleIconName: "icon_howto_checkin", headerImageName: "checkout_question_header", titleText: "on_the_go".localizedString, subTitleText: "left_this_spot_question".localizedString, messageText: "\"" + spotName + "\"")

            if let tabController = window?.rootViewController as? TabController {
                dialogVC.showOnViewController(tabController)
            }
            
        }
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {

        let notificationIdentifier = notification.userInfo != nil ? (notification.userInfo as! [NSObject:String])["identifier"]! : ""

        if notificationIdentifier == "prkng_check_out_monitor" {

            application.cancelLocalNotification(notification)
            let answeredYes = identifier == "yes" ? true : false
            geofencingNotificationResponse(answeredYes)
        }
        
        completionHandler()
    }

    func keyboardWasShown(notification: NSNotification) {
        
        let keyboardSize = (notification.userInfo![UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue().size
        NSUserDefaults.standardUserDefaults().setValue(keyboardSize.height, forKey: "last_keyboard_height")
    }
    
    
    // MARK: Helper

    func configureGlobals() {
        
        let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        Settings.setLastAppVersionString(version)

        Settings.setCachedLotDataFresh(false)
        LotOperations.sharedInstance.findLots(Settings.selectedCityPoint(), radius: 1.0) { (lots, underMaintenance, outsideServiceArea, error) -> Void in }
        
        GiFHUD.setGif("loader.gif")

        SVProgressHUD.setRingThickness(4)
        SVProgressHUD.setCornerRadius(0)
        SVProgressHUD.setBackgroundColor(UIColor.clearColor())
        SVProgressHUD.setForegroundColor(Styles.Colors.red2)
        SVProgressHUD.setDefaultStyle(.Custom)
    }

    func loadInitialViewController() {

        if (Settings.firstUse() || AuthUtility.getUser() == nil || AuthUtility.loginType() == nil) {
            AuthUtility.saveAuthToken(nil)
            AuthUtility.saveUser(nil)
            window!.rootViewController = FirstUseViewController()
        } else {
            window!.rootViewController = TabController()
            Settings.incrementAppLaunches()
        }
        
        window!.makeKeyAndVisible()
    }
    
    // MARK: CLLocationManagerDelegate methods

//    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
//        
//        //test this instead of region updates...
//        for region in self.locationManager.monitoredRegions as! Set<CLCircularRegion> {
//            for location in locations as! [CLLocation] {
//                if region.identifier.rangeOfString("prkng_check_out_monitor") != nil
//                && region.containsCoordinate(location.coordinate) {
//                    //We've entered one of our regions! Handle it!
//                    let date = Settings.geofenceLastSetOnInterval()
//                    let timeInterval = location.timestamp.timeIntervalSinceReferenceDate
////                    NSLog("%d",timeInterval)
//                    if ((date - timeInterval) / 60) > 5 {
//                        handleRegionEntered(location.coordinate)
//                    }
//                }
//            }
//
//        }
//        
//        
//    }
    
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        handleRegionEntered((region as! CLCircularRegion).center)
//        self.locationManager.startUpdatingLocation()
    }

    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        handleRegionExited((region as! CLCircularRegion).center)
//        self.locationManager.stopUpdatingLocation()
    }
    
    //MARK: Notification handling
    
    //this is what we consider to be an estimated checkout
    //take all the monitored regions and turn them into checkout regions
    func handleRegionEntered(center: CLLocationCoordinate2D) {
        
        //stop monitoring regions, turn the identifiers into "prkng_check_out_monitor_entered_region"
        for monitoredRegion in self.locationManager.monitoredRegions as! Set<CLCircularRegion> {
            if monitoredRegion.identifier.rangeOfString("prkng_check_out_monitor") != nil {
                self.locationManager.stopMonitoringForRegion(monitoredRegion)
                let newMonitoredRegion = CLCircularRegion(center: monitoredRegion.center, radius: monitoredRegion.radius, identifier: "prkng_check_out_monitor_entered_region")
                self.locationManager.startMonitoringForRegion(newMonitoredRegion)
            }
        }
        
        //analytics
        AnalyticsOperations.sharedInstance.geofencingEvent(center, entering: true) { (completed) -> Void in
        }

    }

    //this is what we consider to be an estimated checkout
    //if we are leaving AFTER having entered, then we execute! 
    //otherwise we do nothing and simply wait for the region to be entered
    func handleRegionExited(center: CLLocationCoordinate2D) {
        
        //see if there are regions that the user exited after entering
        var found = false
        for monitoredRegion in self.locationManager.monitoredRegions as! Set<CLCircularRegion> {
            if monitoredRegion.identifier.rangeOfString("prkng_check_out_monitor_entered_region") != nil
                && monitoredRegion.center.latitude == center.latitude
                && monitoredRegion.center.longitude == center.longitude {
                    found = true
            }
        }
        if !found {
            return
        }

        //stop monitoring ALL regions
        for monitoredRegion in self.locationManager.monitoredRegions as! Set<CLCircularRegion> {
            if monitoredRegion.identifier.rangeOfString("prkng_check_out_monitor") != nil {
                self.locationManager.stopMonitoringForRegion(monitoredRegion)
            }
        }
        
        let spotName = Settings.checkedInSpot()?.name ?? ""
        
        //next create the alert
        let alert = UILocalNotification()
        alert.userInfo = ["identifier" : "prkng_check_out_monitor"]
        alert.alertTitle = "on_the_go".localizedString
        alert.alertBody = String(format: "left_spot_question".localizedString, spotName)
        alert.soundName = UILocalNotificationDefaultSoundName
        if Settings.iOS8OrLater() {
            alert.category = "prkng_check_out_monitor"
        }
        UIApplication.sharedApplication().presentLocalNotificationNow(alert)
        
        let data = NSKeyedArchiver.archivedDataWithRootObject(alert)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: "prkng_check_out_monitor_notification")
        
        //analytics
        AnalyticsOperations.sharedInstance.geofencingEvent(center, entering: false) { (completed) -> Void in
        }
        
    }

    func geofencingNotificationResponse(answeredYes: Bool) {
        
        NSUserDefaults.standardUserDefaults().removeObjectForKey("prkng_check_out_monitor_notification")
        Settings.cancelNotification()
        
        if answeredYes {
            
            let spotIdentifier = Settings.checkedInSpot()?.identifier ?? ""
            SpotOperations.checkout({ (completed) -> Void in
                Settings.checkOut()

                if let tabController = self.window?.rootViewController as? TabController {
                    tabController.updateTabBar()
                }

            })
            //analytics
            AnalyticsOperations.sharedInstance.geofencingEventUserResponse(true, completion: { (completed) -> Void in })
            
        } else {
            
            if let tabController = self.window?.rootViewController as? TabController {
                tabController.updateTabBar()
            }

            //analytics
            AnalyticsOperations.sharedInstance.geofencingEventUserResponse(false, completion: { (completed) -> Void in })

        }
        
    }
    
    //MARK: PRKDialogViewControllerDelegate methods

    func listButtonTapped(index: Int) {

        if index == 0 {
            //rate it now!
            UIApplication.sharedApplication().openURL(NSURL(string: "itms-apps://itunes.apple.com/app/id999834216")!)
        } else if index == 1 {
            //send feedback?
            var mailVC = MFMailComposeViewController()
            mailVC.mailComposeDelegate = self
            mailVC.setSubject("feedback".localizedString)
            mailVC.setToRecipients(["hello@prk.ng"])
            window?.rootViewController?.presentViewController(mailVC, animated: true, completion: nil)
        }
        
    }
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }

}

