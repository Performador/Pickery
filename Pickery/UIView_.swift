//
//  UIView_.swift
//  Pickery
//
//  Created by Okan Arikan on 8/27/16.
//
//

import UIKit

extension UIView {
    
    /// Some layout helpers...
    
    var viewSize : CGSize {
        get {   return self.frame.size  }
        set {   self.frame = CGRect(x: self.center.x - newValue.width*0.5,y: self.center.y - newValue.height*0.5,width: self.viewSize.width,height: self.viewSize.height)    }
    }
    
    var halfWidth : CGFloat {
        get {   return self.viewSize.width * 0.5    }
    }
    
    var halfHeight : CGFloat {
        get {   return self.viewSize.height * 0.5   }
    }
    
    var viewTopLeft : CGPoint {
        get {   return CGPoint(x: self.frame.minX, y: self.frame.minY)   }
        set {   self.center    =   CGPoint(x: newValue.x + self.halfWidth,     y: newValue.y  + self.halfHeight)   }
    }
    
    var viewTopMiddle : CGPoint {
        get {   return CGPoint(x: self.frame.midX, y: self.frame.minY)   }
        set {   self.center    =   CGPoint(x: newValue.x,                      y: newValue.y  +  self.halfHeight)  }
    }
    
    var viewTopRight : CGPoint {
        get {   return CGPoint(x: self.frame.maxX, y: self.frame.minY)   }
        set {   self.center    =   CGPoint(x: newValue.x - self.halfWidth,     y: newValue.y  +  self.halfHeight)  }
    }
    
    var viewMiddleLeft : CGPoint {
        get {   return CGPoint(x: self.frame.minX, y: self.frame.midY)   }
        set {   self.center    =   CGPoint(x: newValue.x + self.halfWidth,     y: newValue.y)   }
    }
    
    var viewMiddleMiddle : CGPoint {
        get {   return CGPoint(x: self.frame.midX, y: self.frame.midY)   }
        set {   self.center    =   CGPoint(x: newValue.x,                      y: newValue.y)  }
    }
    
    var viewMiddleRight : CGPoint {
        get {   return CGPoint(x: self.frame.maxX, y: self.frame.midY)   }
        set {   self.center    =   CGPoint(x: newValue.x - self.halfWidth,     y: newValue.y)  }
    }
    
    
    var viewBottomLeft : CGPoint {
        get {   return CGPoint(x: self.frame.minX, y: self.frame.maxY)   }
        set {   self.center    =   CGPoint(x: newValue.x + self.halfWidth,     y: newValue.y - self.halfHeight)   }
    }
    
    var viewBottomMiddle : CGPoint {
        get {   return CGPoint(x: self.frame.midX, y: self.frame.maxY)   }
        set {   self.center    =   CGPoint(x: newValue.x,                      y: newValue.y - self.halfHeight)  }
    }
    
    var viewBottomRight : CGPoint {
        get {   return CGPoint(x: self.frame.maxX, y: self.frame.maxY)   }
        set {   self.center    =   CGPoint(x: newValue.x - self.halfWidth,     y: newValue.y - self.halfHeight)  }
    }
    
    var viewMinX : CGFloat {
        get {   return self.frame.minX      }
        set {   self.center = CGPoint(x: newValue + self.halfWidth,y: self.center.y)  }
    }
    
    var viewMidX : CGFloat {
        get {   return self.frame.midX      }
        set {   self.center = CGPoint(x: newValue,y: self.center.y)  }
    }
    
    var viewMaxX : CGFloat {
        get {   return self.frame.maxX      }
        set {   self.center = CGPoint(x: newValue - self.halfWidth,y: self.center.y)  }
    }
    
    var viewMinY : CGFloat {
        get {   return self.frame.minY      }
        set {   self.center = CGPoint(x: self.center.y, y: newValue + self.halfHeight)  }
    }
    
    var viewMidY : CGFloat {
        get {   return self.frame.midY      }
        set {   self.center = CGPoint(x: self.center.y, y: newValue)  }
    }
    
    var viewMaxY : CGFloat {
        get {   return self.frame.maxY      }
        set {   self.center = CGPoint(x: self.center.y, y: newValue - self.halfHeight)  }
    }
    
    /// Get the pixel size
    var pixelSize       :   CGSize {
        let contentScale = window?.screen.nativeScale ?? 1
        return CGSize(width: bounds.width * contentScale, height: bounds.height * contentScale)
    }

    /// Add a subtle shadow to a view
    func addShadow(color: UIColor) {
        layer.shadowColor      =   color.cgColor
        layer.shadowOpacity    =   1.0
        layer.shadowRadius     =   2
        layer.shadowOffset     =   CGSize(width: 0,height: 0)
        layer.shouldRasterize  =   true
    }
    
    /// Overwrite to provide custom snapshot functionality
    func snapshot() -> UIView {
        return snapshotView(afterScreenUpdates: true) ?? UIView(frame: CGRect.zero)
    }
    
    /// Set the frame and force layout of the subviews
    ///
    /// - parameter frame : The frame for the view
    func setFrameAndLayout(frame: CGRect) {
        self.frame = frame
        self.layoutIfNeeded()
    }
}
