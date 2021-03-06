//
//  TabSwitcherView.swift
//  TabSwitcherViewDemo
//
//  Created by Amornchai Kanokpullwad on 7/26/2558 BE.
//  Copyright (c) 2558 zoonref. All rights reserved.
//

import UIKit

class TabSwitcherView: UIView {
    
    let maxNumberOfTabs = 5
    var focusingIndex = -1
    
    private var switchingEnable = true
    var switching: Bool {
        get {
            return switchingEnable
        }
        set {
            setSwithingModeEnable(newValue, fromIndex: focusingIndex)
        }
    }
    
    var collectionView: UICollectionView!
    private let layout = TabSwitcherLayout()
    weak var dataSource: TabSwitcherDataSource?
    
    private var adding = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        collectionView.registerClass(TabViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.backgroundColor = UIColor.clearColor()
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        addSubview(collectionView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
    }
    
    // MARK: 
    
    func setSwithingModeEnable(enable: Bool, fromIndex: Int) {
        // do nothing if there is no tabs, always in swiching mode
        if dataSource?.numberOfTabs() ?? 0 < 0 {
            return
        }
        
        switchingEnable = enable
        let index = enable ? -1 : focusingIndex
        layout.switchToIndex(index)
    }

    func addTab() {
        adding = true
        
        if !switching {
            switching = true
        } else {
            didSwitchingToIndex(-1)
        }
        
    }
    
    // MARK:
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        if !switching {
            for cell in collectionView!.visibleCells() as! [TabViewCell] {
                if collectionView!.indexPathForCell(cell)?.item == focusingIndex {
                    return cell.displayView.hitTest(point, withEvent: event)
                }
            }
        }
        return super.hitTest(point, withEvent: event);
    }
}

// MARK: - CollectionView DataSource & Delegate

extension TabSwitcherView: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = dataSource?.numberOfTabs() ?? 0
        if count == 0 {
            switchingEnable = true
        }
        focusingIndex = -1
        layout.switchToIndex(focusingIndex)
        return count
    }
    
    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell",
            forIndexPath: indexPath) as! TabViewCell
                
        return cell
    }
    
}

extension TabSwitcherView: TabSwitcherLayoutDelegate {
    
    func didSwitchingToIndex(index: Int) {
        if adding && index < 0 {
            let offset = max(collectionView.contentSize.height - collectionView.bounds.size.height, 0)
            
            if offset > 0 {
                collectionView.setContentOffset(
                    CGPointMake(0, offset),
                    animated: true)
            } else {
                scrollViewDidEndScrollingAnimation(collectionView)
            }
        }
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        if adding {
            adding = false
            
            if let count = self.dataSource?.numberOfTabs() where count > 0 {
                collectionView.performBatchUpdates({ () -> Void in
                    self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: count - 1, inSection: 0)])
                }, completion: { (finished) in
                    self.layout.switchToIndex(count - 1)
                    self.switchingEnable = false
                    self.focusingIndex = count - 1
                })
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if switching {
            layout.switchToIndex(indexPath.item)
            switchingEnable = false
            focusingIndex = indexPath.item
        }
    }
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        if indexPath.item == dataSource!.numberOfTabs() - 1 {
            return CGSizeMake(bounds.size.width, bounds.size.height * 0.8)
        }
        
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let count = min(dataSource!.numberOfTabs(), maxNumberOfTabs)
        let height = (bounds.size.height - layout.sectionInset.top - 37) / CGFloat(count)
        return CGSizeMake(bounds.size.width, height)
    }
    
}
