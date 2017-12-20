//
//  CollectionViewController.swift
//  Pickery
//
//  Created by Okan Arikan on 8/1/16.
//
//

import Foundation
import ReactiveSwift
import Result
import Photos
import FontAwesome_swift

/// The main class for showing multiple assets in a collection view
///
/// Provides the base functionality for transitioning between controllers and
/// keeping the data source around
class AssetCollectionViewController : UICollectionViewController {
    
    /// The disposibles we are listenning
    let disposibles             =   ScopedDisposable(CompositeDisposable())
    
    /// Da data source
    let dataSource              =   AssetsDataSource(galleryData: GalleryManager.sharedInstance.galleryData.value)
    
    /// If we just pushed/popped from another collection view, this will hold the
    /// index paths for the selected assets.
    /// Once the view is loaded we will set these items to be selected and
    /// make sure that they are visible on the screen
    var pendingSelection        :   [ IndexPath ]?
    
    /// The gallery data we are displaying in the collection view
    var galleryData             :   GalleryData {
        get { return dataSource.galleryData }
        set {
            
            // We better be on the main queue
            assertMainQueue()
            
            // Animate the changes
            dataSource.animatedChangesTo(collectionView: collectionView, galleryData: newValue)
        }
    }
    
    /// Forward the selection from collection view
    var selectedIndexPaths : [ IndexPath ]? {
        get { return collectionView?.selectedIndexPaths }
        set { collectionView?.selectedIndexPaths = newValue }
    }
    
    /// Da bar button items
    var deleteSelectedBarButtonItem : UIBarButtonItem!
    var purgeBarButtonItem          : UIBarButtonItem!
    var settingsBarButtonItem       : UIBarButtonItem!
    var requestAccessBarButtonItem  : UIBarButtonItem!
    var internetBarButtonItem       : UIBarButtonItem!
}

// MARK: - View controller overrides
extension AssetCollectionViewController {
    
    /// Create the views and establish the view hierarchy
    override func loadView() {
        super.loadView()
        
        // We don;t want this for transitions
        clearsSelectionOnViewWillAppear  = false
        
        // Configure the collection view
        collectionView?.dataSource              =   dataSource
        collectionView?.allowsSelection         =   true
        collectionView?.allowsMultipleSelection =   false
        collectionView?.backgroundColor         =   UIColor.white
        collectionView?.alwaysBounceVertical    =   true
        
        // Register the collection view cells with the collection view
        collectionView?.register(AssetGridCell.self,        forCellWithReuseIdentifier: AssetGridCell.Constants.kReuseIdentifier)
        collectionView?.register(AssetsHeaderView.self,     forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: AssetsHeaderView.Constants.kReuseIdentifier)
        
        // Configure the refresh control
        let refreshControl              =   UIRefreshControl(frame: CGRect.zero)
        refreshControl.attributedTitle  =   NSAttributedString(string: "Refresh")
        refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: UIControlEvents.valueChanged)
        collectionView?.addSubview(refreshControl)
    }
    
    /// Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do further initialization
        title = "Assets"
        
        // No back button text
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // Allocate the bar button items
        deleteSelectedBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.trash, target: self, action: #selector(deleteSelected))
        purgeBarButtonItem          = UIBarButtonItem(icon: FontAwesome.recycle,                        target: self, action: #selector(purge))
        settingsBarButtonItem       = UIBarButtonItem(icon: FontAwesome.cog,                            target: self, action: #selector(showSettings(sender:)))
        requestAccessBarButtonItem  = UIBarButtonItem(icon: FontAwesome.question,                       target: self, action: #selector(requestAccess(sender:)))
        internetBarButtonItem       = UIBarButtonItem(icon: FontAwesome.exclamationTriangle,            target: self, action: #selector(internet(sender:)))
        
        // Update da bar button stuff
        updateBarButtonItems()
        
        // Listen to the changes to network (when the connectivity changes)
        disposibles += Network
            .sharedInstance
            .gotNetwork
            .signal
            .observe(on: UIScheduler())
            .observeValues { [ unowned self ] _ in
                assertMainQueue()
                
                self.updateBarButtonItems()
        }
        
        // Listen to the backend changes (when the backend is initialized)
        disposibles += RemoteLibrary
            .sharedInstance
            .backend
            .signal
            .observe(on: UIScheduler())
            .observeValues { [ unowned self ] _ in
                assertMainQueue()
                
                self.updateBarButtonItems()
        }

        // Observe changes to the gallery data
        disposibles += GalleryManager
            .sharedInstance
            .galleryData
            .signal
            .observe(on: UIScheduler())
            .observeValues { [ unowned self ] galleryData in
                assertMainQueue()
                
                let oldSelection = self.selectedIndexPaths?.flatMap { self.galleryData.asset(at: $0) }
                self.galleryData = galleryData
                
                // Update the index paths
                self.selectedIndexPaths = oldSelection?.flatMap { galleryData.indexPath(for: $0) }
                
                // Make sure we are in sync
                self.updateBarButtonItems()
        }
    }
    
    /// Do the appropriate scrolling
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // If we have pending selection, do it now
        if let selection = pendingSelection {
            selectedIndexPaths = pendingSelection
            
            // Scroll to the first item in the selection
            if let focusItem = selection.first {
                collectionView?.scrollToItem(at: focusItem, at: .centeredVertically, animated: false)
            }
            
            // No longer waiting to select
            pendingSelection = nil
        }
    }
    
    /// Update the nav/tool bars
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Setup the toolbars
        navigationController?.setToolbarHidden(true, animated: animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

// MARK: - Editing management
extension AssetCollectionViewController {
    
    /// Called to refresh the collection
    @objc func refresh(sender: UIRefreshControl) {
        
        // Turn off the refresh
        sender.endRefreshing()
        
        // Refresh the local cache
        RemoteLibrary.sharedInstance.setNeedsRefresh()
    }
}

// MARK: - Editing management
extension AssetCollectionViewController {
    
    /// Remove the items at these indexpaths
    func delete(items atIndexPaths: [ IndexPath ]) {
        
        // Get the selected assets first
        let selectedAssets = atIndexPaths.flatMap { galleryData.asset(at: $0) }
        
        // Partition into the photos and remote
        let photosAssets = selectedAssets.flatMap { $0 as? PhotosAsset }
        let remoteAssets = selectedAssets.flatMap { ($0 as? RemoteAsset) ?? ($0 as? PhotosAsset)?.remoteAsset }
        
        // We must have something to remove
        guard photosAssets.count > 0 || remoteAssets.count > 0 else {
            return
        }
        
        // Run the modal dialog
        runTask(title: "Removing",
                task:   PhotoLibrary
                            .sharedInstance
                            .deleteAssets(assets: photosAssets.map { $0.phAsset })
                    
                            // Filter out the permission errors
                            .flatMapError({ (error: NSError) -> SignalProducer<String, NSError> in
                                
                                // Convert the errors into user cancelled
                                return SignalProducer<String, NSError>(error: PickeryError.userCancelled as NSError)
                                
                            })

                            // Then remove the remote assets
                            .then(RemoteLibrary
                                        .sharedInstance
                                        .remove(assets: remoteAssets)))
        
    }
    
    /// Handle the editing mode enter/exit
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        // Update the cell status
        for cell in collectionView?.visibleCells ?? [] {
            (cell as? AssetGridCell)?.set(editing: editing, animated: animated)
        }
        
        // Update the bar button items
        updateBarButtonItems()
        
        // Clear the selection before we return
        selectedIndexPaths = nil
        
        // Whether we allow multiple selection or not
        collectionView?.allowsMultipleSelection = editing
    }
}

// MARK: - Collection view delegate methods
extension AssetCollectionViewController {
    
    // We want scroll to top behavior when the user taps on the status bar
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    /// Push the asset display
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // If we are in the edit mode, do not push the asset page controller
        guard isEditing == false else {
            updateBarButtonItems()
            return
        }
        
        Logger.debug(category: .ui, message: "\(type(of: self)) -> didSelect: \(indexPath)")
        
        // Push the asset
        if  let asset = galleryData.asset(at: indexPath),
            let pageController = AssetPageViewController(currentAsset: asset) {
            
            // Go to the page view controller
            navigationController?.pushViewController(pageController, animated: true)
        }
    }
    
    /// Deselecting an asset
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        if isEditing {
            updateBarButtonItems()
        }
    }
    
    /// A new cell is being displayed
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        // Make sure the editing property of the cell is in sync with the view controller
        (cell as? AssetGridCell)?.set(editing: isEditing, animated: false)
    }
}


// MARK: - Bar button management
extension AssetCollectionViewController {
    
    /// Update the bar button items here
    func updateBarButtonItems() {
        var items : [ UIBarButtonItem ] = [ editButtonItem ]
        
        if isEditing {
            
            if selectedIndexPaths?.count ?? 0 > 0 {
                items.append(deleteSelectedBarButtonItem)
                items.append(purgeBarButtonItem)
            }
        } else {
            
            if galleryData.alreadyUploaded.isEmpty == false  {
                items.append(purgeBarButtonItem)
            }
            
            // The settings
            items.append(settingsBarButtonItem)
        }
        
        // Got internet?
        if RemoteLibrary.sharedInstance.backend.value == nil {
            items.append(internetBarButtonItem)
        }
        
        // Do we not have access?
        switch PHPhotoLibrary.authorizationStatus() {
        case .denied: fallthrough
        case .restricted: fallthrough
        case .notDetermined:
            items.append(requestAccessBarButtonItem)
        default:
            break
        }
        
        navigationItem.setRightBarButtonItems(items, animated: isViewLoaded)
    }
    
    /// Enter the delete mode
    @objc func deleteSelected(sender: UIBarButtonItem) {
        
        // Delete the index paths
        delete(items: selectedIndexPaths ?? [ IndexPath ]())
        
        // Cancel
        cancelDeleteMode(sender: sender)
    }
    
    /// Cancel the delete mode
    func cancelDeleteMode(sender: UIBarButtonItem) {
        
        // No longer editing
        setEditing(false, animated: true)
    }
    
    /// Enter the delete mode
    func enterDeleteMode(sender: UIBarButtonItem) {

        // Yes, we are editing
        setEditing(true, animated: true)
    }
    
    /// Purge the already uploaded assets
    @objc func purge(sender: UIBarButtonItem) {
        
        // The local photos assets to remove
        let assetsToRemove = isEditing  ?   (selectedIndexPaths ?? []).flatMap { (galleryData.asset(at: $0) as? PhotosAsset)?.phAsset }
                                        :   galleryData.alreadyUploaded.map { $0.phAsset }

        // Got something?
        if assetsToRemove.count > 0 {
            runTask(title: "Removing duplicate photos assets",
                    task: PhotoLibrary
                            .sharedInstance
                            .deleteAssets(assets: assetsToRemove)
                        
                            // Filter out the permission errors
                            .flatMapError({ (error: NSError) -> SignalProducer<String, NSError> in
                    
                                // Convert the errors into user cancelled
                                return SignalProducer<String, NSError>(error: PickeryError.userCancelled as NSError)
                            })
                        
                            // Better be on the main thread
                            .observe(on: UIScheduler())
            
                            // If we are current in editing mode, switch back to normal
                            .on(completed: {
                                
                                if self.isEditing {
                                    self.setEditing(false, animated: true)
                                }
                            }))
        }
    }
    
    /// Got internet?
    @objc func internet(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Connectivity", message: "There was an error connecting to the backend", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        // Do we have an initializer?
        if let initializer = Credentials.sharedInstance.initializer {
            
            // Retry connecting
            alert.addAction(UIAlertAction(title: "Retry", style: UIAlertActionStyle.default, handler: { _ in
                RemoteLibrary.sharedInstance.initializeBackend(producer: initializer)
            }))
            
            /// Go home
            alert.addAction(UIAlertAction(title: "Home", style: UIAlertActionStyle.default, handler: { action in
                _ = self.navigationController?.popViewController(animated: true)
            }))
            
            /// OK - we don't care
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: { action in
                
            }))
        } else {
            
            /// OK - go back
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: { action in
                _ = self.navigationController?.popViewController(animated: true)
            }))
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    /// Request access
    @objc func requestAccess(sender: UIBarButtonItem) {
        let controller = UIAlertController(title: "Photo Library Access", message: "I need access to your photo library to back it up.", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        controller.addAction(UIAlertAction(title: "Take me to settings", style: UIAlertActionStyle.default, handler: { _ in
            if let url = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(url)
                controller.dismiss(animated: false, completion: {
                    
                })
            }
        }))
        
        controller.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { _ in
            
        }))
        
        present(controller, animated: true, completion: {
            
        })
    }
    
    /// Show the program settings
    @objc func showSettings(sender: UIBarButtonItem) {
        present(form: SettingsViewController(), from: sender)
    }
}


// MARK: - Transition suppport
extension AssetCollectionViewController : ViewTransitionController {
    
    /// The transition view to use for animated transitions
    var transitionView :   UIView {
        
        // We must have a visible cell for this item
        if  let selectedIndex   = selectedIndexPaths?.first,
            let collectionView  = collectionView,
            let cell            = collectionView.cellForItem(at: selectedIndex) as? AssetCell {
            
            // Do we have a visible cell already?
            return cell.transitionView
        }
        
        assertionFailure("Cannot animate transition if nothing is selected")
        return UIView(frame: CGRect.zero)
    }
    
    /// Insert it at the top
    func insertTransitionView(transitionView: UIView) {
        view.addSubview(transitionView)
    }
    
    
    /// We will transition from an index path
    func willTransition(from indexPath: IndexPath) {
        
        // Select the selection
        if isViewLoaded {
            Logger.debug(category: .ui, message: "\(type(of: self)) selection: \(indexPath)")
            
            selectedIndexPaths = [ indexPath ]
            
            // Is the cell we are transitioning from is outside the view?
            if collectionView?.indexPathsForVisibleItems.contains(indexPath) == false {
                
                // Scroll the collection so that it is visible
                collectionView?.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            }
        } else {
            pendingSelection = [ indexPath ]
        }
    }
    
    /// If the target controller is an asset viewer, make sure we are currently
    /// showing the asset it was displaying
    func selectAssetFromController(controller: UIViewController, animated: Bool) {
        
        // Grab the identifier of the asset we are transitioning from
        if let controller  = controller as? AssetCollectionViewController,
            let indexPath   = controller.selectedIndexPaths?.first {
            
            // Make sure the index path is visible
            willTransition(from: indexPath)
            
        } else if let controller = controller as? AssetPageViewController,
            let indexPath = galleryData.indexPath(for: controller.currentAsset) {
            
            // Make sure the index path is visible
            willTransition(from: indexPath)
        }
    }
}

// MARK: - Navigation management
extension AssetCollectionViewController : NavigationItem {
    func willPushTo(controller: UIViewController, animated: Bool) {

    }
    
    
    /// Going back, reset the remote library
    func willPopTo(controller: UIViewController, animated: Bool) {
        
        // Remove the backend
        RemoteLibrary.sharedInstance.install(backend: nil)
    }
    
    /// Figure out the selected index
    func willPopFrom(controller: UIViewController, animated: Bool) {
        
        // Make sure we are setup for the transition from another view controller
        selectAssetFromController(controller: controller, animated: animated)
    }
    
    func willPushFrom(controller: UIViewController, animated: Bool) {
        
        // Make sure we are setup for the transition from another view controller
        selectAssetFromController(controller: controller, animated: animated)
    }
}
