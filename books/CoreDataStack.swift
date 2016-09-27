//
//  CoreDataStack.swift
//  books
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

    fileprivate var modelUrl: URL!
    fileprivate var sqliteStoreUrl: URL!
    
    /**
     Constructs a CoreDataStack which represents the model contained in the .momd file with the specified
     name, for storage in an .sqlite file with the given name (the extension should not be included)
    */
    init(sqliteFileName: String, momdFileName: String){
        self.sqliteStoreUrl = FileManager.default
            .urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
            .first!.appendingPathComponent(sqliteFileName + ".sqlite")
        self.modelUrl = Bundle.main.url(forResource: momdFileName, withExtension: "momd")!
    }
    
    /// The managed object context
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.persistentStoreCoordinator
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
    }()
    
    /// Creates a new item of the specified type with the provided entity name.
    func createNewItem<T>(_ entityName: String) -> T where T: NSManagedObject {
        let newItem = NSEntityDescription.insertNewObject(forEntityName: entityName, into: managedObjectContext) as! T
        print("Created new object with ID \(newItem.objectID.uriRepresentation().absoluteString)")
        return newItem
    }
    
    fileprivate lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.sqliteStoreUrl, options: nil)
        }
        catch {
            print("Unresolved error adding persistent store: \(error)")
        }
        return coordinator
    }()

    fileprivate lazy var managedObjectModel: NSManagedObjectModel = {
        return NSManagedObjectModel(contentsOf: self.modelUrl)!
    }()
}
