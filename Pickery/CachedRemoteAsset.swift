//
//  CachedAsset.swift
//  Pickery
//
//  Created by Okan Arikan on 6/28/16.
//
//

import Foundation
import RealmSwift
import CoreLocation

/// The realm class we use to represent cached assets
class CachedRemoteAsset : CachedModel {
    dynamic var localIdentifier     :   String?     ///< If this represents a local photos asset, its local identifier is here
    dynamic var dateStateChanged    =   Date()      ///< The last modification timestamp
    dynamic var type : String       =   ""          ///< The asset type
    dynamic var pixelWidth          =   Int(0)      ///< Resolution
    dynamic var pixelHeight         =   Int(0)
    dynamic var durationSeconds     =   Double(0)
    dynamic var dateTaken           :   Date? = nil ///< Date created
    
    /// Location data if any
    dynamic var latitude            =   Double(0)
    dynamic var longitude           =   Double(0)
    dynamic var altitude            =   Double(0)
    dynamic var horizontalAccuracy  =   Double(0)
    dynamic var verticalAccuracy    =   Double(0)
    dynamic var hasLocation         =   false
    
    /// Compute the location object
    var location : CLLocation? {
        return hasLocation ?
                    CLLocation(coordinate:           CLLocationCoordinate2DMake(latitude, longitude),
                               altitude:             altitude,
                               horizontalAccuracy:   horizontalAccuracy,
                               verticalAccuracy:     verticalAccuracy,
                               timestamp:            dateTaken ?? Date())
                : nil
    }
    
    /// Parse the meta data and create the asset object
    convenience init(timeStateChanged:  Double,
                     data:              [ String : AnyObject ]) throws {
        
        try self.init(data: data)
        
        /// Let's see what is the latest modification date
        self.dateStateChanged       =   GlobalConstants.date(from: timeStateChanged)
        
        // Grab the type
        self.type                   =   try data.metaValue(key: MetaInfoKey.entryType.rawValue)
        self.pixelWidth             =   data[MetaInfoKey.pixelWidth.rawValue] as? Int ?? 0
        self.pixelHeight            =   data[MetaInfoKey.pixelHeight.rawValue] as? Int ?? 0
        self.durationSeconds        =   data[MetaInfoKey.durationSeconds.rawValue] as? Double ?? 0
        
        // Do we have a date taken?
        if let dateTaken = data[MetaInfoKey.dateTaken.rawValue] as? String {
            self.dateTaken          =   Formatters.sharedInstance.ISOFormatter.date(from: dateTaken)
        }
        
        // Do we have location data?
        if let location = data[MetaInfoKey.location.rawValue] as? [ String : AnyObject ] {
            self.latitude           =   try location.metaValue(key: MetaInfoKey.latitude.rawValue) as Double
            self.longitude          =   try location.metaValue(key: MetaInfoKey.longitude.rawValue) as Double
            self.altitude           =   try location.metaValue(key: MetaInfoKey.altitude.rawValue) as Double
            self.horizontalAccuracy =   try location.metaValue(key: MetaInfoKey.hAccuracy.rawValue) as Double
            self.verticalAccuracy   =   try location.metaValue(key: MetaInfoKey.vAccuracy.rawValue) as Double
            self.hasLocation        =   true
        }
    }
    
    /// The indexed properties
    override class func indexedProperties() -> [String] {
        return super.indexedProperties() + [ "dateStateChanged" ]
    }
}

