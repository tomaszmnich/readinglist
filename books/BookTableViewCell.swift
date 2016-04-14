//
//  BookTableViewCell.swift
//  books
//
//  Created by Andrew Bennet on 31/12/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import UIKit

class BookTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorsLabel: UILabel!
    @IBOutlet weak var bookCover: UIImageView!
    
    func configureFromBook(book: Book?){
        titleLabel.text = book?.title
        authorsLabel.text = book?.authorList
        bookCover.image = book?.coverImage != nil ? UIImage(data: book!.coverImage!) : nil
    }
}
