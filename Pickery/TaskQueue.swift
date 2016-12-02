//
//  TaskQueue.swift
//  Pickery
//
//  Created by Okan Arikan on 8/30/16.
//
//

import Foundation
import ReactiveSwift
import Result

/// Encapsulates a queue where multiple tasks can go at the same time
class TaskQueue<T : Equatable, U> {

    /// A block that is responsible for actual execution of the tasks
    typealias Executor = (T) -> SignalProducer<U,NSError>
    
    /// The scheduler for the tasks
    let scheduler               =   QueueScheduler()
    
    /// The set of tasks waiting to execute
    var pendingTasks            =   [ T ]()
    
    /// The function that actually executes the task
    var executor                :   Executor?
    
    /// The number of parallel tasks
    let numSimultaneousTasks    :   UserDefault<Int>
    
    /// Some events we fire
    let queueEmpty              =   SignalSource<(),NoError>()
    let currentlyExecuting      =   MutableProperty<Int>(0)
    let numPending              =   MutableProperty<Int>(0)
    
    /// The disposibles we are listenning
    let disposibles             =   ScopedDisposable(CompositeDisposable())
    
    /// Ctor
    init(numSimultaneousTasks: UserDefault<Int>) {
        self.numSimultaneousTasks   =   numSimultaneousTasks
        
        // When the simultaneous tasks change, re-jiggle the queue
        disposibles += numSimultaneousTasks
            .valueProperty
            .signal
            .observe(on: scheduler)
            .observeValues { _ in
                self.checkQueue()
            }
    }
    
    /// Called when a task is finished
    private func taskFinishedOnQueue() {
        
        // We are no longer executing a task
        currentlyExecuting.value = currentlyExecuting.value - 1
        
        // Let's see if we should start another
        checkQueue()
        
        // If there are no more tasks left, deliver the done signal
        if currentlyExecuting.value == 0 {
            assert(pendingTasks.isEmpty)
            queueEmpty.observer.send(value: ())
        }
    }
    
    /// Check if there are tasks to be executed on the queue and start one if there is
    private func checkQueue() {
        
        // Have the bandwidth?
        if currentlyExecuting.value < numSimultaneousTasks.value {
            
            // FIXME: This should be a priority queue
            if let task = pendingTasks.popLast() {
                
                // The pending tasks has changed
                numPending.value = pendingTasks.count
            
                // Execute the task
                currentlyExecuting.value = currentlyExecuting.value + 1
                
                // Go back to background and start executing the task
                dispatchBackground {
                    
                    // We must have an executor
                    assert(self.executor != nil, "The executor was not set")
                    
                    // Execute the task
                    self.executor?(task)
                        .observe(on: self.scheduler)
                        .on(failed: { error in
                            Logger.error(error: error)
                        }, terminated: {
                            self.taskFinishedOnQueue()
                        })
                        .start()
                }
                
                // Check again
                checkQueue()
            }
        }
    }
    
    /// Queue a task
    func queue(task: T) {
        
        // We better be on the main queue
        assertMainQueue()
        
        // Increase the number of remaining tasks
        scheduler.queue.async {
            self.pendingTasks.append(task)
            self.checkQueue()
        }
    }
    
    /// Cancel a particular task
    func cancel(task: T) {
        
        // We better be on the main queue
        assertMainQueue()
        
        // Go to the serial queue and clear all pending tasks
        scheduler.queue.async {
            
            // Remove all pending tasks
            self.pendingTasks = self.pendingTasks.filter { $0 != task }
            
            // Fire notification
            self.numPending.value = self.pendingTasks.count
        }
    }
    
    /// Check the queue for tasks to execute
    func check() {
        scheduler.queue.async {
            self.checkQueue()
        }
    }

    /// Cancell all tasks
    func cancelAll() {
        
        // We better be on the main queue
        assertMainQueue()
        
        // Go to the serial queue and clear all pending tasks
        scheduler.queue.async {
            
            // Remove all pending tasks
            self.pendingTasks.removeAll()
            
            // Fire notification
            self.numPending.value = self.pendingTasks.count
        }
    }
}
