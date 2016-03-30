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
    func FetchedBooksController(sorters: [BookSortOrder], filters: [BookFilter]) -> NSFetchedResultsController{
        // Wrap the fetch request into a fetched results controller, and return that
        return NSFetchedResultsController(fetchRequest: MakeFetchRequest(sorters, filters: filters),
            managedObjectContext: self.coreDataStack.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
    }
    
    /**
     Gets Books according to the sort order and filters provided.
    */
    func GetBooks(sorters: [BookSortOrder], filters: [BookFilter]) -> [Book]{
        return try! coreDataStack.managedObjectContext.executeFetchRequest(MakeFetchRequest(sorters, filters: filters)) as! [Book]
    }
    
    /**
     Retrieves the specified Book, if it exists.
     */
    func GetBook(objectIdUrl: NSURL) -> Book? {
        let bookObjectUrl = coreDataStack.managedObjectContext.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(objectIdUrl)!
        return coreDataStack.managedObjectContext.objectWithID(bookObjectUrl) as? Book
    }
    
    private func MakeFetchRequest(sorters: [BookSortOrder], filters: [BookFilter]) -> NSFetchRequest {
        let fetchRequest = NSFetchRequest(entityName: bookEntityName)
        
        // Sorting and Filtering are achieved with sortDescriptors and predicates on the fetch request
        fetchRequest.sortDescriptors = sorters.map{ $0.ToSortDescriptor() }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: filters.map{ $0.ToPredicate() })
        
        return fetchRequest;
    }
    
    /**
     Creates a new Book object.
     Does not save the managedObjectContent; does not add the item to the index.
    */
    func CreateBook() -> Book {
        let newBook: Book = coreDataStack.createNewItem(bookEntityName)
        print("New book created with id \(newBook.objectID.URIRepresentation())")
        return newBook
    }
    
    /**
     Adds or updates the book in the Spotlight index.
    */
    func UpdateSpotlightIndex(book: Book) {
        coreSpotlightStack.UpdateItems([CreateSpotlightItemForBook(book)])
    }
    
    /**
     Deletes the given book from the managed object context.
    */
    func DeleteBook(bookToDelete: Book) {
        coreDataStack.managedObjectContext.deleteObject(bookToDelete)
    }
    
    func SaveAndUpdateIndex(modifiedBook: Book){
        Save()
        UpdateSpotlightIndex(modifiedBook)
    }
    
    /**
     Saves the managedObjectContext and suppresses any errors.
    */
    func Save(){
        do {
            try coreDataStack.managedObjectContext.save()
        }
        catch {
            print("Error saving context: \(error)")
        }
    }
}
