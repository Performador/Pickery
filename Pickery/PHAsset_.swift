//
//  PHAsset_.swift
//  Pickery
//
//  Created by Okan Arikan on 11/30/16.
//
//

import Photos
import ReactiveSwift
import MobileCoreServices

extension PHAsset {
    
    /// Da constants
    struct Constants {
        
        /// The compression quality we use for thumbnails
        static let kJPEGCompressionQuality = CGFloat(0)
    }
    
    /// This is where we will store the intermediate files waiting to get uploaded
    private static var stagingURL = FileManager.tmpURL
    
    /// The asset meta data that will be saved on DynamoDB
    var metaData : [ String : Any ] {
        
        // The dict that will store our data
        var assetInfo = [ String : Any]()
        
        // Is this a favorite?
        if isFavorite {
            assetInfo[MetaInfoKey.favorite.rawValue] = true
        }
        
        // Set the media type
        switch mediaType {
        case .audio:    assetInfo[MetaInfoKey.entryType.rawValue] = "Audio"
        case .image:    assetInfo[MetaInfoKey.entryType.rawValue] = "Image"
        case .video:    assetInfo[MetaInfoKey.entryType.rawValue] = "Video"
        case .unknown:  assetInfo[MetaInfoKey.entryType.rawValue] = "Unknown"
        }
        
        // Set the sub type
        let subTypes = [    (PHAssetMediaSubtype.photoPanorama,     "PhotoPanorama"),
                            (PHAssetMediaSubtype.photoHDR,          "PhotoHDR"),
                            (PHAssetMediaSubtype.photoScreenshot,   "PhotoScreenshot"),
                            (PHAssetMediaSubtype.photoLive,         "PhotoLive"),
                            (PHAssetMediaSubtype.videoStreamed,     "VideoStreamed"),
                            (PHAssetMediaSubtype.videoHighFrameRate,"VideoHighFrameRate"),
                            (PHAssetMediaSubtype.videoTimelapse,    "VideoTimelapse"),
                        ]
        
        // Why is this an array?
        assetInfo[MetaInfoKey.subType.rawValue] = subTypes
            .filter { return mediaSubtypes.contains($0.0) }
            .map { return $0.1 }
        
        
        // Got size?
        if pixelWidth > 0 && pixelHeight > 0 {
            assetInfo[MetaInfoKey.pixelWidth.rawValue]  = Int(pixelWidth)
            assetInfo[MetaInfoKey.pixelHeight.rawValue] = Int(pixelHeight)
        }
        
        // Got duration?
        if duration > 0 {
            assetInfo[MetaInfoKey.durationSeconds.rawValue]  = Double(duration)
        }
        
        // Got a date?
        if let dateTaken = creationDate {
            assetInfo[MetaInfoKey.dateTaken.rawValue] = Formatters.sharedInstance.ISOFormatter.string(from: dateTaken) as String
        }
        
        if let dateModified = modificationDate {
            assetInfo[MetaInfoKey.dateModified.rawValue] = Formatters.sharedInstance.ISOFormatter.string(from: dateModified) as String
        }
        
        if let burstIdentifier = burstIdentifier {
            assetInfo[MetaInfoKey.burstIdentifier.rawValue] = burstIdentifier
        }
        
        if representsBurst {
            assetInfo[MetaInfoKey.burstRepresentative.rawValue] = true
        }
        
        // Got a location?
        if let location = location {
            
            // Set the location data
            assetInfo[MetaInfoKey.location.rawValue] = [
                MetaInfoKey.latitude.rawValue   :   location.coordinate.latitude,
                MetaInfoKey.longitude.rawValue  :   location.coordinate.longitude,
                MetaInfoKey.altitude.rawValue   :   location.altitude,
                MetaInfoKey.hAccuracy.rawValue  :   location.horizontalAccuracy,
                MetaInfoKey.vAccuracy.rawValue  :   location.verticalAccuracy
            ]
        }
        
        return assetInfo
    }
    
    /// Creates a new file name we can use to save staging data
    ///
    /// - returns: A file URL. It does not exist yet.
    private func createStagingFileURL() -> URL {
        return PHAsset.stagingURL.appendingPathComponent(UUID().uuidString)
    }
    
    /// We use this function to create a single frame snapshot for a video to display in gallery
    ///
    /// - parameter videoSize: The pixel size of the video
    /// - parameter videoURL: The local file URL for the video
    /// - parameter toImageURL: The file URL to create the snapshot to
    /// - parameter sink: The sink to send the resulting file to
    private func createSnapshot(videoSize: CGSize, videoURL: URL, sink: Signal<PendingUploadResource, NSError>.Observer) {
        let avAsset         = AVURLAsset(url: videoURL, options: nil)
        let imageGenerator  = AVAssetImageGenerator(asset: avAsset)
        
        // Configure the image generator
        imageGenerator.appliesPreferredTrackTransform   =   true
        imageGenerator.maximumSize                      =   videoSize
        
        // Let's see if we can generate and write an image file
        do {
            
            // Where we want to save the image data
            let fileURL = createStagingFileURL()
            
            // Let's see if we can save the image
            try UIImageJPEGRepresentation(UIImage(cgImage: try imageGenerator.copyCGImage(at: kCMTimeZero, actualTime: nil)), Constants.kJPEGCompressionQuality)?
                .write(to: fileURL, options: NSData.WritingOptions())
            
            // Generate thumbnails for this image
            createThumbnails(imageSize: videoSize, imageURL: fileURL, sink: sink)
        } catch let error {
            sink.send(error: error as NSError)
        }
    }
    
    /// Create a thumbnail image at a particular height
    ///
    /// - parameter imageSize: The original image size
    /// - parameter targetHeight: The pixel height we want
    /// - parameter imageSource: The image source to create thumbnails for
    /// - parameter sink: The sink to send the generated file to
    private func createThumbnail(imageSize: CGSize, targetHeight: CGFloat, imageSource: CGImageSource, sink: Signal<PendingUploadResource, NSError>.Observer) {
        let aspectRatio = Double(imageSize.width) / Double(imageSize.height)
        
        // The size we want
        let size = CGSize(width: CGFloat(Int(aspectRatio * Double(targetHeight))), height: targetHeight)
        
        // The options
        let options: [NSString: NSObject] = [
            kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height) as NSValue,
            kCGImageSourceCreateThumbnailFromImageAlways: true as NSValue,
            kCGImageSourceCreateThumbnailWithTransform: true as NSValue
        ]
        
        // Create a JPEG thumbnail
        let targetURL = createStagingFileURL()
        if let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary?),
            let destination = CGImageDestinationCreateWithURL(targetURL as CFURL, kUTTypeJPEG, 1, nil) {
            CGImageDestinationAddImage(destination, scaledImage, nil)
            
            // Able to save the image?
            if CGImageDestinationFinalize(destination) {
                
                // Form the dict that holds data
                let thumbInfo : [ String : Any ] = [
                    MetaInfoKey.mimeType.rawValue:      MimeType.jpeg.rawValue,
                    MetaInfoKey.entryType.rawValue:     ResourceType.thumbnail.rawValue,
                    MetaInfoKey.pixelWidth.rawValue:    Int(size.width),
                    MetaInfoKey.pixelHeight.rawValue:   Int(size.height)
                ]
                
                do {
                    sink.send(value: try PendingUploadResource(localIdentifier:    localIdentifier,
                                                               localFileURL:       targetURL,
                                                               info:               thumbInfo))
                } catch let error {
                    sink.send(error: error as NSError)
                }
            } else {
                sink.send(error: PickeryError.internalThumbnailError as NSError)
            }
        } else {
            sink.send(error: PickeryError.internalThumbnailError as NSError)
        }
    }
    
    /// Create thumbnails for an image file and send each thumbnail into a sink
    ///
    /// - parameter imageSize: The size of the image
    /// - parameter imageURL: Where the image is on disk
    /// - parameter sink: Where the resulting files should go
    private func createThumbnails(imageSize: CGSize, imageURL: URL, sink: Signal<PendingUploadResource, NSError>.Observer) {
        assert(imageSize.width > 0)
        assert(imageSize.height > 0)
        assert(imageURL.isFileURL)
        assert(imageURL.exists)
        
        // Able to load the image?
        if let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil) {
            var height = GlobalConstants.kMinThumbHeight
            
            // While we have height
            while height < Int(imageSize.height) {
                createThumbnail(imageSize: imageSize, targetHeight: CGFloat(height), imageSource: imageSource, sink: sink)
                
                // Double the height
                height *= 2
            }
            
            // Create a placeholder image
            createThumbnail(imageSize: imageSize, targetHeight: CGFloat(GlobalConstants.kPlaceholderHeight), imageSource: imageSource, sink: sink)
        } else {
            sink.send(error: PickeryError.internalThumbnailError as NSError)
        }
    }
    
    /// Create thumbnails for an image file and send the resulting files to a sink
    ///
    /// - parameter resource: The photos library resource to create the thumbnails for
    /// - parameter fileURL: Where the resource is locally
    /// - parameter sink: Where the resulting files should go
    private func sendResource(resource: PHAssetResource, fileURL: URL, sink: Signal<PendingUploadResource, NSError>.Observer) {
        assert(fileURL.isFileURL)
        assert(fileURL.exists)
        
        // Figure out the mime type
        var mimeType = UTTypeCopyPreferredTagWithClass(resource.uniformTypeIdentifier as CFString, kUTTagClassMIMEType)?.takeRetainedValue() as String?
        
        // Guess the mime type from the extension
        if mimeType == nil {
            mimeType = MimeType(fileExtension: fileURL.pathExtension).rawValue
        }
        
        // Form the resource info dict
        let resourceInfo    : [ String: Any ] = [
            MetaInfoKey.entryType.rawValue:         ResourceType(resourceType: resource.type).rawValue,
            MetaInfoKey.mimeType.rawValue:          mimeType ?? MimeType.unknown.rawValue,
            MetaInfoKey.fileName.rawValue:          resource.originalFilename
        ]
        
        do {
            // Create the resource to upload
            let pendingFile = try PendingUploadResource(localIdentifier:    localIdentifier,
                                                        localFileURL:       fileURL,
                                                        info:               resourceInfo)
            
            // Send the original resource
            sink.send(value: pendingFile)
        } catch let error {
            sink.send(error: error as NSError)
        }
    }
    
    /// Enumerate the resources for the asset
    var resources : SignalProducer<PHAssetResource,NSError> {
        return SignalProducer<PHAssetResource,NSError> { sink, disposible in
            
            // For each associated resource
            for resource in PHAssetResource.assetResources(for: self) {
                sink.send(value: resource)
            }
            
            sink.sendCompleted()
        }
    }
    
    /// Create the files to upload for a photos resource
    ///
    /// A single photo resource might generate multiple resources in our terminology
    ///
    /// For example, if the resource is a photo, we will create multiple thumbnails each
    /// of which will be a resource
    ///
    /// - parameter resource: The resource for which we want to create the upload resources
    /// - returns: The producer for the files to upload
    private func uploadResource(for resource: PHAssetResource) -> SignalProducer<PendingUploadResource,NSError> {
        
        return SignalProducer<PendingUploadResource,NSError> { sink, disposible in
            let tmpURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
            
            // Create a random file name to save to
            if let fileURL = tmpURL.appendingPathComponent(ProcessInfo().globallyUniqueString + "_" + resource.originalFilename) {
                
                // Configure the resource access options
                let options = PHAssetResourceRequestOptions()
                options.isNetworkAccessAllowed    =   true
                
                // Request the data object
                PHAssetResourceManager.default().writeData(for: resource, toFile: fileURL, options: options, completionHandler: { (error: Swift.Error?) in
                    assert(!isMainQueue())
                    
                    // Got error?
                    if let error = error {
                        sink.send(error: error as NSError)
                    } else {
                        assert(fileURL.exists)
                        
                        // Let's see if we need to compute thumbnails
                        switch resource.type {
                        case .photo:                        fallthrough
                        case .fullSizePhoto:
                            
                            // Create the thumbnails and send them over
                            self.createThumbnails(imageSize: CGSize(width: CGFloat(self.pixelWidth), height: CGFloat(self.pixelHeight)), imageURL: fileURL, sink: sink)
                            
                        case .video:                        fallthrough
                        case .fullSizeVideo:                fallthrough
                        case .pairedVideo:
                            
                            // First snapshot to an image file
                            self.createSnapshot(videoSize: CGSize(width: CGFloat(self.pixelWidth),height: CGFloat(self.pixelHeight)), videoURL: fileURL, sink: sink)
                            
                        case .audio:                        fallthrough
                        case .alternatePhoto:               fallthrough
                        case .fullSizeVideo:                fallthrough
                        case .adjustmentData:               fallthrough
                        case .adjustmentBasePhoto:          fallthrough
                        case .fullSizePairedVideo:          fallthrough
                        case .adjustmentBasePairedVideo:
                            break
                        }
                        
                        // Send the actual resource
                        self.sendResource(resource: resource, fileURL: fileURL, sink: sink)
                        
                        // Done
                        sink.sendCompleted()
                    }
                })
            } else {
                sink.send(error: PickeryError.internalUnableToCreate as NSError)
            }
        }
    }
    
    
    /// Package a photo library asset into resources to upload
    var uploadResources : SignalProducer<PendingUploadResource,NSError> {
        return resources.flatMap(.merge) { resource in
            return self.uploadResource(for: resource)
        }
    }
}
