//
//  Book+CoreDataProperties.swift
//  books
//
//  Created by Andrew Bennet on 14/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import Foundation
import CoreData

extension Book{
    @NSManaged var title: String?
    @NSManaged var author: String?
    @NSManaged var sortOrder: Int32
}