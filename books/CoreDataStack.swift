//
//  CoreDataStack.swift
//  Coffee Timer
//
//  Created by Andrew Bennet on 08/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import CoreData

/**
 Standard CoreData boilerplate code.
 An instance of CoreDataStack can be held by a more specific accessing class.
*/
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
    
    */
    private func applicationDocumentsDirectory() -> NSURL {
        return NSFileManager.defaultManager()
            .URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
            .first!
    }
    
    /// Creates a new item of the specified type with the provided entity name.
    func createNewItem<T>(entityName: String) -> T {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext) as! T
    }
    
}
