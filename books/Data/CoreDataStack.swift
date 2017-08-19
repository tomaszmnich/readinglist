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
 Post iOS 10 this could potentially be replaced by NSPersistentContainer
*/
class CoreDataStack {
    
    let managedObjectContext: NSManagedObjectContext
    
    enum PersistentStoreType {
        case sqlite
        case inMemory
    }
    
    /**
     Constructs a CoreDataStack which represents the model contained in the .momd file with the specified
     name, for storage in an .sqlite file with the same name.
    */
    init(momdFileName: String, persistentStoreType: PersistentStoreType) {
        
        // Build the ManagedObjectModel from the momd file
        let managedObjectModelUrl = Bundle.main.url(forResource: momdFileName, withExtension: "momd")!
        let managedObjectModel = NSManagedObjectModel(contentsOf: managedObjectModelUrl)!
        
        // Build a PersistentStoreCoordinator for the ManagedObjectModel
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        // Add the requested persistent store
        let storeUrl: URL? = {
            switch persistentStoreType {
            case .sqlite:
                return FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!.appendingPathComponent("\(momdFileName).sqlite")
            case .inMemory:
                return nil
            }
        }()
        let storeDescriptor: String = {
            switch persistentStoreType {
            case .sqlite:
                return NSSQLiteStoreType
            case .inMemory:
                return NSInMemoryStoreType
            }
        }()
        let persistentStoreOptions = [NSMigratePersistentStoresAutomaticallyOption: true]
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: storeDescriptor, configurationName: nil, at: storeUrl, options: persistentStoreOptions)
        }
        catch {
            print("Unresolved error adding persistent store: \(error)")
        }
        
        // Add the ManagedObjectContext
        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    /// Creates a new item of the specified type with the provided entity name.
    func createNew(entity: String) -> NSManagedObject {
        let newItem = NSEntityDescription.insertNewObject(forEntityName: entity, into: managedObjectContext)
        #if DEBUG
            print("Created new object with ID \(newItem.objectID.uriRepresentation().absoluteString)")
        #endif
        return newItem
    }
}
