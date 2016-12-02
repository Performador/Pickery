//
//  NavigationController.swift
//  Pickery
//
//  Created by Okan Arikan on 7/31/16.
//
//

import UIKit
import ReactiveSwift

/// Da navigation controller
class NavigationController : UINavigationController, UINavigationControllerDelegate {
    
    /// Set ourself as the delegate
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        
        self.delegate = self
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Handle delivering the push/pop events
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        
        // Notify the controller hierarchy
        if let currentController = topViewController {
            viewController.willPushFrom(controller: currentController, animated: animated)
            currentController.willPushTo(controller: viewController, animated: animated)
        }
        
        super.pushViewController(viewController, animated: animated)
    }
    
    /// Handle delivering the push/pop events
    override func popViewController(animated: Bool) -> UIViewController? {
        if viewControllers.count > 1 {
            if let topViewController = self.topViewController {
                topViewController.willPopTo(controller: viewControllers[viewControllers.count-2], animated: animated)
                viewControllers[viewControllers.count-2].willPopFrom(controller: topViewController, animated: animated)
            }
        }
        
        return super.popViewController(animated: animated)
    }
    
    /// Interactive transition?
    func navigationController(navigationController: UINavigationController, interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
    
    /// Regular transition
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        switch (fromVC, toVC) {
        case (_ as ViewTransitionController, _ as ViewTransitionController):
            return ViewTransition()
        default:
            return nil
        }
    }
}
