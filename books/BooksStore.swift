//
//  BooksStore.swift
//  books
//
//  Created by Andrew Bennet on 29/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import CoreData

/// Interfaces with the CoreData storage of Book objects
class BooksStore {
    
    /// The core data stack which will be doing the actual work.
    private lazy var coreDataStack = CoreDataStack(sqliteFileName: "books", momdFileName: "books")
    
    // Store the entity names here.
    private let bookEntityName = "Book"
    private let authorEntityName = "Author"
    
    /**
     Creates a NSFetchedResultsController to retrieve books in the given state.
    */
    func fetchedBooksController(bookStateToRetrieve: BookReadState) -> NSFetchedResultsController{
        let fetchRequest = NSFetchRequest(entityName: self.bookEntityName)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "title", ascending: true)
        ]
        fetchRequest.predicate = NSPredicate(format: "readState == \(bookStateToRetrieve.rawValue)")
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return controller
    }
        
    func newBook() -> Book {
        return coreDataStack.createNewItem(bookEntityName)
    }
    
    func newAuthor() -> Author {
        return coreDataStack.createNewItem(authorEntityName)
    }
    
    func deleteBook(bookToDelete: Book) {
        coreDataStack.managedObjectContext.deleteObject(bookToDelete)
    }
    
    func save(){
        do {
            try coreDataStack.managedObjectContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}