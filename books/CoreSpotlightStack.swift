//
//  SpotlightIndexStack.swift
//  books
//
//  Created by Andrew Bennet on 29/03/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import CoreSpotlight
import MobileCoreServices

class CoreSpotlightStack{
    
    var domainIdentifier: String!
    
    init(domainIdentifier: String){
        self.domainIdentifier = domainIdentifier
    }
    
    /**
     Adds the items to the Spotlight index.
     */
    func IndexItems(items: [SpotlightItem]){
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
    
    func DeindexItems(identifiers: [String]){
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
        // Create the searchable item from the spotlight item, and set the expiry to be never
        let searchableItem = CSSearchableItem(uniqueIdentifier: spotlightItem.uniqueIdentifier, domainIdentifier: self.domainIdentifier, attributeSet: spotlightItem.ToAttributeSet())
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
    
    func ToAttributeSet() -> CSSearchableItemAttributeSet{
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = title
        attributeSet.contentDescription = description
        attributeSet.thumbnailData = thumbnailImageData
        return attributeSet
    }
}