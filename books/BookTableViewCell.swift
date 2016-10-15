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
    @IBOutlet weak var bookCover: UIImageView!
    
    typealias ResultType = Book
    
    func configureFrom(_ book: BookMetadata) {
        let titleAndAuthor = NSMutableAttributedString.byConcatenating(
            withNewline: true,
            book.title.withTextStyle(UIFontTextStyle.subheadline),
            book.authorList?.withTextStyle(UIFontTextStyle.caption1))!
        
        titleLabel.attributedText = titleAndAuthor
        bookCover.image = UIImage(optionalData: book.coverImage)
    }
    
    func configureFrom(_ result: Book) {
        let titleAndAuthor = NSMutableAttributedString.byConcatenating(
            withNewline: true,
            result.title.withTextStyle(UIFontTextStyle.subheadline),
            result.authorList?.withTextStyle(UIFontTextStyle.caption1))!
        
        if result.readState == .reading {
            titleAndAuthor.appendNewline()
            titleAndAuthor.append("Started: \(result.startedReading!.toHumanisedString())".withTextStyle(UIFontTextStyle.caption1))
        }
        else if result.readState == .finished {
            titleAndAuthor.appendNewline()
            titleAndAuthor.append("\(result.startedReading!.toHumanisedString()) - \(result.finishedReading!.toHumanisedString())".withTextStyle(UIFontTextStyle.caption1))
        }
        
        titleLabel.attributedText = titleAndAuthor
        bookCover.image = UIImage(optionalData: result.coverImage)
    }
}
