//
//  BookDetailsViewController.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class BookDetails: UIViewController {
    
    var book: Book?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var publishedWhenLabel: UILabel!
    @IBOutlet weak var pagesLabel: UILabel!
    
    override func viewWillAppear(animated: Bool) {
        updateUi()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editBookSegue" {
            let navController = segue.destinationViewController as! UINavigationController
            let editBookController = navController.viewControllers.first as! CreateEditBook
            editBookController.bookToEdit = self.book
        }
    }
    
    func switchState(newState: BookReadState) {
        if let book = book {
            book.readState = newState
            appDelegate.booksStore.UpdateSpotlightIndex(book)
            appDelegate.booksStore.Save()
            self.navigationController?.popViewControllerAnimated(true)
        }
    }

    func delete(){
        if let book = book {
            appDelegate.booksStore.DeleteBookAndDeindex(book)
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func updateUi(){
        titleLabel.text = book?.title
        subtitleLabel.text = book?.subtitle
        authorLabel.text = book?.authorList
        descriptionLabel.text = book?.bookDescription
        
        if let pageCount = book?.pageCount{
            pagesLabel.text = "\(pageCount) pages"
        }
        else {
            pagesLabel.text = nil
        }
        if let coverImg = book?.coverImage {
            imageView.image = UIImage(data: coverImg)
        }
        else {
            imageView.image = nil
        }
        if let publicationDate = book?.publishedDate {
            let formatter = NSDateFormatter()
            formatter.dateStyle = NSDateFormatterStyle.LongStyle
            formatter.timeStyle = .NoStyle
            publishedWhenLabel.text = "Published: \(formatter.stringFromDate(publicationDate))"
        }
        else {
            publishedWhenLabel.text = nil
        }
    }
}