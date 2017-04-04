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
     A NSFetchRequest for the Book entities. Has a batch size of 1000 by default.
    */
    private func bookFetchRequest() -> NSFetchRequest<Book> {
        let fetchRequest = NSFetchRequest<Book>(entityName: bookEntityName)
        fetchRequest.fetchBatchSize = 1000
        return fetchRequest
    }
    
    /**
     Creates a NSFetchedResultsController to retrieve books in the given state.
    */
    func fetchedResultsController(_ initialPredicate: NSPredicate?, initialSortDescriptors: [NSSortDescriptor]?) -> NSFetchedResultsController<Book> {
        let fetchRequest = bookFetchRequest()
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
     Whether or not the provided ISBN exists in a book already.
    */
    func isbnExists(_ isbn: String) -> Bool {
        return get(isbn: isbn) != nil
    }
    
    /**
     Returns a book with the specified ISBN, if one exists.
    */
    func get(isbn: String) -> Book? {
        let fetchRequest = NSFetchRequest<Book>(entityName: self.bookEntityName)
        fetchRequest.fetchLimit = 1
        
        fetchRequest.predicate = BookPredicate.isbnEqual(isbn: isbn)
        let books = try? coreDataStack.managedObjectContext.fetch(fetchRequest)
        return books?.first
    }
    
    /**
     Gets all of the books in the store
    */
    func getAllAsync(callback: @escaping (([Book]) -> Void), onFail: @escaping ((Error) -> Void)) {
        do {
            try coreDataStack.managedObjectContext.execute(NSAsynchronousFetchRequest(fetchRequest: self.bookFetchRequest()) {
                callback($0.finalResult ?? [])
            })
        }
        catch {
            print("Error fetching objects asyncronously")
            onFail(error)
        }
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
    private func maxSort() -> Int? {
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
    @discardableResult func create(from metadata: BookMetadata, readingInformation: BookReadingInformation, bookSort: Int? = nil) -> Book {
        let book = coreDataStack.createNew(entity: bookEntityName) as! Book
        book.createdWhen = Date()
        book.populate(from: metadata)
        book.populate(from: readingInformation)
        if readingInformation.readState == .toRead{
            if let specifiedBookSort = bookSort {
                book.sort = NSNumber(value: specifiedBookSort)
            }
            else {
                let maxSort = self.maxSort() ?? -1
                book.sort = NSNumber(value: maxSort + 1)
            }
        }
        
        save()
        updateSpotlightIndex(for: book)
        return book
    }
    
    /**
        Updates the provided book with the provided metadata and reading information (whichever are provided).
        Saves and reindexes in spotlight.
    */
    func update(book: Book, withMetadata metadata: BookMetadata? = nil, withReadingInformation readingInformation: BookReadingInformation? = nil) {
        if let metadata = metadata {
            book.populate(from: metadata)
        }
        if let readingInformation = readingInformation {
            book.populate(from: readingInformation)
        }
        save()
        updateSpotlightIndex(for: book)
    }
    
    /**
     Saves the managedObjectContext and suppresses any errors.
     Is automatically called by the Update and Create functions.
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
    
    /**
     Deletes **all** book objects from the persistent store.
    */
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
