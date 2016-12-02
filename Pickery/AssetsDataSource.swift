//
//  AssetsDataSource.swift
//  Pickery
//
//  Created by Okan Arikan on 6/30/16.
//
//

import Foundation
import UIKit
import Photos

/// The assets data source for collection views
class AssetsDataSource : NSObject, UICollectionViewDataSource {
    
    /// The gallery data we are presenting
    var galleryData     :   GalleryData
    
    /// Ctor
    init(galleryData: GalleryData) {
        self.galleryData    =   galleryData
        
        super.init()
    }
    
    /// Animate the changes to another data source
    ///
    /// FIXME: Implement
    ///
    /// - parameter collectionView: The view displaying this data
    /// - parameter galleryData: The new gallery data we should animate to
    func animatedChangesTo(collectionView: UICollectionView?, galleryData: GalleryData) {
        
        // Overwrite the data
        self.galleryData    =   galleryData
        
        // Reload the collection view if needed
        collectionView?.reloadData()
    }
        
    /// Delegate method
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return galleryData.sections.count
    }
    
    /// Delegate method
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return galleryData.sections[section].assets.count
    }
    
    /// Delegate method
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Create the cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetGridCell.Constants.kReuseIdentifier, for: indexPath)
        
        // Setup the cell
        (cell as? AssetGridCell)?.asset = galleryData.asset(at: indexPath)
        
        // Done
        return cell
    }
    
    /// Delegate method
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: AssetsHeaderView.Constants.kReuseIdentifier, for: indexPath) as! AssetsHeaderView
        
        // Configure the view here
        header.day = galleryData.sections[indexPath.section].day
        
        return header
    }
}
