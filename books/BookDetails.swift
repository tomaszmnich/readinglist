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
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var publishedWhenLabel: UILabel!
    @IBOutlet weak var pagesLabel: UILabel!
    
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
        func formatPublicationDate(date: NSDate?) -> String? {
            if let date = date {
                let formatter = NSDateFormatter()
                formatter.dateStyle = NSDateFormatterStyle.LongStyle
                formatter.timeStyle = .NoStyle
                return "Published: \(formatter.stringFromDate(date))"
            }
            else {
                return nil
            }
        }
        
        if let book = book {
            titleLabel.text = book.title
            subtitleLabel.text = book.subtitle
            authorLabel.text = book.authorList
            descriptionLabel.text = book.bookDescription
            pagesLabel.text = book.pageCount != nil ? "\(book.pageCount!) pages" : nil
            imageView.image = book.coverImage != nil ? UIImage(data: book.coverImage!) : nil
            publishedWhenLabel.text = formatPublicationDate(book.publishedDate)
        }
        else {
            ClearUI()
        }
    }
    
    func ClearUI() {
        titleLabel.text = nil
        subtitleLabel.text = nil
        authorLabel.text = nil
        descriptionLabel.text = nil
        pagesLabel.text = nil
        imageView.image = nil
        publishedWhenLabel.text = nil
    }
}