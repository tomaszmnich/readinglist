//
//  BookMappingModels.swift
//  books
//
//  Created by Andrew Bennet on 20/08/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import CoreData

class BookMapping_6_7: NSEntityMigrationPolicy {
    
    func copyValue(oldObject: NSManagedObject, newObject: NSManagedObject, key: String) {
        newObject.setValue(oldObject.value(forKey: key), forKey: key)
    }
    
    func copyValues(oldObject: NSManagedObject, newObject: NSManagedObject, keys: String...) {
        for key in keys {
            copyValue(oldObject: oldObject, newObject: newObject, key: key)
        }
    }
    
    func newAuthor(manager: NSMigrationManager, lastName: String, firstNames: String?) -> NSManagedObject {
        let newAuthor = NSEntityDescription.insertNewObject(forEntityName: "Author", into: manager.destinationContext)
        newAuthor.setValue(lastName, forKey: "lastName")
        newAuthor.setValue(firstNames, forKey: "firstNames")
        return newAuthor
    }
    
    func extractAuthorComponents(authorListString: String?) -> [(String, String?)] {
        var components = [(lastName: String, firstNames: String?)]()
        guard let authors = authorListString?.components(separatedBy: ","), authors.count > 0 else { return components }
        
        for authorString in (authors.flatMap{$0.trimming().nilIfWhitespace()}) {
            if let range = authorString.range(of: " ", options: .backwards),
                let lastName = authorString.substring(from: range.upperBound).trimming().nilIfWhitespace() {
                components.append((lastName: lastName,
                                   firstNames: authorString.substring(to: range.upperBound).trimming().nilIfWhitespace()))
            }
            else {
                components.append((lastName: authorString, firstNames: nil))
            }
        }
        return components
    }
    
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        let newBook = NSEntityDescription.insertNewObject(forEntityName: "Book", into: manager.destinationContext)
        
        // Copy easy properties
        copyValues(oldObject: sInstance, newObject: newBook, keys: "title", "isbn13", "googleBooksId", "pageCount", "publicationDate", "bookDescription", "coverImage", "readState", "startedReading", "finishedReading", "notes", "currentPage", "sort", "createdWhen")
        
        // Copy subjects
        let sourceSubjects = (sInstance.value(forKey: "subjects") as! NSOrderedSet).map{$0 as! NSManagedObject}
        let destinationSubjects = manager.destinationInstances(forEntityMappingName: "SubjectToSubject",
                                                               sourceInstances: sourceSubjects)
        newBook.setValue(NSOrderedSet(array: destinationSubjects), forKey: "subjects")
        
        
        // Create authors
        let previousAuthorList = sInstance.value(forKey: "authorList") as! String?
        let newAuthorsComponents = extractAuthorComponents(authorListString: previousAuthorList)
        var newAuthorObjects = [NSManagedObject]()
        for authorComponents in newAuthorsComponents {
            newAuthorObjects.append(newAuthor(manager: manager, lastName: authorComponents.0, firstNames: authorComponents.1))
        }
        newBook.setValue(NSOrderedSet(array: newAuthorObjects), forKey: "authors")
        newBook.setValue(newAuthorsComponents.first?.0, forKey: "firstAuthorLastName")
    }
}
