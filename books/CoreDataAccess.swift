//
//  CoreDataAccess.swift
//  books
//
//  Created by Andrew Bennet on 29/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import CoreData

class CoreDataAccess {
    /// The core data stack which will be doing the actual work.
    private lazy var coreDataStack = CoreDataStack()
    
    private func getFetchedBooksController(bookStateToRetrieve: BookReadState) -> NSFetchedResultsController{
        let fetchRequest = NSFetchRequest(entityName: "Book")
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
    
    func getBooks(booksStateToRetrieve: BookReadState) -> [Book]{
        let fetchedResultsController = getFetchedBooksController(booksStateToRetrieve)
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error fetching: \(error)")
        }
        return fetchedResultsController.sections![0].objects as! [Book]
    }
    
    func newBook() -> Book {
        return newItem("Book")
    }
    
    func newAuthor() -> Author {
        return newItem("Author")
    }
    
    func deleteItem(itemToDelete: NSManagedObject){
        coreDataStack.managedObjectContext.deleteObject(itemToDelete)
    }
    
    func save(){
        coreDataStack.save()
    }
    
    private func newItem<T>(entityName: String) -> T {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self.coreDataStack.managedObjectContext) as! T
    }

    
}