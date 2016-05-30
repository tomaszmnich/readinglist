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
    
    func configureFromBook(book: Book?) {
        titleLabel.attributedText = NSMutableAttributedString.byConcatenating(withNewline: true,
            book?.title.withTextStyle(UIFontTextStyleBody),
            book?.authorList?.withTextStyle(UIFontTextStyleCaption1))
        bookCover.image = UIImage(optionalData: book?.coverImage)
    }
}
