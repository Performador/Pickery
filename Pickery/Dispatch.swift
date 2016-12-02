//
//  Dispatch.swift
//  Pickery
//
//  Created by Okan Arikan on 8/15/16.
//
//

import Foundation

/// Initialize tge main queue
func initMainQueue() {
    DispatchQueue.main.setSpecific(key: DispatchSpecificKey<Bool>(), value: true)
}

/// See if we are currently on the main queue
func isMainQueue() -> Bool {
    return Thread.isMainThread
}

/// Make sure we are on the main queue
func assertMainQueue() {
    assert(isMainQueue(), "Must be on main thread")
}

/// Dispatch a block to the background using the default
/// priority
/// - parameter block: The block to execute in background
func dispatchBackground(block: @escaping () -> Void) {
    DispatchQueue.global().async(execute: block)
}

/// Dispatch a block to the main queue
///
/// - parameter block: The block to execute on the main thread
func dispatchMain(block: @escaping () -> Void) {
    DispatchQueue.main.async(execute: block)
}
