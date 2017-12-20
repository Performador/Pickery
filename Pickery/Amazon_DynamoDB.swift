//
//  AmazonDynamoDB.swift
//  Pickery
//
//  Created by Okan Arikan on 7/22/16.
//
//

import Foundation
import AWSDynamoDB
import ReactiveSwift
import Result

/// DynamoDB related functions
extension Amazon {
    
    /// Remove a DynamoDB table
    ///
    /// - parameter queue: The queue to execute on
    /// - parameter tableName: The table to remove
    /// - returns: The producer that will execute the task
    internal class func deleteDynamoDBTable(queue:       AmazonTaskQueue,
                                            tableName:   String) -> SignalProducer<(),NSError> {
        
        return SignalProducer<(),NSError> { sink, disposible in
            let request : AWSDynamoDBDeleteTableInput        =   AWSDynamoDBDeleteTableInput()
            request.tableName   =   tableName
            
            // Execute
            queue.run(taskGenerator: {
                return AWSDynamoDB.default().deleteTable(request)
            }, description: "Deleting DynamoDB table: \(tableName)") { task in
                if let error = task.error {
                    sink.send(error: error as NSError)
                } else {
                    sink.sendCompleted()
                }
            }
        }
    }
    
    /// Wait for a dynamodb table to be fully created
    ///
    /// - parameter queue: The queue to execute on
    /// - parameter sink: The sink to deliver events to
    /// - parameter tableName: The name of the table to wait
    internal class func waitForTable(queue:      AmazonTaskQueue,
                                     sink:       Signal<(),NSError>.Observer,
                                     tableName:  String) {
        
        
        let describeInput : AWSDynamoDBDescribeTableInput = AWSDynamoDBDescribeTableInput()
        
        describeInput.tableName = tableName
        
        // Send the request
        queue.run(taskGenerator: {
            return AWSDynamoDB.default().describeTable(describeInput)
        }, description: "Checking DynamoDB table: \(tableName)") { task in
            
            if let error = task.error {
                sink.send(error: error as NSError)
            } else {
                
                if  let result = task.result,
                    let table = result.table,
                    table.tableStatus == .active {
                    sink.sendCompleted()
                } else {
                    Amazon.waitForTable(queue:      queue,
                                        sink:       sink,
                                        tableName:  tableName)
                }
                
            }
        }
    }
    
    /// Initialize the DynamoDB Assets table where we keep the meta data
    ///
    /// - parameter queue: The queue to execute on
    /// - parameter tableName: The table to create
    /// - returns: The producer that will execute the task
    internal class func initializeDynamoDBTable(queue: AmazonTaskQueue,
                                                tableName: String) -> SignalProducer<(),NSError> {
                
        return SignalProducer<(),NSError> { sink, disposible in
            
            /// Create the input
            let createInput : AWSDynamoDBCreateTableInput = AWSDynamoDBCreateTableInput()
            
            createInput.tableName               =   tableName
            createInput.attributeDefinitions    =   [
                self.makeAttribute(name: AmazonModel.hashKeyAttribute(), type: AWSDynamoDBScalarAttributeType.S),
            ]
            
            createInput.keySchema               =   [
                self.makeKey(name: AmazonModel.hashKeyAttribute(), type: AWSDynamoDBKeyType.hash),
            ]
            
            createInput.provisionedThroughput   =   Amazon.defaultThroughput()
            
            // Send the request
            queue.run(taskGenerator: {
                return AWSDynamoDB.default().createTable(createInput)
            }, description: "Creating DynamoDB table: \(tableName)") { task in
                
                // Did we fail?
                if let error = task.error as NSError?, error.code != AWSDynamoDBErrorType.resourceInUse.rawValue {
                    sink.send(error: error)
                } else {

                    // Wait until the table is good to go
                    waitForTable(queue: queue, sink: sink, tableName: tableName)
                }
            }
        }
    }
    
    /// Add an asset record to DynamoDB
    ///
    /// - parameter queue: The queue to execute on
    /// - parameter asset : The local asset we want to create the record for
    /// - parameter resourceReceipts: The resource receipts that have already been uploaded to S3
    /// - returns: The producer that will execute the task
    internal class func record(asset metaData: [ String : Any ],
                               using queue: AmazonTaskQueue,
                               with resourceReceipts: [ UploadResourceReceipt ]) -> SignalProducer<UploadAssetReceipt, NSError> {
        
        return SignalProducer<UploadAssetReceipt, NSError> { sink, disposible in
            
            // We must have at least one resource
            guard resourceReceipts.count > 0 else {
                sink.send(error: PickeryError.internalNoResourcesForAsset as NSError)
                sink.sendCompleted()
                return
            }
            
            assert(resourceReceipts.filter { $0.data[MetaInfoKey.entryType.rawValue] as? String ?? "" == ResourceType.thumbnail.rawValue }.count > 0,"There must be non-thumbnail resources for asset")
            
            // Find a signature for the asset
            // This is where we go from multiple resource reipts to a single identifier for the collection
            // The signature for the asset is the minimum signature
            //
            // FIXME: Remove the !
            let signature = resourceReceipts.flatMap { return $0.data[MetaInfoKey.signature.rawValue] as? String }.sorted { return $0 < $1 }.first!
            
            Logger.debug(category: .amazon, message: "Recording asset \(signature)")

            // The dict that will store the final meta data on DynamoDB
            let assetInfo  = metaData + [   MetaInfoKey.signature.rawValue: signature,
                                            MetaInfoKey.resources.rawValue: resourceReceipts.map { return $0.data },
                                        ]
            
            // Create the model that we will write
            let model : AmazonModel =   AmazonModel()
            model.signature         =   signature
            
            do {
                model.metaData = try assetInfo.toJSON()
                
                // We must have asset meta data
                if model.metaData == nil {
                    throw PickeryError.internalUnableToSaveMetaData
                }
            } catch let error {
                sink.send(error: error as NSError)
            }

            /// Write the model
            model.timeStateChanged  =   GlobalConstants.double(from: Date()) as NSNumber

            // Write the dynamoDB record
            queue.run(taskGenerator: {
                return AWSDynamoDBObjectMapper.default().save(model)
            }, description: "Recording asset meta data") { task in

                // Did we fail?
                if let error = task.error {
                    sink.send(error: error as NSError)
                } else {
                    
                    Logger.debug(category: .amazon, message: "Done recording asset \(signature)")
                    
                    // Yes, we did upload this asset
                    sink.send(value: UploadAssetReceipt(signature: signature, data: assetInfo as [String : AnyObject]))
                                            
                    /// We are done
                    sink.sendCompleted()
                }
            }
        }
    }
    
    /// Internal function for requesting a page of results
    ///
    /// - parameter queue: The queue to execute on
    /// - parameter timeStateChanged: Only lookup changes since this date
    /// - parameter startKey: The start key for paging (nil for the first page)
    /// - parameter sink: The sink to send the changes to
    internal class func refresh(queue:               AmazonTaskQueue,
                                timeStateChanged:    Double,
                                startKey:            [ String : AWSDynamoDBAttributeValue ]?,
                                sink:                Signal< [ AmazonModel ], NSError>.Observer) {
        
        // Do a DynamoDB query for all assets changed after this
        let expression = AWSDynamoDBScanExpression()
        
        expression.filterExpression             =   "timeStateChanged > :val"
        expression.expressionAttributeValues    =   [   ":val"      : timeStateChanged as NSNumber ]
        expression.exclusiveStartKey            =   startKey
        
        queue.run(taskGenerator: {
            return AWSDynamoDBObjectMapper.default()
                .scan(AmazonModel.self, expression: expression)
        }, description: "Fetching new asset meta data") { task in
            
            // Did we fail?
            if let error = task.error {
                sink.send(error: error as NSError)
            } else {
                
                // Fetch the models
                if  let output = task.result,
                    let items = output.items as? [ AmazonModel ] {
                    sink.send(value: items)
                    
                    // Got more results?
                    if let lastKey = output.lastEvaluatedKey {
                        
                        // Ask for the next page
                        Amazon.refresh(queue:               queue,
                                       timeStateChanged:    timeStateChanged,
                                       startKey:            lastKey,
                                       sink:                sink)
                    } else {
                        
                        /// We are done
                        sink.sendCompleted()
                    }
                } else {
                    sink.sendCompleted()
                }
            }
        }
    }
    
    /// Add an asset record to DynamoDB about an asset
    ///
    /// - parameter queue: The queue to execute on
    /// - parameter signature: The signature for this asset
    /// - returns: The producer that will execute the task
    internal class func recordAssetDeletion(queue: AmazonTaskQueue,
                                            signature: String) -> SignalProducer<String, NSError> {
        
        return SignalProducer<String, NSError> { sink, disposible in
            
            Logger.debug(category: .amazon, message: "Recording asset deletion for \(signature)")
            
            // Create the model that we will write
            let model : AmazonModel =   AmazonModel()
            model.signature         =   signature
            model.metaData          =   nil
            model.timeStateChanged  =   GlobalConstants.double(from: Date()) as NSNumber
            
            // Write the dynamoDB record
            queue.run(taskGenerator: {
                return AWSDynamoDBObjectMapper.default().save(model)
            }, description: "Removing asset meta data") { task in
                
                // Did we fail?
                if let error = task.error {
                    sink.send(error: error as NSError)
                } else {
                    
                    /// We are done
                    sink.send(value: signature)
                    sink.sendCompleted()
                }
            }
        }
    }
    
    
    /// Make a dynamoDB attribute
    ///
    /// - parameter name : The name of the attribute
    /// - parameter type : The type of the attribute
    /// - returns : The attribute definition
    internal class func makeAttribute(name: String, type: AWSDynamoDBScalarAttributeType) -> AWSDynamoDBAttributeDefinition {
        let def : AWSDynamoDBAttributeDefinition = AWSDynamoDBAttributeDefinition()
        def.attributeName  =   name
        def.attributeType  =   type
        
        return def
    }
    
    /// Make a dynamoDB key definition
    ///
    /// - parameter name : The name of the key
    /// - parameter type : The type of the key
    /// - returns : The key definition
    internal class func makeKey(name: String, type: AWSDynamoDBKeyType) -> AWSDynamoDBKeySchemaElement {
        let key : AWSDynamoDBKeySchemaElement = AWSDynamoDBKeySchemaElement()
        key.attributeName =   name
        key.keyType       =   type
        
        return key
    }
    
    /// Allocate a default throughput definition for the table
    ///
    /// - returns : The key definition
    internal class func defaultThroughput() -> AWSDynamoDBProvisionedThroughput {
        let throughput : AWSDynamoDBProvisionedThroughput         =   AWSDynamoDBProvisionedThroughput()
        throughput.readCapacityUnits    =   Constants.kDynamoDBReadCapacityUnits as NSNumber
        throughput.writeCapacityUnits   =   Constants.kDynamoDBWriteCapacityUnits as NSNumber
        
        return throughput
    }
}
