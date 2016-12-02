//
//  ApplicationState.swift
//  Pickery
//
//  Created by Okan Arikan on 7/29/16.
//
//

import Foundation
import ReactiveSwift
import Result

typealias CompletionHandler = () -> Void

/// Keeps track of the application state
class ApplicationState {
    
    /// Are we running in background?
    let runningInBackground     =   MutableProperty<Bool>(false)
    
    /// Are we running in foreground?
    let runninInForeground      =   MutableProperty<Bool>(false)
    
    /// We fire this when we wake up from background
    let backgroundURLHandle     =   SignalSource<(UIApplication, String, CompletionHandler), NoError>()
        
    /// Some global variables for the application state
    /// FIXME: Not all of these are application state variables (isRelease, isDebug etc.)
#if (arch(i386) || arch(x86_64)) && (os(iOS) || os(watchOS) || os(tvOS))
    public static let isSimulator:  Bool =  true
#else
    public static let isSimulator:  Bool =  false
#endif
    
#if RELEASE
    public static let isRelease:    Bool = true
#else
    public static let isRelease:    Bool = false
#endif
    
#if PRERELEASE
    public static let isPreRelease: Bool = true
#else
    public static let isPreRelease: Bool = false
#endif
    
#if DEBUG
    public static let isDebug:      Bool = true
#else
    public static let isDebug:      Bool = false
#endif
   
    public static var isPad:        Bool { return UIDevice.current.userInterfaceIdiom == .pad }
    public static var isPhone:      Bool { return UIDevice.current.userInterfaceIdiom == .phone }
    
    /// The singleton stuff
    static let sharedInstance = ApplicationState()
}
