//
//  ArrayExtensions.swift
//  books
//
//  Created by Andrew Bennet on 14/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

extension Array {
    mutating func moveFrom(source: Int, toDestination destination: Int) {
        let object = removeAtIndex(source)
        insert(object, atIndex: destination)
    }
}