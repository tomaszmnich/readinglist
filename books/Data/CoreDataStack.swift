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
    let storeDescriptor: String
    
    enum PersistentStoreType {
        case sqlite
        case inMemory
    }
    
    /**
     Constructs a CoreDataStack which represents the model contained in the .momd file with the specified
     name, for storage in an .sqlite file with the same name.
    */
    init(momDirectoryName: String, persistentStoreType: PersistentStoreType) {
        
        switch persistentStoreType {
        case .sqlite:
            storeDescriptor = NSSQLiteStoreType
        case .inMemory:
            storeDescriptor = NSInMemoryStoreType
        }
        
        let storeUrl: URL? = {
            switch persistentStoreType {
            case .sqlite:
                return FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!.appendingPathComponent("\(momDirectoryName).sqlite")
            case .inMemory:
                return nil
            }
        }()
        
        // Create the MOC
        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Build the ManagedObjectModels from the momd/mom files
        let moms = Bundle.main.urls(forResourcesWithExtension: "mom", subdirectory: "\(momDirectoryName).momd")
        let managedObjectModels = moms!.map{NSManagedObjectModel(contentsOf: $0)!}

        // Build a PersistentStoreCoordinator for the ManagedObjectModel
        if let storeUrl = storeUrl {
            do {
                try migrateStore(at: storeUrl, moms: managedObjectModels)
            }
            catch {
                print("Error migrating store")
            }
        }
        
        managedObjectContext.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModels.last!)
        do {
            try managedObjectContext.persistentStoreCoordinator!.addPersistentStore(ofType: storeDescriptor, configurationName: nil, at: storeUrl, options: nil)
        }
        catch {
            print("Error adding persistent store")
        }
    }
    
    enum MigrationError: Error {
        case IncompatibleModels
    }
    
    // moms: [mom_v1, mom_v2, ... , mom_vN]
    func migrateStore(at storeURL: URL, moms: [NSManagedObjectModel]) throws {
        let idx = try indexOfCompatibleMom(at: storeURL, moms: moms)
        let remaining = moms.suffix(from: (idx + 1))
        guard remaining.count > 0 else {
            return // migration not necessary
        }
        _ = try remaining.reduce(moms[idx]) { smom, dmom in
            try migrateStore(at: storeURL, from: smom, to: dmom)
            return dmom
        }
    }
    
    func indexOfCompatibleMom(at storeURL: URL, moms: [NSManagedObjectModel]) throws -> Int {
        let meta = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL)
        guard let idx = moms.index(where: { $0.isConfiguration(withName: nil, compatibleWithStoreMetadata: meta) }) else {
            throw MigrationError.IncompatibleModels
        }
        return idx
    }
    
    func migrateStore(at storeURL: URL, from smom: NSManagedObjectModel, to dmom: NSManagedObjectModel) throws {
        // Prepare temp directory
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        defer {
            _ = try? FileManager.default.removeItem(at: dir)
        }
        
        // Perform migration
        let mapping = try findMapping(from: smom, to: dmom)
        let destURL = dir.appendingPathComponent(storeURL.lastPathComponent)
        let manager = NSMigrationManager(sourceModel: smom, destinationModel: dmom)
        try autoreleasepool {
            try manager.migrateStore(
                from: storeURL,
                sourceType: storeDescriptor,
                options: nil,
                with: mapping,
                toDestinationURL: destURL,
                destinationType: storeDescriptor,
                destinationOptions: nil
            )
        }
        
        // Replace source store
        let psc = NSPersistentStoreCoordinator(managedObjectModel: dmom)
        try psc.replacePersistentStore(
            at: storeURL,
            destinationOptions: nil,
            withPersistentStoreFrom: destURL,
            sourceOptions: nil,
            ofType: storeDescriptor
        )
    }
    
    func findMapping(from smom: NSManagedObjectModel, to dmom: NSManagedObjectModel) throws -> NSMappingModel {
        if let mapping = NSMappingModel(from: Bundle.allBundles, forSourceModel: smom, destinationModel: dmom) {
            return mapping // found custom mapping
        }
        return try NSMappingModel.inferredMappingModel(forSourceModel: smom, destinationModel: dmom)
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
