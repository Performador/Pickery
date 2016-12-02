//
//  AssetCell.swift
//  Pickery
//
//  Created by Okan Arikan on 8/31/16.
//
//

import Foundation

/// The protocol that collection view cells that display assets must conform to
protocol AssetCell {
    
    /// The asset that the cell is showing
    var asset:          Asset?                  {   get set }
        
    /// The transition view to use for the cell during a transition
    /// The returned view must be snapshottable
    var transitionView: UIView                  {   get }
}
