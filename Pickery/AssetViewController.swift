//
//  AssetViewController.swift
//  Pickery
//
//  Created by Okan Arikan on 7/20/16.
//
//

import UIKit
import AVFoundation
import AVKit
import FontAwesome_swift
import CoreLocation

/// Displays a single asset
class AssetViewController : UIViewController, ViewTransitionController, UIScrollViewDelegate {
    
    /// Da constants
    struct Constants {
        static let kLargePlayFont = UIFont.fontAwesome(ofSize: 64)
    }
    
    /// The title view
    var titleView   =   UILabel(frame: CGRect.zero)
    
    /// Da views
    var scrollView  :   UIScrollView!
    var assetView   :   AssetImageView!
    var liveView    :   AssetLiveView?
    
    /// Is there a better way of doing this?
    var needsReset  =   true
    
    /// The asset we are displaying
    let asset       :   Asset
    
    /// The aspect ratio of the asset
    var aspectRatio :   CGFloat { return asset.pixelSize.width / asset.pixelSize.height }
    
    /// Get the transition view
    var transitionView: UIView { return assetView }
    
    /// This is the large play icon for the video assets
    var largePlayButton         :   UIButton?
    
    /// Ctor
    init(asset: Asset) {
        self.asset              =   asset
        super.init(nibName: nil, bundle: nil)
                
        // No back button text
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // Update the navigation items
        var items : [ UIBarButtonItem ] = [ UIBarButtonItem(icon: FontAwesome.info, target: self, action: #selector(info(sender:))) ]
        
        if asset.isVideo {
            items.append(UIBarButtonItem(icon: FontAwesome.play, target: self, action: #selector(play)))
        }
        
        // The right bar button items
        navigationItem.rightBarButtonItems  =   items
        
        // The title view
        navigationItem.titleView            =   titleView
        
        // Create the subtitle
        let subtitle : String
        if let date = asset.dateCreated {
            subtitle = Formatters.sharedInstance.dateHeaderFormatter.string(from: date)
        } else {
            subtitle = ""
        }
        
        // Got location with this?
        if let location = asset.location {
            
            // Display empty title
            set(title: "...", subtitle: subtitle)

            let geocoder        = CLGeocoder()
            geocoder.reverseGeocodeLocation(location, completionHandler: { (placemark: [CLPlacemark]?, error: Error?) -> Void in
                if let error = error {

                    self.set(title: "Location Not Found", subtitle: subtitle)
                    
                    Logger.error(error: error)
                } else if let placemark = placemark {
                    for place in placemark {
                        //if let name = place.name {
                        if let name = place.locality {
                            self.set(title: name, subtitle: subtitle)
                            break
                        }
                    }
                }
            })
        } else {
            self.set(title: "No Location", subtitle: subtitle)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Add the transition view on top
    func insertTransitionView(transitionView: UIView) {
        view.insertSubview(transitionView, aboveSubview: scrollView)
    }
    
    /// We want the navigation stuff
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    /// Do da view stuff
    override func loadView() {
        super.loadView()
        
        // The size of the content
        let size                    =   asset.pixelSize
        
        // The main view
        view                        =   UIView(frame: CGRect.zero)
        
        // Da scroll view
        scrollView                  =   UIScrollView(frame: CGRect.zero)
        scrollView.minimumZoomScale =   1
        scrollView.maximumZoomScale =   1
        scrollView.zoomScale        =   1
        scrollView.contentOffset    =   CGPoint.zero
        scrollView.contentInset     =   UIEdgeInsets.zero
        scrollView.contentSize      =   size
        scrollView.delegate         =   self
        
        // The asset image view
        assetView                   =   AssetImageView(frame: CGRect(origin: CGPoint.zero, size: size))
        assetView.asset             =   asset
        
        // The asset live view for live animations
        if asset.isLivePhoto {
            let liveView            =   AssetLiveView(frame: assetView.bounds)
            liveView.asset          =   asset
            
            assetView.addSubview(liveView)
            
            self.liveView           =   liveView
        }
        
        // Create the view hiderarchy
        view.addSubview(scrollView)
        scrollView.addSubview(assetView)
        
        // Configure the play button
        if asset.isVideo {
            let largePlayButton                 =   UIButton(frame: CGRect.zero)
            largePlayButton.titleLabel?.font    =   Constants.kLargePlayFont
            largePlayButton.setTitle(FontAwesome.play.rawValue, for: UIControlState.normal)
            largePlayButton.sizeToFit()
            largePlayButton.addTarget(self, action: #selector(play), for: UIControlEvents.touchUpInside)
            view.addSubview(largePlayButton)
            
            self.largePlayButton        =   largePlayButton
        }
    }
    
    /// See if the asset view needs to be centered
    func centerAssetView() {
        let offsetX = max((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5, 0.0);
        let offsetY = max((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5, 0.0);
        
        assetView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX,
                                   y: scrollView.contentSize.height * 0.5 + offsetY);
    }
    
    /// Need to handle this to invalidate the scrollview
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        needsReset = true
        view.setNeedsLayout()
        
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    /// Do the layout stuff
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Full screen scroll view
        scrollView.frame = view.bounds
        
        // First time we have the bounds
        if needsReset {
            
            // Recompute the zoom scales
            let size                    =   asset.pixelSize
            let scale                   =   min(view.bounds.width / size.width, view.bounds.height / size.height)
            scrollView.contentSize      =   size
            scrollView.minimumZoomScale =   min(1,scale)
            scrollView.maximumZoomScale =   max(1,scale)
            scrollView.zoomScale        =   scrollView.minimumZoomScale
            
            // Center the asset view
            centerAssetView()
            
            needsReset = false
        }
        
        // Center the play button
        largePlayButton?.center = CGPoint(x: view.bounds.midX,y: view.bounds.midY)
    }
    
    /// Check for centering the scroll view
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerAssetView()
    }
    
    /// Scroll view delegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return assetView
    }
    
    /// Display info
    @objc func info(sender: UIBarButtonItem) {
        
        // Present information about the current asset
        present(form: AssetDetailsViewController(asset: asset), from: sender)
    }
    
    /// Play the current asset
    @objc func play() {
        
        // Show the player view controller
        present(PlayerViewController(asset: asset), animated: true, completion: {
            
        })
    }
}
