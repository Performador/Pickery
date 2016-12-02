//
//  SignalSource.swift
//  Pickery
//
//  Created by Okan Arikan on 7/22/16.
//
//

import Foundation
import ReactiveSwift
import Result

/// A helper class to facilitate persistent signal sources
class SignalSource<SignalType, ErrType : Error> {
    
    /// We have downloaded a key
    let signalSinkPair  = Signal<SignalType, ErrType>.pipe()
    
    /// Get the signal
    var signal          : Signal<SignalType, ErrType> { return signalSinkPair.0 }
    
    /// Get the observer
    var observer        : Observer<SignalType, ErrType> { return signalSinkPair.1 }
        
    /// We are done sending this
    deinit {
        observer.sendCompleted()
    }
}
