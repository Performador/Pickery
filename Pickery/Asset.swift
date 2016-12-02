//
//  Asset.swift
//  Pickery
//
//  Created by Okan Arikan on 7/25/16.
//
//

import Foundation
import Photos
import ReactiveSwift

/// The type of a resource associated with an asset
enum ResourceType : String {
    case photo
    case video
    case audio
    case alternatePhoto
    case fullSizePhoto
    case fullSizeVideo
    case adjustmentData
    case adjustmentBasePhoto
    case pairedVideo
    case thumbnail
    case fullSizePairedVideo
    case adjustmentBasePairedVideo
    
    /// Is this a video resource?
    ///
    /// We will put a play icon on it if it is
    var isVideo : Bool {
        get {
            switch self {
            case .video:            fallthrough
            case .fullSizeVideo:    fallthrough
            case .pairedVideo:
                return true
            default:
                return false
            }
        }
    }
    
    /// All possible resource types
    static let allValues : [ ResourceType ] = [ .photo,
                                                .video,
                                                .audio,
                                                .alternatePhoto,
                                                .fullSizePhoto,
                                                .fullSizeVideo,
                                                .adjustmentData,
                                                .adjustmentBasePhoto,
                                                .pairedVideo,
                                                .thumbnail,
                                                .fullSizePairedVideo,
                                                .adjustmentBasePairedVideo ]
}

/// Extend the resource type so we can copy it from PHAssetResource
extension ResourceType {
    
    /// Ctor
    ///
    /// - parameter resourceType : Photo library asset source
    init(resourceType: PHAssetResourceType) {
        switch resourceType {
            case .adjustmentBasePhoto:       self = ResourceType.adjustmentBasePhoto
            case .alternatePhoto:            self = ResourceType.alternatePhoto
            case .audio:                     self = ResourceType.audio
            case .fullSizePhoto:             self = ResourceType.fullSizePhoto
            case .fullSizeVideo:             self = ResourceType.fullSizeVideo
            case .pairedVideo:               self = ResourceType.pairedVideo
            case .photo:                     self = ResourceType.photo
            case .video:                     self = ResourceType.video
            case .adjustmentData:            self = ResourceType.adjustmentData
            case .fullSizePairedVideo:       self = ResourceType.fullSizePairedVideo
            case .adjustmentBasePairedVideo: self = ResourceType.adjustmentBasePairedVideo
        }
    }
}

/// This protocol provides a uniform interface to local and remote assets
protocol Asset {

    /// A unique identifier for the asset
    var identifier      :   String { get }
    
    /// Return the pixel size of the asset
    var pixelSize       :   CGSize { get }
    
    /// width / height
    var aspectRatio     :   CGFloat { get }
    
    /// The duration in seconds for video assets
    var durationSeconds :   TimeInterval { get }
    
    /// Where is it?
    var location        :   CLLocation? { get }
    
    /// When is it created
    var dateCreated     :   Date? { get }
        
    /// Is this a live photo
    var isLivePhoto     :   Bool { get }
    
    /// Is this a video?
    var isVideo         :   Bool { get }
    
    /// Request an image for this asset.
    /// - parameter resourceType : The type of the resource to request
    /// - parameter forView: The image view that should hold the result
    /// - returns : a request object which, on-deinit will cancel the request
    func requestImage(for view: AssetImageView) -> AnyObject?
    
    /// Request a player item for this asset
    /// - parameter resourceType : The type of the resource to request
    /// - parameter pixelSize : The pixel size of the asset we are requesting
    /// - parameter completion : The callback to invoke when the player item is available
    func requestPlayerItem(pixelSize: CGSize) -> SignalProducer<AVPlayerItem,NSError>
    
    /// Request a live photo for this asset
    /// - parameter pixelSize : The pixel size of the asset we are requesting
    /// - parameter completion : The callback to invoke when the live photo is available
    func requestLivePhoto(pixelSize: CGSize) -> SignalProducer<PHLivePhoto,NSError>
}

extension Asset {
    var aspectRatio     :   CGFloat { return pixelSize.width / pixelSize.height }
}
