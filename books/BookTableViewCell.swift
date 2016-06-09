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
    
    func configureFromBook(book: Book) {
        let titleAndAuthor = NSMutableAttributedString.byConcatenating(
            withNewline: true,
            book.title.withTextStyle(UIFontTextStyleBody),
            book.authorList?.withTextStyle(UIFontTextStyleCaption1))!
        
        if book.readState == .Reading {
            titleAndAuthor.appendNewline()
            titleAndAuthor.appendAttributedString("Started: \(book.startedReading!.toLongStyleString())".withTextStyle(UIFontTextStyleCaption1))
        }
        else if book.readState == .Finished {
            titleAndAuthor.appendNewline()
            titleAndAuthor.appendAttributedString("\(book.startedReading!.toLongStyleString()) - \(book.finishedReading!.toLongStyleString())".withTextStyle(UIFontTextStyleCaption1))
        }
        
        titleLabel.attributedText = titleAndAuthor
        bookCover.image = UIImage(optionalData: book.coverImage)
    }
}
