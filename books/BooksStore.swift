//
//  BooksStore.swift
//  books
//
//  Created by Andrew Bennet on 29/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import CoreData
import MobileCoreServices

/// Interfaces with the CoreData storage of Book objects
class BooksStore {
    
    fileprivate let bookEntityName = "Book"
    
    /// The core data stack which will be doing the MOM work
    fileprivate lazy var coreDataStack = CoreDataStack(sqliteFileName: "books", momdFileName: "books")
    
    /// The spotlight stack which will be doing the indexing work
    fileprivate lazy var coreSpotlightStack = CoreSpotlightStack(domainIdentifier: "com.andrewbennet.books")
    
    /// The mapping from a Book to a SpotlightItem
    fileprivate func CreateSpotlightItemForBook(_ book: Book) -> SpotlightItem{
        return SpotlightItem(uniqueIdentifier: book.objectID.uriRepresentation().absoluteString, title: book.title, description: "\(book.finishedReading != nil ? "Completed: " + book.finishedReading!.description + ". " : "")\(book.bookDescription != nil ? book.bookDescription! : "")", thumbnailImageData: book.coverImage)
    }
    
    /**
     Creates a NSFetchedResultsController to retrieve books in the given state.
    */
    func FetchedBooksController(_ initialPredicate: NSPredicate?, initialSortDescriptors: [NSSortDescriptor]?) -> NSFetchedResultsController<Book> {
        let fetchRequest = NSFetchRequest<Book>(entityName: bookEntityName)
        fetchRequest.predicate = initialPredicate
        fetchRequest.sortDescriptors = initialSortDescriptors
        return NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack.managedObjectContext,
            sectionNameKeyPath: BookPredicate.readStateFieldName,
            cacheName: nil)
    }
    
    /**
     Retrieves the specified Book, if it exists.
     */
    func GetBook(_ objectIdUrl: URL) -> Book? {
        let bookObjectUrl = coreDataStack.managedObjectContext.persistentStoreCoordinator!.managedObjectID(forURIRepresentation: objectIdUrl)!
        return coreDataStack.managedObjectContext.object(with: bookObjectUrl) as? Book
    }
    
    /**
     Adds or updates the book in the Spotlight index.
    */
    func UpdateSpotlightIndex(_ book: Book) {
        coreSpotlightStack.UpdateItems([CreateSpotlightItemForBook(book)])
    }
    
    /**
     Gets the current maximum sort index in the books store
    */
    func GetMaxSort() -> NSNumber? {
        // Build an expression for the maximum value of the 'sort' attribute
        let expression = NSExpressionDescription()
        expression.name = "maxSort"
        expression.expression = NSExpression(forFunction: "max:", arguments: [NSExpression(forKeyPath: "sort")])
        expression.expressionResultType = NSAttributeType.integer32AttributeType
        
        // Build a fetch request for the above expression
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: bookEntityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.propertiesToFetch = [expression]

        // Execute it. Return nil if an error occurs.
        do {
            return try coreDataStack.managedObjectContext.fetch(fetchRequest).first as? NSNumber
        }
        catch {
            print("Error fetching maximum sort index: \(error)")
            return nil
        }
    }
    
    /**
     Deletes the given book from the managed object context.
     Deindexes from Spotlight if necessary.
    */
    func DeleteBookAndDeindex(_ bookToDelete: Book) {
        coreSpotlightStack.DeindexItems([bookToDelete.objectID.uriRepresentation().absoluteString])
        coreDataStack.managedObjectContext.delete(bookToDelete)
        Save()
    }
    
    /**
     Creates a new Book object, populates with the provided metadata, saves the
     object context, and adds the book to the Spotlight index.
    */
    func CreateBook(_ metadata: BookMetadata, readingInformation: BookReadingInformation) {
        let book: Book = coreDataStack.createNewItem(bookEntityName)
        book.Populate(metadata)
        book.Populate(readingInformation)
        
        // The sort index should be 1 more than our maximum, and only if this book is in the ToRead state
        if readingInformation.readState == .toRead {
            book.sort = NSNumber(value: (GetMaxSort()?.int32Value ?? -1) + 1 as Int32)
        }
        
        Save()
        UpdateSpotlightIndex(book)
    }
    
    /**
     Saves the managedObjectContext and suppresses any errors.
    */
    func Save() {
        do {
            try coreDataStack.managedObjectContext.save()
        }
        catch {
            print("Error saving context: \(error)")
        }
    }
    
    /**
     Adds the specified object as an observer of saves to the managed object context.
    */
    func AddSaveObserver(_ observer: AnyObject, callbackSelector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: callbackSelector, name: NSNotification.Name.NSManagedObjectContextDidSave, object: coreDataStack.managedObjectContext)
    }
}
