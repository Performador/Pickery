//
//  File.swift
//  Pickery
//
//  Created by Okan Arikan on 11/11/16.
//
//

import Foundation

extension URL {
    
    // For a fileURL, check to see if it exists
    var exists : Bool {
        assert(isFileURL)
        return (try? checkResourceIsReachable()) ?? false
    }
}
