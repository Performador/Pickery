//
//  DebugSettingsViewController.swift
//  Pickery
//
//  Created by Okan Arikan on 11/28/16.
//
//

import UIKit
import Photos
import Eureka
import ReactiveSwift
import FileBrowser

/// Presents the debug settings
class DebugSettingsViewController : FormViewController {
    
    /// Da constants
    struct Constants {
        static let kClearTmpTag = "ClearTmpTag"
    }
    
    /// The disposibles we are listenning
    let disposibles = ScopedDisposable(CompositeDisposable())
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    /// Create the form
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen to the upload queue changes
        disposibles += RemoteLibrary.sharedInstance.uploadQueue.numPending.producer
            .combineLatest(with: RemoteLibrary.sharedInstance.uploadQueue.currentlyExecuting.producer)
            .observe(on: UIScheduler())
            .on(value: { [ unowned self ] value in
                self.form.rowBy(tag: Constants.kClearTmpTag)?.evaluateHidden()
            })
            .start()
        
        // The debug settings
        title   =   "Debug Settings"
        
        // Mainly for debugging
        form +++ Section("Browse")
            <<< ButtonRow() { row in
                row.title = "Tmp Directory"
                }.onCellSelection { _ in
                    self.present(FileBrowser(initialPath: URL(fileURLWithPath: NSTemporaryDirectory())), animated: true)
            }
            <<< ButtonRow() { row in
                row.title = "File Cache"
                }.onCellSelection { _ in
                    self.present(FileBrowser(initialPath: FileManager.cacheURL), animated: true)
                }
        
        // Delete everything
        form +++ Section("Delete")
            <<< ButtonRow(Constants.kClearTmpTag) { row in
                    row.title   = "Clear Tmp Directory"
                    row.hidden  = Condition.function([], { form in
                        return  RemoteLibrary.sharedInstance.uploadQueue.currentlyExecuting.value > 0 ||
                                RemoteLibrary.sharedInstance.uploadQueue.numPending.value > 0
                    })
                }.onCellSelection { row in
                    FileManager.default.clearFolder(at: FileManager.tmpURL)
                }
            <<< ButtonRow() { row in
                    row.title = "Clear File Cache"
                }.onCellSelection { row in
                    RemoteLibrary.sharedInstance.fileCache.clear()
                }
            <<< ButtonRow() { row in
                    row.title = "Reset Transient Data"
                }.onCellSelection { _ in
                    
                    // Go back to the root view controller
                    _ = self.navigationController?.popToRootViewController(animated: true)
                    
                    // Clear the user defaults
                    if let identifier = Bundle.main.bundleIdentifier {
                        UserDefaults.standard.removePersistentDomain(forName: identifier)
                    }
                    
                    // Reset the transient data
                    RemoteLibrary.sharedInstance.resetTransientData()
            }        
    }
}
