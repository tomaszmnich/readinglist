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
    private let coreDataStack: CoreDataStack
    private let coreSpotlightStack: CoreSpotlightStack
    
    init(storeType: CoreDataStack.PersistentStoreType) {
        self.coreDataStack = CoreDataStack(momdFileName: "books", persistentStoreType: storeType)
        self.coreSpotlightStack = CoreSpotlightStack(domainIdentifier: productBundleIdentifier)
    }
    
    /// The mapping from a Book to a SpotlightItem
    private func spotlightItem(for book: Book) -> SpotlightItem {
        return SpotlightItem(uniqueIdentifier: book.objectID.uriRepresentation().absoluteString, title: book.title, description: "\(book.finishedReading != nil ? "Completed: " + book.finishedReading!.description + ". " : "")\(book.bookDescription != nil ? book.bookDescription! : "")", thumbnailImageData: book.coverImage)
    }
    
    /**
     Creates a NSFetchedResultsController to retrieve books in the given state.
    */
    func fetchedResultsController(_ initialPredicate: NSPredicate?, initialSortDescriptors: [NSSortDescriptor]?) -> NSFetchedResultsController<Book> {
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
    func get(bookIdUrl: URL) -> Book? {
        let bookObjectUrl = coreDataStack.managedObjectContext.persistentStoreCoordinator!.managedObjectID(forURIRepresentation: bookIdUrl)!
        return coreDataStack.managedObjectContext.object(with: bookObjectUrl) as? Book
    }
    
    /**
     Adds or updates the book in the Spotlight index.
    */
    func updateSpotlightIndex(for book: Book) {
        coreSpotlightStack.updateItems([spotlightItem(for: book)])
    }
    
    /**
     Gets the current maximum sort index in the books store
    */
    func max(attribute: String) -> NSNumber? {
        // Build an expression for the maximum value of the 'sort' attribute
        let expression = NSExpressionDescription()
        expression.name = "max\(attribute)"
        expression.expression = NSExpression(forFunction: "max:", arguments: [NSExpression(forKeyPath: attribute)])
        expression.expressionResultType = NSAttributeType.integer32AttributeType
        
        // Build a fetch request for the above expression
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: bookEntityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.propertiesToFetch = [expression]

        // Execute it. Return nil if an error occurs.
        // TODO: consider making this fail hard
        do {
            if let fetchDictionary = try coreDataStack.managedObjectContext.fetch(fetchRequest) as? Array<Dictionary<String,Any>>,
                let maxSort = fetchDictionary.first?["maxsort"] as? NSNumber {
               return maxSort
            }
            else{
                print("Error determining max sort")
                return nil
            }
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
    func delete(_ book: Book) {
        coreSpotlightStack.deindexItems(withIdentifiers: [book.objectID.uriRepresentation().absoluteString])
        coreDataStack.managedObjectContext.delete(book)
        save()
    }
    
    /**
     Creates a new Book object, populates with the provided metadata, saves the
     object context, and adds the book to the Spotlight index.
    */
    func create(from metadata: BookMetadata, readingInformation: BookReadingInformation) {
        let book: Book = coreDataStack.createNew(entity: bookEntityName)
        book.populate(from: metadata)
        book.populate(from: readingInformation)
        
        // The sort index should be 1 more than our maximum, and only if this book is in the ToRead state
        if readingInformation.readState == .toRead {
            let maxSort = max(attribute: "sort")?.intValue ?? -1
            book.sort = NSNumber(value: maxSort + 1)
        }
        
        save()
        updateSpotlightIndex(for: book)
    }
    
    /**
     Saves the managedObjectContext and suppresses any errors.
    */
    func save() {
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
    func addSaveObserver(_ observer: AnyObject, selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: NSNotification.Name.NSManagedObjectContextDidSave, object: coreDataStack.managedObjectContext)
    }
    
    func deleteAllData() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: bookEntityName)
        fetchRequest.returnsObjectsAsFaults = false
        
        let results = try! coreDataStack.managedObjectContext.fetch(fetchRequest)
        for managedObject in results {
            coreDataStack.managedObjectContext.delete(managedObject as! NSManagedObject)
        }
        save()
    }
}
