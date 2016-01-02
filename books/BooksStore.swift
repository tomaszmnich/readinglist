//
//  BooksStore.swift
//  books
//
//  Created by Andrew Bennet on 29/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import CoreData
import CoreSpotlight
import MobileCoreServices

// Field and Entity name strings should be held in one place: here.
private let bookEntityName = "Book"
private let authorEntityName = "Author"
private let titleFieldName = "title"
private let readStateFieldName = "readState"

/// Interfaces with the CoreData storage of Book objects
class BooksStore {
    
    /// The core data stack which will be doing the actual work.
    private lazy var coreDataStack = CoreDataStack(sqliteFileName: "books", momdFileName: "books")
    
    /**
     Creates a NSFetchedResultsController to retrieve books in the given state.
    */
    func FetchedBooksController(sorters: [BookSortOrder], filter: BookFetchedResultFilterer) -> NSFetchedResultsController{
        // We are fetching Books
        let fetchRequest = NSFetchRequest(entityName: bookEntityName)

        // Convert the BookSortOrders into NSSortDescriptors
        fetchRequest.sortDescriptors = sorters.map{ $0.GetSortDescriptor() }
        
        // Convert the Filterer into a NSPredicate
        fetchRequest.predicate = filter.GetPredicate()

        // Wrap the fetch request into a fetched results controller, and return that
        return NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
    }

    /**
     Retrieves the specified Book, if it exists.
    */
    func GetBook(objectIdUrl: NSURL) -> Book? {
        let bookObjectUrl = coreDataStack.managedObjectContext.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(objectIdUrl)!
        return coreDataStack.managedObjectContext.objectWithID(bookObjectUrl) as? Book
    }
    
    /**
     Creates a new Book object, populates the properties on it with those in the BookMetadata.
     Does not save the managedObjectContent.
    */
    func CreateBook(metadata: BookMetadata) -> Book {
        let newBook: Book = coreDataStack.createNewItem(bookEntityName)
        newBook.Populate(metadata)
        for authorName in metadata.authors{
            let newAuthor: Author = coreDataStack.createNewItem(authorEntityName)
            newAuthor.name = authorName
            newAuthor.authorOf = newBook
        }
        
        return newBook
    }
    
    /**
     Adds the book to the Spotlight index.
    */
    func IndexBookInSpotlight(book: Book){
        // The AttributeSet is the information which will be visible in Spotlight
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = book.title
        attributeSet.contentDescription = book.authorListString
        attributeSet.thumbnailData = book.coverImage
        
        // Create the item to be indexed - the AttributeSet from above and an object identifier
        let item = CSSearchableItem(uniqueIdentifier: book.objectID.URIRepresentation().absoluteString, domainIdentifier: "com.andrewbennet.books", attributeSet: attributeSet)
        item.expirationDate = NSDate.distantFuture()
        
        // Index the item!
        CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([item]) {
            (error: NSError?) -> Void in
            if let error = error {
                print("Indexing error: \(error.localizedDescription)")
            }
            else {
                print("Search item successfully indexed!")
            }
        }
    }
    
    /**
     Deletes the given book from the managed object context.
    */
    func DeleteBook(bookToDelete: Book) {
        coreDataStack.managedObjectContext.deleteObject(bookToDelete)
        
        CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers([bookToDelete.objectID.URIRepresentation().lastPathComponent!]) {
            (error: NSError?) -> Void in
            if let error = error {
                print("Deindexing error: \(error.localizedDescription)")
            }
            else {
                print("Search item successfully removed!")
            }
        }
    }
    
    /**
     Saves the managedObjectContext and suppresses any errors.
    */
    func Save(){
        do {
            try coreDataStack.managedObjectContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

class BookFetchedResultFilterer {
    
    init(titleText: String?, readState: BookReadState?){
        titleFilter = titleText
        readStateFilter = readState
    }
    
    var titleFilter: String?
    private func titlePredicate() -> String? {
        return titleFilter?.isEmpty != false ? nil : "\(titleFieldName) CONTAINS[cd] \"\(titleFilter!)\""
    }
    
    var readStateFilter: BookReadState?
    private func readStatePredicate() -> String? {
        return readStateFilter == nil ? nil : "\(readStateFieldName) == \(readStateFilter!.rawValue)"
    }
    
    func GetPredicate() -> NSPredicate? {
        let predicate1 = titlePredicate()
        let predicate2 = readStatePredicate()
        
        let noPredicates = predicate1 == nil && predicate2 == nil
        let multiplePredicates = predicate1 != nil && predicate2 != nil

        if noPredicates{
            return nil
        }
        if multiplePredicates{
            let predicateString = "(\(predicate1!)) AND (\(predicate2!))"
            print(predicateString)
            return NSPredicate(format: predicateString)
        }
        return NSPredicate(format: predicate1 != nil ? predicate1! : predicate2!)
    }
}

enum BookSortOrder {
    case TitleAscending
    case TitleDescending
    
    var fieldName: String{
        switch self{
        case .TitleAscending, .TitleDescending:
            return titleFieldName
        }
    }
    
    var isAscending: Bool{
        switch self{
        case .TitleAscending:
            return true
        case .TitleDescending:
            return false
        }
    }
    
    func GetSortDescriptor() -> NSSortDescriptor{
        return NSSortDescriptor(key: fieldName, ascending: isAscending)
    }
}