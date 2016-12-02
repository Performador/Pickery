//
//  AssetDetailsViewController.swift
//  Pickery
//
//  Created by Okan Arikan on 9/1/16.
//
//

import Foundation
import Photos
import Eureka

/// Displays details about an asset
class AssetDetailsViewController : FormViewController {
 
    let asset : Asset
    
    /// Ctor
    init(asset: Asset) {
        self.asset = asset
        super.init(nibName: nil, bundle: nil)
        
        title = "Details"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Add the sections related photos asset
    func add(photo: PhotosAsset) {
        
        let resourcesSection = Section("Photos Resources")
        
        /// Add the resource
        for resource in PHAssetResource.assetResources(for: photo.phAsset) {
            
            resourcesSection
                <<< LabelRow() { row in
                    row.title = "\(ResourceType(resourceType: resource.type).rawValue) - \(resource.originalFilename)"
                }
        }
        
        form +++ resourcesSection

        // Got a remote asset?
        if let remoteAsset = photo.remoteAsset {
            add(remote: remoteAsset)
        }
    }
    
    /// Add the sections related to remote assets
    func add(remote: RemoteAsset) {
        
        form +++ Section("Signature")
                <<< LabelRow() { row in
                    row.title = remote.signature
                }
        
        let resources = Section("Remote Resources")
        for resource in remote.resources {
            resources <<< LabelRow() { row in
                row.title = "\(resource.type) " + (resource.pixelWidth > 0 ? " \(resource.pixelWidth)x\(resource.pixelHeight)" : "") + " (\(Formatters.sharedInstance.bytesFormatter.string(fromByteCount: Int64(resource.numBytes))))"
            }
        }
        form +++ resources
    }
    
    /// Create the form
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The main description
        form +++ Section("Asset")
                <<< LabelRow() { row in
                    row.title = "Local identifier: \(asset.identifier.description)"
                } <<< LabelRow() { row in
                    row.title = "Resolution: \(Int(asset.pixelSize.width))x\(Int(asset.pixelSize.height))" + (asset.durationSeconds > 0 ? " - (\(asset.durationSeconds) seconds)" : "")
                }

        // Let's see what we have
        switch asset {
        case let remote as RemoteAsset:
            add(remote: remote)
        case let photo as PhotosAsset:
            add(photo: photo)
        default: break
        }
    }
}
