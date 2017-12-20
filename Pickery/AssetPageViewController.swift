//
//  AssetPageViewController.swift
//  Pickery
//
//  Created by Okan Arikan on 8/1/16.
//
//

import UIKit
import Photos
import ReactiveSwift
import Result
import FontAwesome_swift

// The view controller that displays a linear array of assets
class AssetPageViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource, ViewTransitionController {
    
    /// Da constants
    struct Constants {
        static let kMinimumSize             =   CGSize(width: 120,height: 80)
        static let kFocusBackgroundColor    =   UIColor.black
        static let kBackgroundColor         =   UIColor.white
        static let kLargePlayFont           =   UIFont.fontAwesome(ofSize:64)
    }
    
    /// The transition view if any
    var transitionView          :   UIView {
        return (currentViewController as? AssetViewController)?.transitionView ?? UIView(frame: CGRect.zero)
    }
    
    /// The current index in the gallery data
    var currentIndex            :   Int
    
    /// The asset we are displaying now
    var currentAsset            :   Asset {
        didSet {
            
            // Did we go to the previous index?
            if currentIndex > 0 && galleryData.assets[currentIndex - 1].identifier == currentAsset.identifier {
                currentIndex -= 1
            } else if currentIndex < (galleryData.assets.count - 1) && galleryData.assets[currentIndex + 1].identifier == currentAsset.identifier {
                currentIndex += 1
            } else if let foundIndex = galleryData.index(for: currentAsset) {
                currentIndex = foundIndex
            } else {
                assetNotInGalleryData()
            }
            
            // Sync the changes
            currentAssetChanged()
        }
    }
    
    /// Grab the current asset view controller
    var currentViewController   :   UIViewController {
        didSet {
            
            // We better be loaded yo
            guard isViewLoaded else {
                return
            }
            
            // We must have a view controller
            guard let asset = (currentViewController as? AssetViewController)?.asset else {
                assetNotInGalleryData()
                return
            }
            
            // Set the asset
            currentAsset = asset
        }
    }
    
    /// The disposibles we are listenning
    let disposibles             =   ScopedDisposable(CompositeDisposable())
    
    /// Grab the latest gallery data
    var galleryData             =   GalleryManager.sharedInstance.galleryData.value
    
    /// In the focus mode, we hide the toolbars
    var focusMode = false {
        didSet {
            navigationController?.setNavigationBarHidden(focusMode, animated: isViewLoaded)
            
            // Update the background color
            UIView.animate(withDuration: 0.5) {
                self.view.backgroundColor =   self.focusMode ? Constants.kFocusBackgroundColor : Constants.kBackgroundColor
            }
        }
    }
    
    /// Ctor
    init?(currentAsset: Asset) {
        
        // Are we able to find this asset?
        if let foundIndex = galleryData.index(for: currentAsset) {
            self.currentIndex = foundIndex
        } else {
            return nil
        }
        
        // Save the current asset
        self.currentAsset   =   currentAsset
        
        // The current view controller
        currentViewController = AssetViewController(asset: currentAsset)
        
        // Super init
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        
        // No back button text
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // We are the data source and delegate
        delegate   =   self
        dataSource =   self
        
        // Listen to the gallery data changes and respond appropriately
        disposibles += GalleryManager
            .sharedInstance
            .galleryData
            .signal
            .observe(on: UIScheduler())
            .observeValues { [ unowned self ] galleryData in
                
                // Update the current index
                if let foundIndex = galleryData.index(for: currentAsset) {
                    self.currentIndex   =   foundIndex
                    self.galleryData    =   galleryData
                } else {
                    self.assetNotInGalleryData()
                }
            }
        
        
        // Set the view controllers
        setViewControllers([ currentViewController ], direction: .forward, animated: false, completion: nil)
        
        // This interferes with the transition
        automaticallyAdjustsScrollViewInsets = false
    }
    
    /// Sync the display
    func currentAssetChanged() {
        
        // Set the right bar button items
        navigationItem.setRightBarButtonItems(currentViewController.navigationItem.rightBarButtonItems, animated: true)
        
        // Update the title
        navigationItem.titleView = currentViewController.navigationItem.titleView
    }
    
    /// Play the current asset
    func play() {
        (currentViewController as? AssetViewController)?.play()
    }
    
    /// Get info about the current item
    func info(sender: UIBarButtonItem) {
        
        // Present information about the current asset
        present(form: AssetDetailsViewController(asset: currentAsset), from: sender)
    }
    
    /// Enter/exit focus mode
    @objc func toggleFocusMode() {
        focusMode = !focusMode
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// We were unable to find the asset in the gallery
    func assetNotInGalleryData() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    /// Add the transition view
    func insertTransitionView(transitionView: UIView) {
        (currentViewController as? AssetViewController)?.insertTransitionView(transitionView: transitionView)
    }
    
    /// Load the view
    override func loadView() {
        super.loadView()
        
        // The default background color
        view.backgroundColor = Constants.kBackgroundColor
        
        // Listen to the tap events for focus mode
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleFocusMode)))
    }
    
    /// The first time initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sync the changes
        currentAssetChanged()
    }
    
    /// Make sure we have the toolbar
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    /// Create the view controller
    func assetController(at index: Int) -> AssetViewController? {
        
        guard let asset = galleryData.asset(at: index) else {
            return nil
        }
        
        return AssetViewController(asset: asset)
    }
    
    /// Data source functions
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return assetController(at: currentIndex + 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return assetController(at: currentIndex - 1)
    }
    
    /// Delegate functions
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let controllers = viewControllers, completed == true {
            for controller in controllers {
                currentViewController = controller
            }
        }
    }
}
    
