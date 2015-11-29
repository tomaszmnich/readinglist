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

    private var modelUrl: NSURL!
    private var sqliteStoreUrl: NSURL!
    
    /**
     Constructs a CoreDataStack which represents the model contained in the .momd file with the specified
     name, for storage in an .sqlite file with the given name (the extension should not be included)
    */
    init(sqliteFileName: String, momdFileName: String){
        self.sqliteStoreUrl = NSFileManager.defaultManager()
            .URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
            .first!.URLByAppendingPathComponent(sqliteFileName + ".sqlite")
        self.modelUrl = NSBundle.mainBundle().URLForResource(momdFileName, withExtension: "momd")!
    }
    
    /// The managed object context
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.persistentStoreCoordinator
        return moc
    }()
    
    /// Creates a new item of the specified type with the provided entity name.
    func createNewItem<T>(entityName: String) -> T {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext) as! T
    }
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.sqliteStoreUrl, options: nil)
        } catch {
            print("Unresolved error adding persistent store: \(error)")
        }
        return coordinator
    }()

    private lazy var managedObjectModel: NSManagedObjectModel = {
        return NSManagedObjectModel(contentsOfURL: self.modelUrl)!
    }()
}