//
//  Dictionary_.swift
//  Pickery
//
//  Created by Okan Arikan on 12/1/16.
//
//

import Foundation

extension Dictionary {

    /// Convert the dictionary to JSON
    func toJSON() throws -> String? {
        let data = try JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions())
        return String(data: data, encoding: String.Encoding.utf8)
    }
    
    /// Lookup an expected value in the dictionary and throw an exception if it does not exist
    ///
    /// We use this to lookup values we expect in the asset meta data
    ///
    /// - parameter key: The key to lookup
    /// - returns: The value in the meta dictionary
    func metaValue<ValueType>(key: Key) throws -> ValueType {
        
        if let v = self[key] as? ValueType {
            return v
        } else {
            throw PickeryError.internalMissingMetaData
        }
    }
}

/// Helper function for combining two dictionaries
///
/// a += b
func += <K,V>( left: inout [K:V], right: [K:V]) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

/// A helper function for combining two dictionaries
///
/// Not the most efficient implementation
///
/// a = b + c
func + <K,V>(left: Dictionary<K,V>, right: Dictionary<K,V>) -> Dictionary<K,V> {
    var map = Dictionary<K,V>()
    for (k, v) in left {
        map[k] = v
    }
    for (k, v) in right {
        map[k] = v
    }
    return map
}
