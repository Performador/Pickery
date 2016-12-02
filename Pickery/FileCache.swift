//
//  RemoteFileCache.swift
//  Pickery
//
//  Created by Okan Arikan on 7/18/16.
//
//

import Foundation
import ReactiveSwift

/// Caches remote stuff locally
class FileCache {
    
    /// Constants
    struct Constants {
        static let kFileCacheDirectory = "FileCache"
    }
    
    /// Where the cached files will be stored
    let cacheURL        = FileManager.cacheURL.appendingPathComponent(Constants.kFileCacheDirectory)
    
    /// We emit this when the cache is cleared
    let cacheCleared    = SignalSource<(),NSError>()
    
    /// Ctor
    init() {
        
        // Make sure the directory is created
        Logger.attempt {
            try FileManager.default.createDirectory(at: cacheURL, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    /// Make a local file URL for a particular key
    ///
    /// - parameter key: The key in the cache
    func urlForKey(key: String) -> URL {
        return cacheURL.appendingPathComponent(key)
    }
    
    /// Clear all cache files
    func clear() {
        let fileManager = FileManager.default
        let files = fileManager.enumerator(atPath: cacheURL.path)
        while let file = files?.nextObject() as? String {
            Logger.attempt {
                try fileManager.removeItem(at: cacheURL.appendingPathComponent(file))
            }
        }
        
        // We are cleared
        cacheCleared.observer.send(value: ())
    }
    
    /// Compute the byte size of the cache
    ///
    /// - returns: The byte size of the cache
    func byteSize() -> Int64 {
        return FileManager.default.folderSize(folderURL: cacheURL)
    }
}
