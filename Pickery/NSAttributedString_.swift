//
//  NSAttributedString_.swift
//  Pickery
//
//  Created by Okan Arikan on 11/21/16.
//
//

import Foundation

/// Concatenate attributed strings
func + (left: NSAttributedString, right: NSAttributedString) -> NSAttributedString {
    let result = NSMutableAttributedString()
    result.append(left)
    result.append(right)
    return result
}
