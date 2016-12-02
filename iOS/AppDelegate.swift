//
//  AppDelegate.swift
//  iOS
//
//  Created by Okan Arikan on 6/13/16.
//
//

import UIKit
import ReactiveSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    /// Da glorious entry point
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
                
        // Initialize the specifics for the main queue
        initMainQueue()
        assertMainQueue()
        
        // Setup the general appearance
        Appearance.setupAppearance()
                    
        // Create the window and the root navigation view controller
        self.window                     =   UIWindow(frame: UIScreen.main.bounds)
        
        // Create the root view controller
        let navigationController        =   NavigationController(rootViewController: HomeViewController())
        
        // If we are able to initialize the backend directly, start from the 
        // grid view controller
        if let initializer = Credentials.sharedInstance.initializer {
            
            // Set the initializer
            RemoteLibrary.sharedInstance.initializeBackend(producer: initializer)
            
            // Go to the grid view controller right away
            navigationController.pushViewController(AssetCollectionViewController(collectionViewLayout: AssetLayout()), animated: false)
        }
        
        // Setup the root window and we're done
        self.window?.rootViewController =   navigationController
        self.window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    /// Handle the background URL session stuff
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        
        // TODO: Pipe this to the backend
        ApplicationState.sharedInstance.backgroundURLHandle.observer.send(value: (application, identifier, completionHandler))
    }
}

