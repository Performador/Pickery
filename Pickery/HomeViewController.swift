//
//  HomeViewController.swift
//  Pickery
//
//  Created by Okan Arikan on 11/7/16.
//
//

import Foundation
import ChameleonFramework

/// The entry point for the app
class HomeViewController : UIViewController {
    
    /// Da constants
    struct Constants {
        static let kFontSize        =   CGFloat(12)
        static let kFont            =   UIFont.systemFont(ofSize: Constants.kFontSize)
        static let kFieldHeight     =   CGFloat(30)
        static let kPadding         =   CGFloat(5)
        static let kInsets          =   UIEdgeInsets(top: 10, left: 10, bottom: 20, right: 10)
        static let kTextFieldPadding =  CGFloat(10)
    }
    
    /// The view that holds the background image
    var backgroundView  :   UIImageView!
    
    /// Are we on a light background
    var isBackgroundLight : Bool {
        return UIColor(averageColorFrom: (backgroundImage ?? UIImage())).isLight
    }
    
    /// The foreground text color
    var textColor : UIColor {
        return isBackgroundLight ? UIColor.black : UIColor.white
    }
    
    /// The text shadow color
    var shadowColor : UIColor {
        return isBackgroundLight ? UIColor.white : UIColor.black
    }
    
    /// The go button
    var goButton        :   UILabel!
    
    /// The teaser text
    var teaserText      :   UILabel!
    
    /// Da background image
    //var backgroundImage =   UIImage(named: "Background1")
    let backgroundImage =   UIImage(named: "Background1")
    
    /// Let's see what we have
    override var preferredStatusBarStyle: UIStatusBarStyle { return isBackgroundLight ? .default : .lightContent }
    
    /// Load the view
    override func loadView() {
        view                        =   UIView(frame: CGRect.zero)
        
        // The background image view
        backgroundView              =   UIImageView(image: backgroundImage)
        backgroundView.contentMode  =   .scaleAspectFill
        
        // The teaser text
        teaserText                  =   UILabel(frame: CGRect.zero)
        teaserText.numberOfLines    =   0
        teaserText.textColor        =   textColor
        teaserText.font             =   Appearance.Constants.kLargeFont
        teaserText.textAlignment    =   .right
        teaserText.attributedText   =   NSAttributedString(string: "Hello", attributes: nil) +
                                        NSAttributedString(string: "\n\n") +
                                        NSAttributedString(string: "I'm here to to backup your\nphotos and videos to AWS - S3", attributes: [NSAttributedStringKey.font : Appearance.Constants.kBaseFont])
        teaserText.sizeToFit()
        teaserText.addShadow(color: shadowColor)
                
        goButton                    =   UILabel(frame: CGRect.zero)
        goButton.attributedText     =   NSAttributedString(string: "Credentials", attributes: [NSAttributedStringKey.font : Appearance.Constants.kXLargeFont,
                                                                                               NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle.rawValue])
        goButton.textColor          =   textColor
        goButton.sizeToFit()
        goButton.isUserInteractionEnabled   =   true
        goButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(go)))
        goButton.addShadow(color: shadowColor)
        
        // Setup the view hierarchy
        view.addSubview(backgroundView)
        view.addSubview(goButton)
        view.addSubview(teaserText)
    }
    
    /// Configure the navigation
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The view controller title
        title = "Home"
        
        // No back button text
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    /// Hide the navigation bar
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    /// Text field delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    /// Create/initialize the backend then go to the assets view
    @objc func go() {
        present(form: AWSCredentialsViewController(), from: goButton)
    }
    
    /// Do the view layout
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        backgroundView.frame        =   view.bounds
        
        teaserText.viewTopRight     =   CGPoint(x: view.bounds.width - Constants.kInsets.right,
                                                y: Constants.kInsets.top + 50)
        
        goButton.viewBottomRight    =   CGPoint(x: view.bounds.width - Constants.kInsets.right,
                                                y: view.bounds.height - Constants.kInsets.bottom)
        
    }
}
