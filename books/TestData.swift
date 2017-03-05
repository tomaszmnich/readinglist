//
//  TestData.swift
//  books
//
//  Created by Andrew Bennet on 27/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class TestData {
    
    static func loadTestData() {
        
        // Search for each book and add the result
        for bookIndex in 0...1000 {
            let bookMetatdata = BookMetadata()
            bookMetatdata.title = "Book Number \(bookIndex)"
            bookMetatdata.authorList = "Bennet, A.J."
            bookMetatdata.coverImage = UIImagePNGRepresentation(UIImage.fromColor(color: getRandomColor()))
            
            let readingInfo = BookReadingInformation()
            let randomNumber = drand48()
            if randomNumber < 0.005 {
                readingInfo.readState = .reading
                readingInfo.startedReading = Date()
            }
            else if randomNumber < 0.5 {
                readingInfo.readState = .toRead
            }
            else {
                readingInfo.readState = .finished
                readingInfo.startedReading = Date()
                readingInfo.finishedReading = Date()
            }
            appDelegate.booksStore.create(from: bookMetatdata, readingInformation: readingInfo)
        }
    }
    
    static func getRandomColor() -> UIColor{
        let randomRed = CGFloat(drand48())
        let randomGreen = CGFloat(drand48())
        let randomBlue = CGFloat(drand48())
        
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
}

extension UIImage {
    static func fromColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
