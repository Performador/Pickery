//
//  ViewTransition.swift
//  Pickery
//
//  Created by Okan Arikan on 7/25/16.
//
//

import Foundation
import UIKit

/// View controllers that is appropriate for this kind of transition must implement this
protocol ViewTransitionController {
    
    /// The view to focus during the transition (must provide snapshot)
    var transitionView : UIView { get }
    
    /// Your chance to override this to insert a view under a possible overlay
    func insertTransitionView(transitionView: UIView)
}

/// A view transition that zooms into assets
class ViewTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    /// Da constants
    struct Constants {
        static let kTransitionDuration = TimeInterval(0.3)
    }
    
    /// The duration of the transition
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Constants.kTransitionDuration
    }
    
    /// Animate the transition
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        // Capture come variables
        guard let fromVC          =   transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
              let toVC            =   transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
            return
        }
        
        
        // Both need to be asset viewer
        if let fromTransitionController = fromVC as? ViewTransitionController, let toTransitionController = toVC as? ViewTransitionController {
            let containerView       =   transitionContext.containerView
            
            // Disable the interactions temporarily
            fromVC.view.isUserInteractionEnabled  =   false
            toVC.view.isUserInteractionEnabled    =   false
            
            // Insert the view we will transition to
            containerView.insertSubview(toVC.view, aboveSubview: fromVC.view)
            
            // Make sure the view controller that we are transitioning into has been laid out
            toVC.setFrameAndLayout(frame: transitionContext.finalFrame(for: toVC))
            
            // Grab the transition views
            let fromTransitionView  =   fromTransitionController.transitionView
            let toTransitionView    =   toTransitionController.transitionView
            
            // Create the snapshots and figure out where they need to be in the root view
            let fromSnapshot        =   fromTransitionView.snapshot()
            let fromFrame           =   containerView.convert(fromTransitionView.bounds, from: fromTransitionView)
            let toSnapshot          =   toTransitionView.snapshot()
            let toFrame             =   containerView.convert(toTransitionView.bounds, from: toTransitionView)
                        
            // Zero size frames should not be possible
            assert(fromFrame.size != CGSize.zero)
            assert(toFrame.size != CGSize.zero)
                        
            // Hide the asset views
            fromTransitionView.isHidden =   true
            toTransitionView.isHidden   =   true
            
            // Add the snapshot views over everything else
            fromTransitionController.insertTransitionView(transitionView: fromSnapshot)
            toTransitionController.insertTransitionView(transitionView: toSnapshot)
            
            // We will blend it in
            toVC.view.alpha         =   0
            
            // They will both start from fromFrame and transition to toFrame
            fromSnapshot.setFrameAndLayout(frame: fromFrame)
            toSnapshot.setFrameAndLayout(frame: fromFrame)
            
            // Do the actual animation
            UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                                       delay: 0,
                                       usingSpringWithDamping: 1,
                                       initialSpringVelocity: 0,
                                       options: UIViewAnimationOptions(),
                                       animations: {
                
                // Fade the next view in
                toVC.view.alpha     =   1
                
                // Move the frames where they are supposed to go
                fromSnapshot.setFrameAndLayout(frame: toFrame)
                toSnapshot.setFrameAndLayout(frame: toFrame)
            }, completion: { (finished: Bool) in
                
                // Cleanup
                
                // Kill the snapshot views
                fromSnapshot.removeFromSuperview()
                toSnapshot.removeFromSuperview()
                
                // Show the assetViews
                fromTransitionView.isHidden =   false
                toTransitionView.isHidden   =   false
                
                // Re-enable the UI
                fromVC.view.isUserInteractionEnabled  =   true
                toVC.view.isUserInteractionEnabled    =   true
                
                // Done with the transition
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })

        } else {
            assertionFailure("Unable to get the transition view controllers")
        }
    }
}
