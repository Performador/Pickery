//
//  SettingsViewController.swift
//  Pickery
//
//  Created by Okan Arikan on 8/26/16.
//
//


import UIKit
import Photos
import Eureka
import ReactiveSwift
import FileBrowser

/// Presents the settings
class SettingsViewController : FormViewController {
    
    /// Various constants
    struct Constants {
        static let kUploadQueueTag      =   "UploadingTag"
        static let kSizeTagPrefix       =   "SizeTag"
    }
    
    /// The disposibles we are listenning
    let disposibles = ScopedDisposable(CompositeDisposable())
    
    /// The gallery data
    var galleryData = GalleryManager.sharedInstance.galleryData.value {
        didSet {
            if isViewLoaded {
                tableView?.reloadData()
            }
        }
    }
    
    /// Called to update the queue cell
    func updateUploadQueue() {
        
        // Find the cell for the upload queue
        if let row = self.form.rowBy(tag: Constants.kUploadQueueTag) as? LabelRow {
            row.title   =   "\(RemoteLibrary.sharedInstance.uploadQueue.currentlyExecuting.value) uploading" + (RemoteLibrary.sharedInstance.uploadQueue.numPending.value > 0 ? " - \(RemoteLibrary.sharedInstance.uploadQueue.numPending.value) pending" : "")
            row.updateCell()
            row.evaluateHidden()
        }
    }
    
    /// Create the form
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen to the gallery changes
        disposibles += GalleryManager
            .sharedInstance
            .galleryData
            .signal
            .observe(on: UIScheduler())
            .observeValues { [ unowned self ] value in
                self.galleryData = value
            }
        
        // Listen to the upload queue changes
        disposibles += RemoteLibrary.sharedInstance.uploadQueue.numPending.producer
            .combineLatest(with: RemoteLibrary.sharedInstance.uploadQueue.currentlyExecuting.producer)
            .observe(on: UIScheduler())
            .on(value: { [ unowned self ] value in
                self.updateUploadQueue()
            })
            .start()
        
        // The debug settings
        title   =   "Settings"
        
        // Network settings
        form +++ Section("Network")
            <<< PickerInlineRow<Int>() { row in
                    row.title   =   "Simultaneous uploads"
                    row.value   =   Settings.numParallelUploads.value
                    row.options =   [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ]
                }.onChange({ (row: PickerInlineRow<Int>) in
                    Settings.numParallelUploads.value = row.value ?? Settings.numParallelUploads.defaultValue
                })
            <<< PickerInlineRow<Int>() { row in
                    row.title   =   "Simultaneous downloads"
                    row.value   =   Settings.numParallelDownloads.value
                    row.options =   [ 1, 2, 4, 8, 12 ]
                }.onChange({ (row: PickerInlineRow<Int>) in
                    Settings.numParallelDownloads.value = row.value ?? Settings.numParallelDownloads.defaultValue
                })
            <<< SwitchRow() { row in
                    row.title   =   "Enable uploads"
                    row.value   =   Settings.enableUpload.value
                }.onChange { row in
                    Settings.enableUpload.value = row.value ?? Settings.enableUpload.defaultValue
                }
            <<< SwitchRow() { row in
                    row.title   =   "Cellullar uploads"
                    row.value   =   Settings.cellularUpload.value
                }.onChange { row in
                    Settings.cellularUpload.value = row.value ?? Settings.cellularUpload.defaultValue
                }
        
        // The gallery data
        form +++ Section("Gallery")
            
            <<< LabelRow() { row in
                    row.title = "Local only"
                }.cellUpdate { cell, row in
                    cell.detailTextLabel?.text = "\(self.galleryData.assets.filter { ($0 is PhotosAsset) &&  (($0 as? PhotosAsset)?.remoteAsset == nil) }.count)"
                }
            
            <<< LabelRow() { row in
                    row.title = "Remote only"
                }.cellUpdate { cell, row in
                    cell.detailTextLabel?.text = "\(self.galleryData.assets.filter { $0 is RemoteAsset }.count) (\(Formatters.sharedInstance.bytesFormatter.string(fromByteCount: self.galleryData.numRemoteOnlyBytes)))"
                }
            
            <<< LabelRow() { row in
                    row.title   =   "Local & Remote"
                }.cellUpdate { cell, row in
                    cell.detailTextLabel?.text = "\(self.galleryData.alreadyUploaded.count) (\(Formatters.sharedInstance.bytesFormatter.string(fromByteCount: self.galleryData.numLocalRemoteBytes)))"
                }
        
            <<< LabelRow(Constants.kUploadQueueTag) { row in
                    row.hidden  =   Condition.function([], { form in
                        RemoteLibrary.sharedInstance.uploadQueue.currentlyExecuting.value == 0 && RemoteLibrary.sharedInstance.uploadQueue.numPending.value == 0
                    })
                
                }.cellUpdate { cell, row in
                    row.evaluateHidden()
                }
        
        // Do we have actual sizes?
        let sizesSection = Section("Sizes")
        for type in ResourceType.allValues {
            sizesSection <<< LabelRow(Constants.kSizeTagPrefix + type.rawValue) { row in
                row.title   = "\(type.rawValue)"
                row.hidden  =   Condition.function([], { form in
                    self.galleryData.bytesPerResourceType[type.rawValue] == nil
                })
            }.cellUpdate { cell, row in
                cell.detailTextLabel?.text = "\(Formatters.sharedInstance.bytesFormatter.string(fromByteCount: self.galleryData.bytesPerResourceType[type.rawValue] ?? 0))"
            }
        }
        form +++ sizesSection
        
        // Delete everything
        form +++ Section()
            <<< ButtonRow() { row in
                    row.title = "Delete Remote"
                }.onCellSelection { _ in
                    self.nuke()
                }
    
        // Mainly for debugging
        form +++ Section()
            <<< ButtonRow() { row in
                    row.title = "Debug Settings"
                }.onCellSelection { _ in
                    self.navigationController?.pushViewController(DebugSettingsViewController(), animated: true)
                }

        // Update the upload queue
        updateUploadQueue()
    }
    
    
    /// Remove everything
    func nuke() {
        let alert = UIAlertController(title: "Remove remote assets", message: "I will not touch your photo library on the device, but I will remove the your media from the cloud. Are you sure?", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        // The descructive action
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: { _ in
            
            // Run the task
            self.runTask(title: "Removing your data\nin the cloud", task: RemoteLibrary.sharedInstance.removeBackend()
                .observe(on: UIScheduler())
                .on( completed: {
                    
                    // Install the nil backend
                    RemoteLibrary.sharedInstance.install(backend: nil)
                    
                    // Go back to the root view controller
                    _ = self.navigationController?.popToRootViewController(animated: true)
                }))
        }))
        
        // The cancel action
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { _ in
            
        }))
        
        // Show the alert
        present(alert, animated: true) {
            
        }
    }
}
