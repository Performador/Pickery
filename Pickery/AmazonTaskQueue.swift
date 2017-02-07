//
//  AmazonTaskQueue.swift
//  Pickery
//
//  Created by Okan Arikan on 7/22/16.
//
//

import Foundation
import ReactiveSwift
import Result

/// Keeps track of the AWS requests in flight
class AmazonTaskQueue {
    
    /// Execute a task and run the completion block
    /// This is just a thin wrapper around continueWithBlock
    ///
    /// This function is thread safe
    ///
    /// - parameter taskGenerator: The block to generate the AWSTask (this is a block in case we want to re-try)
    /// - parameter description: The task description
    /// - parameter completion: The completion block to run after the task is executed
    func run<ResultType : AnyObject>(   taskGenerator:  @escaping () -> AWSTask<ResultType>,
                                        description:    String,
                                        completion:     @escaping (AWSTask<ResultType>) -> Void) {
        
        let task = taskGenerator()
        
        // We are starting a request
        Network.sharedInstance.willBeginRequest()
        
        // Run the task
        task.continueWith( block: { (task: AWSTask<ResultType>) -> (Any?) in
            
            // Done with the request
            Network.sharedInstance.didFinishRequest()
            
            // Needs tetrying
            if let error = task.error, (error as NSError).shouldRetry {
                
                // Retry
                self.run(taskGenerator: taskGenerator,
                         description:   description,
                         completion:    completion)
            } else {
            
                // Run the completion block
                completion(task)
            }
            
            // No more tasks
            return nil
        })
    }
}
