//
//  BookDetailsViewController.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import UIKit

class BookDetails: UIViewController {
    
    var book: Book?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewWillAppear(animated: Bool) {
        UpdateUi()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editBookSegue" {
            let navController = segue.destinationViewController as! UINavigationController
            let editBookController = navController.viewControllers.first as! EditBook
            editBookController.bookToEdit = self.book
        }
        else if segue.identifier == "editReadStateSegue" {
            let navController = segue.destinationViewController as! UINavigationController
            let changeReadState = navController.viewControllers.first as! EditReadState
            changeReadState.bookToEdit = self.book
        }
    }
    
    func UpdateUi() {
        
        // Check the book exists
        guard let book = book else {
            ClearUI()
            return
        }

        // Setup the title label
        titleLabel.attributedText = NSMutableAttributedString.byConcatenating(withNewline: true,
            book.title.withTextStyle(UIFontTextStyleTitle1),
            book.subtitle?.withTextStyle(UIFontTextStyleSubheadline),
            book.authorList?.withTextStyle(UIFontTextStyleSubheadline))
        
        // Setup the description label
        let pageCountText: NSAttributedString? = book.pageCount == nil ? nil : "\(book.pageCount!) pages".withTextStyle(UIFontTextStyleCallout)
        let publishedWhenText: NSAttributedString? = book.publishedDate == nil ? nil : "Published \(book.publishedDate!.toLongStyleString())".withTextStyle(UIFontTextStyleCallout)
        descriptionLabel.attributedText = NSMutableAttributedString.byConcatenating(withNewline: true,
            pageCountText, publishedWhenText, book.bookDescription?.withTextStyle(UIFontTextStyleCallout))
        
        // Setup the image
        imageView.image = UIImage(optionalData: book.coverImage)
    }
    
    func ClearUI() {
        titleLabel.attributedText = nil
        descriptionLabel.attributedText = nil
        imageView.image = nil
    }
}