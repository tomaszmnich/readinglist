//
//  Settings.swift
//  books
//
//  Created by Andrew Bennet on 23/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import Foundation

class Settings: UITableViewController {

    @IBOutlet weak var addTestDataCell: UITableViewCell!
    @IBOutlet weak var deleteAllDataCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if !DEBUG
        addTestDataCell.isHidden = true
        #endif
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row == 0 {
            loadTestData()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func loadTestData() {
        
        class IsbnAndReadingInformation {
            var readingInformation: BookReadingInformation
            var isbn: String
            init(isbn: String, readingInfo: BookReadingInformation){
                self.isbn = isbn
                self.readingInformation = readingInfo
            }
        }
        
        // Search for each book and add the result
        let isbns = [
            // fahrenheit 451
            IsbnAndReadingInformation(isbn: "9780006546061", readingInfo: BookReadingInformation.finished(started: Date(dateString: "2016-12-27"), finished: Date(dateString: "2017-01-17"))),
            // keep the aspidistra flying
            IsbnAndReadingInformation(isbn: "9780141183725", readingInfo: BookReadingInformation.finished(started: Date(dateString: "2017-01-17"), finished: Date(dateString: "2017-02-11"))),
            // the noise of time
            IsbnAndReadingInformation(isbn: "9781784703325", readingInfo: BookReadingInformation.finished(started: Date(dateString: "2017-02-11"), finished: Date(dateString: "2017-02-14"))),
            
            // the sellout
            IsbnAndReadingInformation(isbn: "9781786070159", readingInfo: BookReadingInformation.reading(started: Date(dateString: "2017-02-17"))),
            
            // the three body problem
            IsbnAndReadingInformation(isbn: "9781784971571", readingInfo: BookReadingInformation.toRead()),
            // cat's cradle
            IsbnAndReadingInformation(isbn: "9780141189345", readingInfo: BookReadingInformation.toRead()),
            // it can't happen here (not found at present)
            IsbnAndReadingInformation(isbn: "9780241310663", readingInfo: BookReadingInformation.toRead())
        ]
        
        appDelegate.booksStore.deleteAllData()
        
        for isbn in isbns {
            GoogleBooksAPI.get(isbn: isbn.isbn) { metadata, error in
                if let metadata = metadata {
                    appDelegate.booksStore.create(from: metadata, readingInformation: isbn.readingInformation)
                }
            }
        }
    }
}
