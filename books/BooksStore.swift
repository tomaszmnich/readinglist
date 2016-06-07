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
    func GetMaxSort() -> Int32? {
        let fetchRequest = NSFetchRequest(entityName: bookEntityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.resultType = .DictionaryResultType

        let expression = NSExpressionDescription()
        expression.name = "maxSort"
        expression.expression = NSExpression(forFunction: "max:", arguments: [NSExpression(forKeyPath: "sort")])
        expression.expressionResultType = NSAttributeType.Integer32AttributeType
        fetchRequest.propertiesToFetch = [expression]

        if let results = try? coreDataStack.managedObjectContext.executeFetchRequest(fetchRequest) {
            return results.first as? Int32
        }
        else {
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
        book.Populate(metadata, readingInformation: readingInformation)
        if readingInformation.readState == .ToRead {
            let maxSort = GetMaxSort()
            book.sort = Int32((maxSort ?? 0) + 1)
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
