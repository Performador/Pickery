//
//  UIBarButtonItem_.swift
//  Pickery
//
//  Created by Okan Arikan on 10/8/16.
//
//

import UIKit
import FontAwesome_swift

extension UIBarButtonItem {
    
    /// Fontawesome icon constructor
    convenience init(icon: FontAwesome, target: Any, action: Selector) {
        self.init(title: icon.rawValue, style: .plain, target: target, action: action)
        
        setTitleTextAttributes([NSFontAttributeName: UIFont.fontAwesome(ofSize: 24)], for: UIControlState.normal)
    }
}
