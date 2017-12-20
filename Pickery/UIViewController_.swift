//
//  UIViewController_.swift
//  Pickery
//
//  Created by Okan Arikan on 8/1/16.
//
//

import Foundation
import ReactiveSwift
import Eureka

protocol ModalViewController {
    
    /// Called when the user hits ok in an error dialog
    func errorDialogOk()
}

extension UIViewController {
    
    
    
    /// Present a popover if on iPad
    func present(form: FormViewController, from element: AnyObject) {
        
        // If on phone, just push into the nav stack
        if ApplicationState.isPhone {
            navigationController?.pushViewController(form, animated: true)
        } else {
            
            // Configure
            form.modalPresentationStyle     =   .popover
            form.tableView?.backgroundColor =   UIColor.clear
            
            if let presentation = form.popoverPresentationController {
                presentation.barButtonItem  = element as? UIBarButtonItem
                presentation.sourceView     = element as? UIView
            }
            
            // Show it
            present(form, animated: true, completion: {
                
            })
        }
    }
    
    /// Set the title and subtitle
    func set(title: String, subtitle: String) {
        
        // Do we have a UILabel as the titleView?
        if let titleView = navigationItem.titleView as? UILabel {
            
            // Set the attributed text for the title view
            titleView.numberOfLines     =   2
            titleView.attributedText    =   NSAttributedString(string: title, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)]) +
                                            NSAttributedString(string: "\n", attributes: nil) +
                                            NSAttributedString(string: subtitle, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 10)])
            titleView.textAlignment     =   .center
            titleView.sizeToFit()
        }
    }
    
    /// Set the frame and force layout of the subviews
    ///
    /// - parameter frame : The frame of the main view
    func setFrameAndLayout(frame: CGRect) {
        view.frame = frame
        view.layoutIfNeeded()
    }
    
    /// Show an error
    ///
    /// - parameter title : The error title
    /// - parameter error : The error object that contains the info about the error
    func showError(title: String, error: Error) {
        
        // Figure out the type of error
        switch error {
            
        // Ignore user cancelled
        case PickeryError.userCancelled:
            break
        default:
            
            // Log da error
            Logger.error(error: error)
            
            // The text we want to show
            let errorString         =   (error as? PickeryError)?.description ?? (error as NSError).displayString
            
            // The alert controller that will show it
            let alertController     =   UIAlertController(title: title, message: errorString, preferredStyle: .alert)
            
            // Just show an OK button
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) in
                
                (self as? ModalViewController)?.errorDialogOk()
            }))
            
            // Show
            present(alertController, animated: true, completion: {
            })
        }
    }
    
    /// Run an asynchronous task and monitor the errors
    ///
    /// - parameter title : The title for the task
    /// - parameter task : The signal producer that encapsulates the task
    func runTask<T>(title: String, task: SignalProducer<T, NSError>) {
        
        present(ModalActivityViewController(title: title, task: task), animated: true) { 
            
        }
    }
}
