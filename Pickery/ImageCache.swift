//
//  ImageCache.swift
//  Pickery
//
//  Created by Okan Arikan on 8/24/16.
//
//

import Foundation

/// This is where we store the image caches for the assets in memory
///
/// FIXME: We can generalize this to any type of key-value. Good idea?
class ImageCache {
    
    /// Where the cached files will be stored
    let cache = NSCache<NSString,UIImage>()
    
    /// The singleton
    static let sharedInstance = ImageCache()
    
    /// Figure out the image for an asset signature
    ///
    /// - parameter key: The cache key to lookup
    /// - returns: The image if any
    func imageForAsset(key: String) -> UIImage? {
        
        // We better be on main queue
        assertMainQueue()
        
        // Let's see if we have this image in our cache
        return cache.object(forKey: key as NSString)
    }
    
    /// Add an image for a key for safekeeping
    ///
    /// - parameter key: The cache key to save
    /// - parameter image: The image to save
    func addImageForAsset(key: String, image: UIImage) {
        
        // We better be on main queue
        assertMainQueue()
        
        // OK, safe to add
        cache.setObject(image, forKey: key as NSString)
    }    
}
