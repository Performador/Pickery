//
//  UIColor_.swift
//  Pickery
//
//  Created by Okan Arikan on 11/6/16.
//
//

import UIKit

/// Some color extensions
extension UIColor {
    
    // OK this is really ugly. Is this the best way to see if a color is light?
    var isLight : Bool {
        var hue         : CGFloat = 0
        var saturation  : CGFloat = 0
        var brightness  : CGFloat = 0
        var alpha       : CGFloat = 0
        
        self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return brightness > 0.5
    }
}
