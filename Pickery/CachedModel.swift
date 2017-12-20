//
//  CachedModel.swift
//  Pickery
//
//  Created by Okan Arikan on 7/8/16.
//
//

import Foundation
import RealmSwift

/// The realm class we use to represent cached assets
class CachedModel : Object {
    
    /// Assets and Resources have signatures
    @objc dynamic var signature : String = ""
    
    /// Ctor
    convenience init(data: [ String : Any ]) throws {
        self.init()
        
        // Must have signature
        self.signature = try data.metaValue(key: MetaInfoKey.signature.rawValue)
    }
    
    /// The indexed properties
    override class func indexedProperties() -> [String] {
        return [ ]
    }
    
    /// Da primary key
    override class func primaryKey() -> String? {
        return "signature"
    }
}
