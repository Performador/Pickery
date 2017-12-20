//
//  PlayerViewController.swift
//  Pickery
//
//  Created by Okan Arikan on 7/25/16.
//
//

import UIKit
import AVFoundation
import AVKit
import ReactiveSwift

/// Displays the player interface
class PlayerViewController : AVPlayerViewController, AVPlayerViewControllerDelegate {
        
    /// The backend that holds our data
    let asset           :   Asset
    
    /// The aspect ratio of the asset
    var aspectRatio     :   CGFloat { return asset.pixelSize.width / asset.pixelSize.height }
    
    /// The current pixel size
    var pixelSize       :   CGSize { return isViewLoaded ? view.bounds.size : CGSize.zero }
    
    /// Ctor
    init(asset: Asset) {
        self.asset              =   asset
        
        super.init(nibName: nil, bundle: nil)
        
        // Blend the player in
        modalPresentationStyle  =   .overCurrentContext
        modalTransitionStyle    =   .crossDissolve
        
        // Just in case we want
        self.delegate           =   delegate
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// We want the navigation stuff
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        // Request the player item for this asset
        asset.requestPlayerItem(pixelSize: view.bounds.size)
            .observe(on: UIScheduler())
            .on(failed: { error in
                self.showError(title: "Error", error: error)
            }, value: { playerItem in
                self.player = AVPlayer(playerItem: playerItem)
                self.showsPlaybackControls = true
            }).start()
        
    }
}
