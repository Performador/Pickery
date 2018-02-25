//
//  AmazonModel.swift
//  Pickery
//
//  Created by Okan Arikan on 7/8/16.
//
//

import Foundation
import AWSDynamoDB

/// Represents an asset
class AmazonModel : AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    @objc var signature           :   String  =   ""
    @objc var metaData            :   String?
    @objc var timeStateChanged    =   NSNumber(value: 0)
    
    class func dynamoDBTableName() -> String {
        return Amazon.Constants.kPrefix
    }
    
    class func hashKeyAttribute() -> String {
        return "signature"
    }
}
