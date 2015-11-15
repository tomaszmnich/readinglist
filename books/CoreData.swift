//
//  CoreDataStack.swift
//  Coffee Timer
//
//  Created by Andrew Bennet on 08/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import CoreData

class CoreDataStack {
    /*
    
    */
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.persistentStoreCoordinator
        return moc
    }()
    
    /*
    
    */
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let storeURL = self.applicationDocumentsDirectory().URLByAppendingPathComponent("books.sqlite")
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
        } catch {
            print("Unresolved error adding persistent store: \(error)")
        }
        return coordinator
    }()
    
    /*
    
    */
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("books", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    /*
    Saves the ManagedObjectContect to persistent store.
    */
    func save() {
        do {
            try managedObjectContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    /*
    Loads the default set of teas and coffees if and only if this is
    the first time the application has been launched.
    */
    func loadDefaultDataIfFirstLaunch() {
        
        // Check whether the application has been launched on this device before
        let key = "hasLaunchedBefore"
        let launchedBefore = NSUserDefaults.standardUserDefaults().boolForKey(key)
        
        // Save at the end of loading data
        defer {
            save()
        }
        
        // If not, load the data!
        if launchedBefore == false {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: key)
        for i in 0..<3 {
            let book = NSEntityDescription.insertNewObjectForEntityForName("Book", inManagedObjectContext: managedObjectContext) as! Book
            switch i {
            case 0:
                book.author = "Jonathan Franzen"
                book.title = "Purity"
            case 1:
                book.author = "Franz Kafka"
                book.title = "The Trial"
            default: // case 2:
                book.title = "Catch-22"
                book.author = "Joseph Heller"
            }
            book.sortOrder = Int32(i)
        }
        }
    }
    
    /*
    
    */
    private func applicationDocumentsDirectory() -> NSURL {
        return NSFileManager.defaultManager()
            .URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
            .first!
    }
    
}
