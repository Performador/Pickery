//
//  CachedRemoteResource.swift
//  Pickery
//
//  Created by Okan Arikan on 7/4/16.
//
//

import Foundation
import RealmSwift

/// The local cached representation for a remote asset
class CachedRemoteResource: CachedModel {
    
    /// The signature of the parent asset that this resurce belongs to
    dynamic var parentSignature     :   String      =   ""
    dynamic var fileName            :   String?
    dynamic var type                :   String      =   ""
    dynamic var mimeType            :   String      =   ""
    dynamic var pixelWidth          =   Int(0)
    dynamic var pixelHeight         =   Int(0)
    dynamic var durationSeconds     =   Double(0)
    dynamic var numBytes            =   Int(0)
    dynamic var placeholder         :   Data?
    
    /// The name of the key we're storing this resource in
    //var key : String { return signature + "_" + fileName }
    
    /// Parse the meta data and create the asset object
    convenience init(parentSignature: String, data: [ String : Any ]) throws {
        try self.init(data: data)
        
        self.parentSignature    =   parentSignature
        self.fileName           =   data[MetaInfoKey.fileName.rawValue] as? String
        self.type               =   try data.metaValue(key: MetaInfoKey.entryType.rawValue)
        self.mimeType           =   try data.metaValue(key: MetaInfoKey.mimeType.rawValue)
        self.numBytes           =   try data.metaValue(key: MetaInfoKey.numBytes.rawValue)
        self.pixelWidth         =   data[MetaInfoKey.pixelWidth.rawValue] as? Int ?? 0
        self.pixelHeight        =   data[MetaInfoKey.pixelHeight.rawValue] as? Int ?? 0
        self.durationSeconds    =   data[MetaInfoKey.durationSeconds.rawValue] as? Double ?? 0
        
        // Do we have a placeholder?
        if let placeholder = data[MetaInfoKey.placeholder.rawValue] as? String {
            self.placeholder    =   Data(base64Encoded: placeholder)
        }
    }
    
    /// The indexed properties
    override class func indexedProperties() -> [String] {
        return super.indexedProperties() + [ "parentSignature" ]
    }
}
