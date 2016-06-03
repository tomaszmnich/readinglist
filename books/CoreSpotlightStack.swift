//
//  SpotlightIndexStack.swift
//  books
//
//  Created by Andrew Bennet on 29/03/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import CoreSpotlight
import MobileCoreServices

class CoreSpotlightStack {
    
    var domainIdentifier: String
    var indexingAvailable: Bool
    
    init(domainIdentifier: String) {
        self.domainIdentifier = domainIdentifier
        self.indexingAvailable = CSSearchableIndex.isIndexingAvailable()
    }
    
    /**
     Adds the items to the Spotlight index.
     */
    func IndexItems(items: [SpotlightItem]) {
        guard indexingAvailable else { return }
        
        CSSearchableIndex.defaultSearchableIndex().indexSearchableItems(items.map{CreateSearchableItem($0)}) {
            if $0 != nil {
                print("Error indexing items: \($0!.localizedDescription)")
            }
        }
    }
    
    /**
     Removes the items from the Spotlight index.
    */
    func DeindexItems(items: [SpotlightItem]){
        DeindexItems(items.map{$0.uniqueIdentifier})
    }

    /**
     Removes the items from the Spotlight index.
     */
    func DeindexItems(identifiers: [String]){
        guard indexingAvailable else { return }
        
        CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers(identifiers) {
            if $0 != nil {
                print("Error deindexing items: \($0!.localizedDescription)")
            }
        }
    }
    
    /**
     Updates the items' entries in the Spotlight index.
    */
    func UpdateItems(items: [SpotlightItem]){
        DeindexItems(items)
        IndexItems(items)
    }
    
    private func CreateSearchableItem(spotlightItem: SpotlightItem) -> CSSearchableItem {
        // Create an attribute set from the spotlight item
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = spotlightItem.title
        attributeSet.contentDescription = spotlightItem.description
        attributeSet.thumbnailData = spotlightItem.thumbnailImageData
        
        // Create the searchable item from the spotlight item, and set the expiry to be never
        let searchableItem = CSSearchableItem(uniqueIdentifier: spotlightItem.uniqueIdentifier, domainIdentifier: self.domainIdentifier, attributeSet: attributeSet)
        searchableItem.expirationDate = NSDate.distantFuture()
        return searchableItem
    }
}

class SpotlightItem {
    var title: String
    var description: String?
    var thumbnailImageData: NSData?
    var uniqueIdentifier: String
    
    init(uniqueIdentifier: String, title: String, description: String?, thumbnailImageData: NSData?){
        self.uniqueIdentifier = uniqueIdentifier
        self.title = title
        self.description = description
        self.thumbnailImageData = thumbnailImageData
    }
}