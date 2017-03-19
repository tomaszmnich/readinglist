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
     Ordered by read state, sort order, started reading date and then finished reading date
    */
    static let standardSortOrder = [BookPredicate.readStateSort,
                                    BookPredicate.sortIndexSort,
                                    BookPredicate.finishedReadingDescendingSort,
                                    BookPredicate.startedReadingDescendingSort]
    
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
        coreSpotlightStack.updateItems([book.toSpotlightItem()])
    }
    
    /**
     Gets the current maximum sort index in the books store
    */
    func maxSort() -> Int? {
        let fetchRequest = NSFetchRequest<Book>(entityName: self.bookEntityName)
        fetchRequest.fetchLimit = 1
        
        fetchRequest.sortDescriptors = [BookPredicate.sortIndexDescendingSort]
        do {
            let books = try coreDataStack.managedObjectContext.fetch(fetchRequest)
            return books.first?.sort as? Int
        }
        catch {
            print("Error determining max sort")
            return nil
        }
    }
    
    /**
     Returns whether a book with the supplied ISBN currently exists.
    */
    func isbnExists(_ isbn: String) -> Bool {
        let fetchRequest = NSFetchRequest<Book>(entityName: self.bookEntityName)
        fetchRequest.fetchLimit = 1
        
        fetchRequest.predicate = BookPredicate.isbnEqual(isbn: isbn)
        do {
            let books = try coreDataStack.managedObjectContext.fetch(fetchRequest)
            return books.count == 1
        }
        catch {
            print("Error determining whether ISBN exists")
            return false
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
    @discardableResult func create(from metadata: BookMetadata, readingInformation: BookReadingInformation) -> Book {
        let book = coreDataStack.createNew(entity: bookEntityName) as! Book
        book.populate(from: metadata)
        book.populate(from: readingInformation)
        
        // The sort index should be 1 more than our maximum, and only if this book is in the ToRead state
        if readingInformation.readState == .toRead {
            let maxSort = self.maxSort() ?? -1
            book.sort = NSNumber(value: maxSort + 1)
        }
        
        save()
        updateSpotlightIndex(for: book)
        return book
    }
    
    /**
        Updates the provided book with the provided metadata. Saves and reindexes in spotlight.
    */
    func update(book: Book, with metadata: BookMetadata) {
        book.populate(from: metadata)
        save()
        updateSpotlightIndex(for: book)
    }
    
    /**
        Updates the provided book with the provided reading information. Saves and reindexes in spotlight.
     */
    func update(book: Book, with readingInformation: BookReadingInformation) {
        book.populate(from: readingInformation)
        save()
        updateSpotlightIndex(for: book)
    }
    
    /**
     Saves the managedObjectContext and suppresses any errors.
    */
    func save() {
        // TODO: Find a way to make this method private, if possible
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
            delete(managedObject as! Book)
        }
        save()
    }
}
