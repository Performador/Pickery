//
//  AssetViewTransition.swift
//  Pictoria
//
//  Created by Okan Arikan on 7/25/16.
//
//

import Foundation
import UIKit

class AssetViewTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    /// The duration of the transition
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.5
    }
    
    /// Animate the transition
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard  let containerView  =   transitionContext.containerView(),
            let fromVC     =   transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
            let toVC       =   transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) else {
                return
        }
        
        let scaleTransform  =   CGAffineTransformMakeScale(1.5, 1.5)
        
        fromVC.view.userInteractionEnabled  =   false
        toVC.view.userInteractionEnabled    =   false
        //
        //        // Home -> Stops?
        //        if let homeVC = fromVC as? HomePagingViewController, stopsVC = toVC as? StopsTableViewController {
        //            containerView.insertSubview(stopsVC.view, aboveSubview: homeVC.view)
        //
        //            stopsVC.view.frame          =   homeVC.view.frame
        //            stopsVC.view.alpha          =   0
        //            stopsVC.tableView.transform =   scaleTransform
        //
        //            UIView.animateWithDuration(self.transitionDuration(transitionContext), delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: {
        //                stopsVC.view.alpha          =   1
        //                stopsVC.tableView.transform =   CGAffineTransformIdentity
        //                }, completion: { (finished: Bool) in
        //                    fromVC.view.userInteractionEnabled  =   true
        //                    toVC.view.userInteractionEnabled    =   true
        //                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        //            })
        //
        //            // Stops -> Home?
        //        } else if let homeVC = toVC as? HomePagingViewController, stopsVC = fromVC as? StopsTableViewController {
        //            containerView.insertSubview(homeVC.view, belowSubview: stopsVC.view)
        //
        //            homeVC.view.frame = stopsVC.view.frame
        //
        //            let snapshotView            =   stopsVC.tableView.snapshotViewAfterScreenUpdates(true)
        //            stopsVC.view.alpha          =   1
        //            stopsVC.view.insertSubview(snapshotView, belowSubview: stopsVC.tableView)
        //            stopsVC.tableView.hidden    =   true
        //            snapshotView.transform      =   CGAffineTransformIdentity
        //
        //            UIView.animateWithDuration(self.transitionDuration(transitionContext), delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: {
        //                stopsVC.view.alpha      =   0
        //                snapshotView.transform  =   scaleTransform
        //                }, completion: { (finished: Bool) in
        //                    snapshotView.removeFromSuperview()
        //                    stopsVC.tableView.hidden    =   false
        //                    fromVC.view.userInteractionEnabled  =   true
        //                    toVC.view.userInteractionEnabled    =   true
        //                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        //            })
        //            
        //        } else {
        //            assert(false, "WTF, this transition cannot handle more than Home <-> Stops")
        //        }
    }
}
