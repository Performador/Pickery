//
//  ModalActivityViewController.swift
//  Pickery
//
//  Created by Okan Arikan on 9/26/16.
//
//

import UIKit
import ReactiveSwift

/// Just displays an activity dialog while executing a signal producer
class ModalActivityViewController<T : Any> : UIViewController {
    
    var activityIndicator   :   UIActivityIndicatorView!
    var titleView           :   UILabel!
    var titleString         :   String
    var task                :   SignalProducer<T, NSError>
    
    /// Ctor
    init(title: String, task: SignalProducer<T, NSError>) {
        self.titleString    =   title
        self.task           =   task
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle  =   .overCurrentContext
        modalTransitionStyle    =   .crossDissolve
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Create the view components
    override func loadView() {
        view                            =   UIView(frame: CGRect.zero)
        view.backgroundColor            =   UIColor.black.withAlphaComponent(0.7)
        view.isUserInteractionEnabled   =   false
        
        activityIndicator       =   UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
        activityIndicator.startAnimating()
        
        titleView               =   UILabel(frame: CGRect.zero)
        
        titleView.text          =   titleString
        titleView.numberOfLines =   0
        titleView.textAlignment = .center
        titleView.textColor     =   UIColor.white
        titleView.sizeToFit()
        
        view.addSubview(activityIndicator)
        view.addSubview(titleView)
    }
    
    /// No toolbars please
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setToolbarHidden(true, animated: animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    /// Execute the task here
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Start a spinner
        task
            .observe(on: UIScheduler())
            .on( failed: { error in
                
                // Failed
                self.showError(title: "Error", error: error)
                
            // Done with the task, remove the spinner
            }, terminated: {
                self.dismiss(animated: true) {   
                }
            })
            .start()
    }
    
    /// Hmmm, failed, go back
    override func errorDialogOk() {
        super.errorDialogOk()
        
        self.dismiss(animated: true) { 
            
        }
    }
    
    /// Layout
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        activityIndicator.center    =   CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        titleView.center            =   CGPoint(x: view.bounds.midX, y: activityIndicator.frame.maxY + titleView.intrinsicContentSize.height)
    }
    
}
