//
//  NSError_.swift
//  Pickery
//
//  Created by Okan Arikan on 11/21/16.
//
//

import Foundation

extension NSError {
    
    /// Is this an error we should retry
    var shouldRetry :   Bool {
        if domain == AWSDynamoDBErrorDomain && code == AWSDynamoDBErrorType.provisionedThroughputExceeded.rawValue {
            return true
        } else {
            return false
        }
    }

    /// What to display for this error
    var displayString: String {
        
        // Is this an AWS error?
        switch domain {
            
        case AWSS3TransferUtilityErrorDomain:
            switch code {
            case AWSS3TransferUtilityErrorType.unknown.rawValue:
                return "AWS Transfer Utility: unknown (Hmm, not sure what this means)"
            case AWSS3TransferUtilityErrorType.redirection.rawValue:
                return "AWS Transfer Utility: redirection (Seems like wrong region was selected)"
            case AWSS3TransferUtilityErrorType.clientError.rawValue:
                return "AWS Transfer Utility: clientError (Hmm, this looks like a bug. Please leave a bug report)"
            case AWSS3TransferUtilityErrorType.serverError.rawValue:
                return "AWS Transfer Utility: serverError (There seems to be a problem with the S3)"
            default:
                break
            }
            
        // AWS transfer manager problem?
        case AWSS3TransferManagerErrorDomain:
            switch code {
            case AWSS3TransferManagerErrorType.unknown.rawValue:
                return "AWS Transfer Manager: unknown (Hmm, not sure what this means)"
            case AWSS3TransferManagerErrorType.cancelled.rawValue:
                return "AWS Transfer Manager: cancelled (Transfer was cancelled)"
            case AWSS3TransferManagerErrorType.paused.rawValue:
                return "AWS Transfer Manager: paused (Hmm, this looks like a bug. Please leave a bug report)"
            case AWSS3TransferManagerErrorType.completed.rawValue:
                return "AWS Transfer Manager: completed (Not sure why this is an error)"
            case AWSS3TransferManagerErrorType.internalInConsistency.rawValue:
                return "AWS Transfer Manager: internalInConsistency (Looks like a bug. Please leave a bug report.)"
            case AWSS3TransferManagerErrorType.missingRequiredParameters.rawValue:
                return "AWS Transfer Manager: missingRequiredParameters (Looks like a bug. Please leave a bug report.)"
            case AWSS3TransferManagerErrorType.invalidParameters.rawValue:
                return "AWS Transfer Manager: invalidParameters (Looks like a bug. Please leave a bug report.)"
            default:
                break
            }

        // AWS DynamoDB problem?
        case AWSDynamoDBErrorDomain:
            switch code {
            case AWSDynamoDBErrorType.unknown.rawValue:
                return "AWS DynamoDB: unknown (Hmm, not sure what this means)"
            case AWSDynamoDBErrorType.conditionalCheckFailed.rawValue:
                return "AWS DynamoDB: conditionalCheckFailed (Hmm, not sure what this means)"
            case AWSDynamoDBErrorType.internalServer.rawValue:
                return "AWS DynamoDB: internalServer (AWS issue?)"
            case AWSDynamoDBErrorType.itemCollectionSizeLimitExceeded.rawValue:
                return "AWS DynamoDB: itemCollectionSizeLimitExceeded (Hmm, not sure what this means)"
            case AWSDynamoDBErrorType.limitExceeded.rawValue:
                return "AWS DynamoDB: limitExceeded (Hmm, not sure what this means)"
            case AWSDynamoDBErrorType.provisionedThroughputExceeded.rawValue:
                return "AWS DynamoDB: provisionedThroughputExceeded (Try again later)"
            case AWSDynamoDBErrorType.resourceInUse.rawValue:
                return "AWS DynamoDB: resourceInUse (The table exists already)"
            case AWSDynamoDBErrorType.resourceNotFound.rawValue:
                return "AWS DynamoDB: resourceNotFound (Could not find the table)"
            default:
                break
            }
            
        // AWS S3 problem?
        case AWSS3ErrorDomain:
            
            switch code {
            case AWSS3ErrorType.unknown.rawValue:
                return "AWS S3: unknown (Hmm, not sure what this means)"
            case AWSS3ErrorType.bucketAlreadyExists.rawValue:
                return "AWS S3: bucketAlreadyExists (Hmm, not sure what this means)"
            case AWSS3ErrorType.bucketAlreadyOwnedByYou.rawValue:
                return "AWS S3: bucketAlreadyOwnedByYou (Hmm, not sure what this means)"
            case AWSS3ErrorType.noSuchBucket.rawValue:
                return "AWS S3: noSuchBucket (Hmm, not sure what this means)"
            case AWSS3ErrorType.noSuchKey.rawValue:
                return "AWS S3: noSuchKey (Hmm, not sure what this means)"
            case AWSS3ErrorType.noSuchUpload.rawValue:
                return "AWS S3: noSuchUpload (Hmm, not sure what this means)"
            case AWSS3ErrorType.objectAlreadyInActiveTier.rawValue:
                return "AWS S3: objectAlreadyInActiveTier (Hmm, not sure what this means)"
            case AWSS3ErrorType.objectNotInActiveTier.rawValue:
                return "AWS S3: objectNotInActiveTier (Hmm, not sure what this means)"
            default:
                break
            }
                        
        default:
            break
        }

        return localizedDescription
    }
}
