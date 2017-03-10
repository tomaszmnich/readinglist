//
//  BookTableViewCell.swift
//  books
//
//  Created by Andrew Bennet on 31/12/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class BookTableViewCell: UITableViewCell, ConfigurableCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorsLabel: UILabel!
    @IBOutlet weak var bookCover: UIImageView!
    @IBOutlet weak var readTimeLabel: UILabel!

    typealias ResultType = Book
    
    func configureFrom(_ book: BookMetadata) {
        titleLabel.text = book.title
        authorsLabel.text = book.authorList
        bookCover.image = UIImage(optionalData: book.coverImage)
    }

    
    func configureFrom(_ book: Book) {
        titleLabel.text = book.title
        authorsLabel.text = book.authorList
        bookCover.image = UIImage(optionalData: book.coverImage)
        if book.readState == .reading {
            readTimeLabel.text = book.startedReading!.toHumanisedString()
        }
        else if book.readState == .finished {
            readTimeLabel.text = book.finishedReading!.toHumanisedString()
        }
        else {
            readTimeLabel.text = nil
        }
    }
}
