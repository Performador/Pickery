//
//  Errors.swift
//  Pickery
//
//  Created by Okan Arikan on 6/24/16.
//
//

import Foundation

/// The Pickery errors
enum PickeryError: Error, CustomStringConvertible, CustomNSError {
    
    /// Da constants
    struct Constants {
        static let kErrorDomain = "com.pickery.error"
    }
    
    /// Various error types
    case internalUnableToSaveMetaData
    case internalUnableToCreate
    case internalFoundEmptyFile
    case internalMissingMetaData
    case internalAssetNotFound
    case internalThumbnailError
    case internalNoResourcesForAsset
    case alreadyUploaded(signature: String)
    case backendNotReady
    case userCancelled
    
    /// The domain of the error.
    static var errorDomain: String { return Constants.kErrorDomain }
    
    
    /// The error code within the given domain.
    var errorCode: Int { return 0 }
    
    /// The user-info dictionary.
    var errorUserInfo: [String : Any] {
        switch self {
        case .alreadyUploaded(let signature):
            return [ "signature": signature]
        default:
            return [ "description": description]
        }
    }
    
    /// Figure out the description
    var description: String {
        switch self {
        case .internalUnableToSaveMetaData:
            return "I was unable to save the meta data"
        case .internalUnableToCreate:
            return "I was unable to create a local file"
        case .internalFoundEmptyFile:
            return "Hmm, a resource seems empty"
        case .internalMissingMetaData:
            return "The asset meta data is missing expected attributes"
        case .internalAssetNotFound:
            return "I could not find the asset in Realm"
        case .internalThumbnailError:
            return "I could not create thumbnails for an asset resource"
        case .internalNoResourcesForAsset:
            return "The asset does not contain any rsources"
        case .alreadyUploaded:
            return "Asset was already uploaded"
        case .backendNotReady:
            return "The connection to the backend is not ready yet"
        case .userCancelled:
            return "Cancelled"
        }
    }
    
    /// Da localized description
    var localizedDescription: String { return description }
}
