//
//  book.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import Foundation
import CoreData

class Book: NSObject {

    var title: String!
    var author: String!
    
    init(title: String, author: String){
        self.title = title
        self.author = author
    }
}