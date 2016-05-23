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
    func FetchedBooksController() -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName: bookEntityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "readState", ascending: true), BookSortOrder.Title.ToSortDescriptor()]
        return NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack.managedObjectContext,
            sectionNameKeyPath: "readState",
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
     Creates a new Book object.
     Does not save the managedObjectContent; does not add the item to the index.
    */
    private func CreateBook() -> Book {
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
    func CreateBook(metadata: BookMetadata) {
        let book = CreateBook()
        book.UpdateFromMetadata(metadata)
        Save()
        UpdateSpotlightIndex(book)
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
