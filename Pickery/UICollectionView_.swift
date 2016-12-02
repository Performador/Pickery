//
//  UICollectionView_.swift
//  Pickery
//
//  Created by Okan Arikan on 10/14/16.
//
//

import UIKit

extension UICollectionView {
    
    /// Select bunch of index paths
    var selectedIndexPaths : [ IndexPath ]? {
        get { return indexPathsForSelectedItems }
        set {
            
            // Is the new selection different?
            if  let currentSelection    = indexPathsForSelectedItems,
                let selection           = newValue,
                currentSelection == selection {
                
                // The selection is the same, nothing needs to be done
            } else {
                
                // Clear the current selection
                if let currentSelection = indexPathsForSelectedItems {
                    for indexPath in currentSelection {
                        deselectItem(at: indexPath, animated: false)
                    }
                }
                
                // Nothing is selected
                assert(indexPathsForSelectedItems?.first == nil)

                // Select the new items
                if let selection = newValue, selection.count > 0 {
                    
                    // Select the new index paths
                    for path in selection {
                        selectItem(at: path, animated: false, scrollPosition: [])
                    }
                    
                    // Sanity check
                    if let currentSelection = indexPathsForSelectedItems {
                        assert(currentSelection == selection)
                    } else {
                        assertionFailure("Was expecting the selection")
                    }
                }
            }
        }
    }
}
