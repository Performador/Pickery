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
    var signature           :   String  =   ""
    var metaData            :   String?
    var timeStateChanged    =   NSNumber(value: 0)
    
    class func dynamoDBTableName() -> String {
        return Amazon.Constants.kPrefix
    }
    
    class func hashKeyAttribute() -> String {
        return "signature"
    }
}
