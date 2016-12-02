//
//  AssetLayout.swift
//  Pickery
//
//  Created by Okan Arikan on 7/18/16.
//
//

import UIKit

/// This class does the asset layout
class AssetLayout : UICollectionViewLayout {
    
    /// The global constants
    struct Constants {
        
        /// The height of the header view
        static let kHeaderHeight    =   AssetsHeaderView.Constants.kFontSize * 2
        static let kHeaderPadding   =   AssetsHeaderView.Constants.kFontSize / 4
        
        /// The height of individual thumbs
        static let kThumbHeight     =   CGFloat(80)
        
        /// Gap between thumbs
        static let kItemSpacing     =   CGFloat(1)
    }
    
    
    /// We compute this in prepareLayout and represents the total content size
    var desiredContentSize = CGSize.zero
    
    /// For each section, this is where store the precomputed layout data
    struct SectionLayoutData {
        
        /// The top Y coordinate for the section
        let topY    :   CGFloat
        
        /// The number of rows of assets we have in this section
        let numRows :   Int
        
        /// For each asset, the layout data (frame)
        let assetRects  :   [ CGRect ]
        
        /// The total height of the section
        var height  :   CGFloat { return    AssetLayout.Constants.kHeaderHeight +
                                            AssetLayout.Constants.kThumbHeight * CGFloat(numRows) +
                                            AssetLayout.Constants.kItemSpacing * CGFloat(numRows - 1) }
        
        /// The bottom Y coordinate of the section
        var bottomY :   CGFloat { return topY + height }
    }
    
    /// Precomputed section layout data
    var sections = [ SectionLayoutData ]()
    
    /// Where we cache IndexPath -> UICollectionViewLayoutAttributes
    let layoutCache = NSCache<NSIndexPath, UICollectionViewLayoutAttributes> ()
    
    /// Layout assets in a row
    ///
    /// - parameter row: The asset records that should be in this row
    /// - parameter collectionView: The parent collection view
    /// - parameter topY: The Y coordinate of the top of the row
    /// - returns: An array of CGRects, one for each asset in the row
    func layoutRow(row:             ArraySlice<Asset>,
                   collectionView:  UICollectionView,
                   topY:            CGFloat) -> [ CGRect ] {
        
        // Compute the desired width if we were to put these assets side by side
        let desiredSpace    =   row.reduce(CGFloat(0)) { (s: CGFloat, record: Asset) -> CGFloat in
            return s + CGFloat(record.aspectRatio) * Constants.kThumbHeight
        }
        
        // Some variables
        let size            =   collectionView.frame.size
        let inset           =   collectionView.contentInset
        let width           =   size.width - inset.left - inset.right
        var leftX           =   inset.left
        let availableSpace  =   width - CGFloat(row.count-1)*Constants.kItemSpacing
        
        // This is the factor by which we need to shrink all assets
        let shrinkage       =   min(1,availableSpace / desiredSpace)
        
        // Map each asset
        return row.map { assetRecord in
            
            // The width we want
            let width       =   shrinkage * Constants.kThumbHeight * CGFloat(assetRecord.aspectRatio)
            
            // The rect we want
            let rect        =   CGRect(x: leftX, y: topY, width: width, height: Constants.kThumbHeight)
            
            // Advance the left
            leftX           +=  width + Constants.kItemSpacing
            
            // Done
            return rect
        }
    }
    
    /// Precompute the layout
    override func prepare() {
        super.prepare()
        
        // Must have a collection view
        guard let collectionView = collectionView,
              let dataSource = collectionView.dataSource as? AssetsDataSource else {
            return
        }
        
        // Compute the available width we have for the thumbnails
        let size    =   collectionView.frame.size
        let inset   =   collectionView.contentInset
        let width   =   size.width - inset.left - inset.right

        // Compute the number of rows needed for each section
        var topY    =   CGFloat(0)
        sections    =   dataSource.galleryData.sections.map { section in
            
            // Count the number of rows in this section
            var numRows         = Int(1)
            var numAssetsInRow  = 0
            var rowTopY         = topY + Constants.kHeaderHeight
            var desiredWidth    = CGFloat(0)
            var rowStartIndex   = Int(0)
            var assetRects      = [ CGRect ]()
            
            // For each asset
            for (index, asset) in section.assets.enumerated() {
                
                // No more space in this row? If so start a new row
                if desiredWidth + CGFloat(numAssetsInRow-1)*Constants.kItemSpacing >= width {
                    
                    // Compute the layout for this row
                    assetRects      +=  layoutRow(row: section.assets[rowStartIndex..<index], collectionView: collectionView, topY: rowTopY)
                    desiredWidth    =   0
                    numAssetsInRow  =   0
                    numRows         +=  1
                    rowTopY         +=  Constants.kItemSpacing + Constants.kThumbHeight
                    rowStartIndex   =   index
                }
                
                // Add asset to the row
                desiredWidth   += Constants.kThumbHeight * CGFloat(asset.aspectRatio)
                numAssetsInRow += 1
            }
            
            // Finish off the last row
            assetRects += layoutRow(row: section.assets[rowStartIndex..<section.assets.count], collectionView: collectionView, topY: rowTopY)
            
            // This is the section layout data
            let sectionLayoutData = SectionLayoutData(topY: topY, numRows: numRows, assetRects: assetRects)
            
            // Advance the top
            topY = sectionLayoutData.bottomY
            
            // Done in the map
            return sectionLayoutData
        }
        
        // Update the desired content size
        desiredContentSize = CGSize(width: size.width, height: topY + inset.bottom)
        
        // Reset the layout cache
        layoutCache.removeAllObjects()
    }
    
    /// Return the desired size
    override var collectionViewContentSize : CGSize {
        return desiredContentSize
    }
    
    /// Compute the layout attributes for an asset
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        // Already cached?
        if let attribs = layoutCache.object(forKey: indexPath as NSIndexPath) {
            return attribs
        } else {
            
            // Need a new one
            let attribs = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            
            attribs.frame = sections[indexPath.section].assetRects[indexPath.row]
            
            layoutCache.setObject(attribs, forKey: indexPath as NSIndexPath)
            
            return attribs
        }
    }
    
    /// Compute the layout attributes for a supplementary view
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        // Must have a collection view
        guard let collectionView = collectionView else {
            return nil
        }
        
        let attribs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
        
        // Set the frame
        attribs.frame = CGRect(x: collectionView.contentInset.left + Constants.kHeaderPadding,
                               y: sections[indexPath.section].topY,
                               width: collectionView.frame.width - collectionView.contentInset.left - collectionView.contentInset.right - 2*Constants.kHeaderPadding,
                               height: Constants.kHeaderHeight)
        return attribs
    }
    
    /// See if a (start,end) range intersects with another (start,end) range
    func rangeIntersects(first: (CGFloat, CGFloat), second: (CGFloat, CGFloat)) -> Bool {
        return first.0 < second.1 && first.1 > second.0
    }
    
    /// Figure out the layout attributes for a rect
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        if collectionView?.dataSource == nil {
            return nil
        }
        
        var attributes = [ UICollectionViewLayoutAttributes ] ()
        
        // For each section that intersects the Y range of the rect
        // (TODO: We can do binary search for performance here)
        for (sectionIndex, section) in sections.enumerated() {
            
            // Intersects the range?
            if rangeIntersects(first: (section.topY,section.bottomY), second: (rect.minY, rect.maxY)) {
                
                if rangeIntersects(first: (section.topY,section.topY+Constants.kHeaderHeight), second: (rect.minY, rect.maxY)) {
                    if let attribs = self.layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: IndexPath(row: 0, section: sectionIndex)) {
                        attributes.append(attribs)
                    }
                }
                
                for (assetIndex,assetRect) in section.assetRects.enumerated() {
                    if rect.intersects(assetRect) {
                        if let attribs = self.layoutAttributesForItem(at: IndexPath(row: assetIndex, section: sectionIndex)) {
                            attributes.append(attribs)
                        }
                    }
                }
            }
        }
        
        return attributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
