//
//  SignalProducerTests.swift
//  Pickery
//
//  Created by Okan Arikan on 7/28/16.
//
//

import ReactiveSwift
import XCTest
@testable import iOS

class SignalProducerTests: XCTestCase {
    
    /// This will test the parallel map extension
    func testParallelMap() {
        
        // We will swuare these
        let values : [ Int ] = [ 1,2,3 ]
        
        // Parallel map (signal producer version)
        SignalProducer<Int, Error>(values: values)
            .parallelFlatMap { (value: Int) -> SignalProducer<Int, Error> in
                return SignalProducer<Int, Error> { sink, disposible in
                    sink.sendNext(value * value)
                    sink.sendCompleted()
                }
            }.collect()
            .startWithNext { squaredValues in
                XCTAssert(squaredValues.count == 3)
                for v in values {
                    XCTAssert(squaredValues.contains(v * v))
                }
            }
        
        // Parallel map (direct version)
        SignalProducer<Int, Error>(values: values)
            .parallelFlatMap { (value: Int) -> Int in
                return value * value
            }.collect()
            .startWithNext { squaredValues in
                XCTAssert(squaredValues.count == 3)
                for v in values {
                    XCTAssert(squaredValues.contains(v * v))
                }
        }
        
    }
}
