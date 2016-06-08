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
    
    private let bookEntityName = "Book"
    
    /// The core data stack which will be doing the MOM work
    private lazy var coreDataStack = CoreDataStack(sqliteFileName: "books", momdFileName: "books")
    
    /// The spotlight stack which will be doing the indexing work
    private lazy var coreSpotlightStack = CoreSpotlightStack(domainIdentifier: "com.andrewbennet.books")
    
    /// The mapping from a Book to a SpotlightItem
    private func CreateSpotlightItemForBook(book: Book) -> SpotlightItem{
        return SpotlightItem(uniqueIdentifier: book.objectID.URIRepresentation().absoluteString, title: book.title, description: "\(book.finishedReading != nil ? "Completed: " + book.finishedReading!.description + ". " : "")\(book.bookDescription != nil ? book.bookDescription! : "")", thumbnailImageData: book.coverImage)
    }
    
    /**
     Creates a NSFetchedResultsController to retrieve books in the given state.
    */
    func FetchedBooksController(initialPredicate: NSPredicate?, initialSortDescriptors: [NSSortDescriptor]?) -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName: bookEntityName)
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
    func GetBook(objectIdUrl: NSURL) -> Book? {
        let bookObjectUrl = coreDataStack.managedObjectContext.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(objectIdUrl)!
        return coreDataStack.managedObjectContext.objectWithID(bookObjectUrl) as? Book
    }
    
    /**
     Adds or updates the book in the Spotlight index.
    */
    func UpdateSpotlightIndex(book: Book) {
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
        expression.expressionResultType = NSAttributeType.Integer32AttributeType
        
        // Build a fetch request for the above expression
        let fetchRequest = NSFetchRequest(entityName: bookEntityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.resultType = .DictionaryResultType
        fetchRequest.propertiesToFetch = [expression]

        // Execute it. Return nil if an error occurs.
        do {
            return try coreDataStack.managedObjectContext.executeFetchRequest(fetchRequest).first?.valueForKey("maxSort") as? NSNumber
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
    func DeleteBookAndDeindex(bookToDelete: Book) {
        coreSpotlightStack.DeindexItems([bookToDelete.objectID.URIRepresentation().absoluteString])
        coreDataStack.managedObjectContext.deleteObject(bookToDelete)
        Save()
    }
    
    /**
     Creates a new Book object, populates with the provided metadata, saves the
     object context, and adds the book to the Spotlight index.
    */
    func CreateBook(metadata: BookMetadata, readingInformation: BookReadingInformation) {
        let book: Book = coreDataStack.createNewItem(bookEntityName)
        book.Populate(metadata)
        book.Populate(readingInformation)
        
        // The sort index should be 1 more than our maximum, and only if this book is in the ToRead state
        if readingInformation.readState == .ToRead {
            book.sort = NSNumber(int: (GetMaxSort()?.intValue ?? -1) + 1)
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
    func AddSaveObserver(observer: AnyObject, callbackSelector: Selector) {
        NSNotificationCenter.defaultCenter().addObserver(observer, selector: callbackSelector, name: NSManagedObjectContextDidSaveNotification, object: coreDataStack.managedObjectContext)
    }
}
