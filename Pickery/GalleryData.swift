//
//  GalleryData.swift
//  Pickery
//
//  Created by Okan Arikan on 8/12/16.
//
//

import Foundation

/// Represents the gallery data
///
/// Instances of this object are emitted by the GalleryManager and are retained by the AssetDataSource
class GalleryData {
    
    /// A collection of asset records
    ///
    /// Each section designates a day
    /// FIXME: Array slices should work but doesn't
    struct Section {
        let day         :   Date                    ///< The date of the day
        //var assets      :   ArraySlice<Asset> ///< The assets in this section
        let assets      :   Array<Asset> ///< The assets in this section
    }
    
    /// An entry for each asset
    let assets : [ Asset ]
    
    /// Where we store the assets into sections
    let sections : [ Section ]
    
    /// The bytes
    let numRemoteOnlyBytes  : Int64
    let numLocalRemoteBytes : Int64
    
    /// The list of assets that have been already uploaded
    var alreadyUploaded : [ PhotosAsset ] { return assets.flatMap { $0 as? PhotosAsset }.filter { $0.remoteAsset != nil } }
    
    /// The list of assets that we never uploaded
    var unUploaded : [ PhotosAsset ] { return assets.flatMap { $0 as? PhotosAsset }.filter { $0.remoteAsset == nil } }
    
    /// Where we keep track of the sizes
    let bytesPerResourceType : [ String : Int64 ]
    
    /// Ctor
    init(remoteAssets: [ RemoteAsset ], photosAssets: [ PhotosAsset ]) {
        
        // Union these two arrays to create a linear set of assets
        assets = GalleryData.createAssets(remoteAssets: remoteAssets, photosAssets: photosAssets)
        
        // Count the bytes in the remote assets
        let bytes               = GalleryData.countBytes(remoteAssets: remoteAssets)
        numRemoteOnlyBytes      = bytes.0
        numLocalRemoteBytes     = bytes.1
        bytesPerResourceType    = bytes.2
        
        // Create the sections from the assets
        sections = GalleryData.createSections(assets: assets)
    }
    
    /// Count the bytes in a set of remote assets
    ///
    /// - parameter remoteAssets: The set of remote assets to sum
    /// - returns: A tuple of statistics
    private class func countBytes(remoteAssets: [ RemoteAsset ]) -> (Int64, Int64, [ String : Int64 ]) {
        var numRemoteOnlyBytes      = Int64(0)
        var numLocalRemoteBytes     = Int64(0)
        var bytesPerResourceType    = [ String : Int64 ]()
        
        // Let's see if there are local assets for these
        for asset in remoteAssets {
            var numBytes = Int64(0)
            
            // Count the bytes
            for resource in asset.resources {
                numBytes += resource.numBytes
                bytesPerResourceType[resource.type] = (bytesPerResourceType[resource.type] ?? 0) + resource.numBytes
            }
            
            if asset.asset.localIdentifier != nil {
                numLocalRemoteBytes += numBytes
            } else {
                numRemoteOnlyBytes += numBytes
            }
        }
        
        return (numRemoteOnlyBytes, numLocalRemoteBytes, bytesPerResourceType)
    }
    
    /// Union the local and remote assets and figure out the overlap
    ///
    /// - parameter remoteAssets: The set of assets we have remotely
    /// - parameter photosAssets: The set of local photos assets
    /// - returns: The set of unique assets
    private class func createAssets(remoteAssets: [ RemoteAsset ], photosAssets: [ PhotosAsset ]) -> [ Asset ] {
        
        /// The local assets
        var locals = [ String : PhotosAsset ]()
        for asset in photosAssets {
            locals[asset.localIdentifier] = asset
        }
        
        // Save the photos
        var assets : [ Asset ] = photosAssets
        
        // Let's see if there are local assets for these
        for asset in remoteAssets {
            
            if let localIdentifier = asset.asset.localIdentifier,
                let local = locals[localIdentifier] {
                local.remoteAsset = asset
            } else {
                assets.append(asset)
            }
        }
        
        // Sort the assets with time
        return assets.sorted { a,b in
            return a.dateCreated?.timeIntervalSince1970 ?? 0 > b.dateCreated?.timeIntervalSince1970 ?? 0
        }
    }
    
    /// Take a set of assets and create sections from them
    ///
    /// - parameter assets: The set of assets we have
    /// - returns: The array of sections
    private class func createSections(assets: [ Asset ]) -> [ Section ] {
        
        // OK, let's create the sections
        var sections        =   [ Section ]()
        var sectionStart    =   Int(0)
        let defaultDate     =   Date()
        for (index,asset) in assets.enumerated() {
            
            
            if Calendar.current.isDate(asset.dateCreated ?? defaultDate, inSameDayAs: assets[sectionStart].dateCreated ?? defaultDate) == false {
                sections.append(Section(day:        assets[sectionStart].dateCreated ?? defaultDate,
                                        assets:     assets[sectionStart..<index].map { return $0 } ))
                sectionStart = index
            }
            
        }
        
        if assets.count > 0 {
            sections.append(Section(day:        assets[sectionStart].dateCreated ?? defaultDate,
                                    assets:     assets[sectionStart..<assets.count].map { return $0 } ))
        }
        
        return sections
    }
    
    /// Get the index path for an asset (brute force)
    func indexPath(for asset: Asset) -> IndexPath? {
        
        for (sectionIndex,section) in sections.enumerated() {
            for (assetIndex,sectionAsset) in section.assets.enumerated() {
                if sectionAsset.identifier == asset.identifier {
                    return IndexPath(row: assetIndex, section: sectionIndex)
                }
            }
        }
        
        return nil
    }
    
    /// Get the index for an asset (brute force)
    func index(for asset: Asset) -> Int? {
        
        for (assetIndex, galleryAsset) in assets.enumerated() {
            if asset.identifier == galleryAsset.identifier {
                return assetIndex
            }
        }
        
        return nil
    }
    
    /// Return the asset at an index path
    func asset(at indexPath: IndexPath) -> Asset? {
        guard indexPath.section < sections.count && indexPath.row < sections[indexPath.section].assets.count else {
            return nil
        }
        
        return sections[indexPath.section].assets[indexPath.row]
    }
    
    /// Return the asset at an index
    func asset(at index: Int) -> Asset? {
        return (index < 0 || index >= assets.count) ? nil : assets[index]
    }
}
