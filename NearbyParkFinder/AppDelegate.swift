//
//  AppDelegate.swift
//  NearbyParkFinder
//
//  Created by adam on 12/21/15.
//  Copyright © 2015 Adam Schoonmaker. All rights reserved.
//

import GoogleMaps
import UIKit

private(set) var placesClient: GMSPlacesClient!
let simulateLocation = true

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        initialize()
        return true
    }
    
    /// Prepare the app before launching
    func initialize() {
        initializeGoogleMaps()
        customizeAppearance()
    }
    
    /// Prepare the Google maps SDK before launching
    func initializeGoogleMaps() {
        GMSServices.provideAPIKey(kGMSServiceAPIKey)
        placesClient = GMSPlacesClient()
    }
    
    func customizeAppearance() {
        // Navigation bar
        UINavigationBar.appearance().barTintColor = primaryGreen4
        UINavigationBar.appearance().barStyle = .Black
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: kSignikaSemiboldFontName, size: 17)!]
        
        // Bar button item
        UIBarButtonItem.appearance().tintColor = UIColor.whiteColor()
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: kSignikaLightFontName, size: 17)!], forState: UIControlState.Normal)
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
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

