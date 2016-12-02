//
//  NSFileManager_.swift
//  Pickery
//
//  Created by Okan Arikan on 8/25/16.
//
//

import Foundation

extension FileManager {

    /// Where we have the cache
    static let cacheURL = FileManager.locateSystemDir(.cachesDirectory)
    
    /// The documents directory
    static let documentsURL = FileManager.locateSystemDir(.documentDirectory)
    
    /// The temporary directory
    static let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())
    
    /// Compute the total size of a directory in bytes
    ///
    /// - parameter folderSize: The URL for the folder. Must be a local file URL
    /// - returns: The total number of bytes here
    func folderSize(folderURL: URL) -> Int64 {
        var totalSize   = Int64(0)
        
        // This better be a path
        let files = self.enumerator(atPath: folderURL.path)
        while let file = files?.nextObject() as? String {
            totalSize += fileSize(url: folderURL.appendingPathComponent(file))
        }
        
        return totalSize
    }
        
    /// Grab the file size
    ///
    /// - parameter url: Must be a file url
    /// - returns: The number of bytes
    func fileSize(url: URL) -> Int64 {
        
        assert(url.isFileURL)
        
        if let attributes = try? self.attributesOfItem(atPath: url.path) {
            return (attributes[FileAttributeKey.size] as? NSNumber)?.int64Value ?? 0
        }
        
        return 0
    }
    
    /// Remove everything in a folder
    ///
    /// Ignores failure
    ///
    /// - parameter at: The directory URL to clear
    func clearFolder(at url: URL) {
        Logger.attempt {
            for file in try subpathsOfDirectory(atPath: url.path) as [String]  {
                try removeItem(at: url.appendingPathComponent(file))
            }
        }
    }
    
    /// Locate a system directory
    ///
    /// - parameter directory: The system directory to locate
    /// - returns: The URL for the directory
    private class func locateSystemDir(_ directory: FileManager.SearchPathDirectory) -> URL {
        
        // Resolve the cache URL
        for dir in NSSearchPathForDirectoriesInDomains(directory, .userDomainMask, true) {
            return URL(fileURLWithPath: dir, isDirectory: true)
        }
        
        // Unable to locate
        return tmpURL
    }
}
