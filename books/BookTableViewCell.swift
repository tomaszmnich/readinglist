//
//  BookTableViewCell.swift
//  books
//
//  Created by Andrew Bennet on 31/12/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class BookTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bookCover: UIImageView!
    
    func configureFrom(_ book: BookMetadata) {
        let titleAndAuthor = NSMutableAttributedString.byConcatenating(
            withNewline: true,
            book.title.withTextStyle(UIFontTextStyle.subheadline),
            book.authorList?.withTextStyle(UIFontTextStyle.caption1))!
        
        titleLabel.attributedText = titleAndAuthor
        bookCover.image = UIImage(optionalData: book.coverImage)
    }
    
    func configureFromBook(_ book: Book) {
        let titleAndAuthor = NSMutableAttributedString.byConcatenating(
            withNewline: true,
            book.title.withTextStyle(UIFontTextStyle.subheadline),
            book.authorList?.withTextStyle(UIFontTextStyle.caption1))!
        
        if book.readState == .reading {
            titleAndAuthor.appendNewline()
            titleAndAuthor.append("Started: \(book.startedReading!.toHumanisedString())".withTextStyle(UIFontTextStyle.caption1))
        }
        else if book.readState == .finished {
            titleAndAuthor.appendNewline()
            titleAndAuthor.append("\(book.startedReading!.toHumanisedString()) - \(book.finishedReading!.toHumanisedString())".withTextStyle(UIFontTextStyle.caption1))
        }
        
        titleLabel.attributedText = titleAndAuthor
        bookCover.image = UIImage(optionalData: book.coverImage)
    }
}
