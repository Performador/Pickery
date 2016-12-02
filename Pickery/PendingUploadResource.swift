//
//  PendingUploadResource.swift
//  Pickery
//
//  Created by Okan Arikan on 6/24/16.
//
//

import Foundation
import Arcane

/// Possible mime types we understand
enum MimeType : String {
    case jpeg       = "image/jpeg"
    case png        = "image/png"
    case json       = "application/json"
    case mov        = "video/quicktime"
    case unknown    = "application/octet"
}

extension MimeType {
    
    /// Try figuring out the mime type from file extension
    init(fileExtension: String) {
        switch fileExtension.lowercased() {
        case "jpg":    fallthrough
        case "jpeg":   self = .jpeg
        case "png":    self = .png
        case "json":   self = .json
        case "mov":    self = .mov
        default:       self = .unknown
        }
    }
}

/// The keys we use in the meta data dictionary
enum MetaInfoKey : String {
    case mimeType
    case pixelWidth
    case pixelHeight
    case location
    case latitude
    case longitude
    case altitude
    case hAccuracy
    case vAccuracy
    case entryType
    case subType
    case numBytes
    case fileName
    case signature
    case durationSeconds
    case dateTaken
    case dateModified
    case resources
    case placeholder
    case favorite
    case burstIdentifier
    case burstRepresentative
}

/// Encapsulates a temporary file, waiting to be uploaded
/// Each of these corresponds to a resource associated with an asset
/// This class will remove the local tmp file on destructor
class PendingUploadResource : CustomStringConvertible {
    
    /// The local identifier of the asset that this resource belongs to
    let localIdentifier:    String
    
    /// The local file URL
    let localFileURL:       URL
        
    /// The MD5 for the file
    let MD5:                String
    
    /// The signature for the file
    let signature:          String
    
    /// The meta information for this file
    let info:               [ String : Any ]
    
    /// Return the description
    var description:        String { return signature }
    
    /// Ctor
    /// - parameter localIdentifier: The asset local identifier
    /// - parameter fileName: The name of the file we want (will be the same local and remote)
    /// - parameter info: The meta data to record with this file
    init(localIdentifier: String, localFileURL: URL, info: [ String : Any ]) throws {

        // Get the file into a Data
        let fileData            =   try Data(contentsOf: localFileURL)
        
        // Save the fields
        self.localIdentifier    =   localIdentifier
        self.localFileURL       =   localFileURL
        self.MD5                =   Hash.MD5(fileData).base64EncodedString()
        self.signature          =   Hash.SHA256(fileData).base64EncodedString().replacingOccurrences(of: "/", with: "-")
        self.info               =   info + [ MetaInfoKey.signature.rawValue : self.signature,
                                             MetaInfoKey.numBytes.rawValue  : fileData.count ]
    }
    
    /// Dtor
    /// Remove the local file if it exists
    deinit {
        
        Logger.attempt {
            try FileManager.default.removeItem(at: self.localFileURL)
        }
    }
    
}
