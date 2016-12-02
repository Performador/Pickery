//
//  UploadReceipt.swift
//  Pickery
//
//  Created by Okan Arikan on 7/13/16.
//
//

import Foundation

/// A receipt object that holds the proof of upload
///
/// This is the base class for UploadResourceReceipt and UploadAssetReceipt
class UploadReceipt {
    
    /// The signature that got uploaded
    let signature:  String
    
    /// The meta data associated with the upload
    let data:       [ String : Any ]
    
    /// Ctor
    init(signature: String, data: [ String : Any ]) {
        self.signature  =   signature
        self.data       =   data
    }
}
