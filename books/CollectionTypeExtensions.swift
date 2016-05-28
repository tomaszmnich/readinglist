//
//  CollectionTypeExtensions.swift
//  books
//
//  Created by Andrew Bennet on 28/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

extension CollectionType {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}