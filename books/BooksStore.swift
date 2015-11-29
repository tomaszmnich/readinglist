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
    private lazy var coreDataStack = CoreDataStack()
    
    func fetchedBooksController(bookStateToRetrieve: BookReadState, doFetch: Bool, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController{
        let fetchRequest = NSFetchRequest(entityName: "Book")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "title", ascending: true)
        ]
        fetchRequest.predicate = NSPredicate(format: "readState == \(bookStateToRetrieve.rawValue)")
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        controller.delegate = delegate
        if doFetch {
           let _ = try? controller.performFetch()
        }
        return controller
    }
        
    func newBook() -> Book {
        return coreDataStack.createNewItem("Book")
    }
    
    func newAuthor() -> Author {
        return coreDataStack.createNewItem("Author")
    }
    
    func deleteBook(bookToDelete: Book){
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