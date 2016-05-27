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
        updateUi()
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
    
    func updateUi(){
        titleLabel.text = book?.title
        subtitleLabel.text = book?.subtitle
        authorLabel.text = book?.authorList
        descriptionLabel.text = book?.bookDescription
        pagesLabel.text = book?.pageCount != nil ? "\(book!.pageCount!) pages" : nil
        imageView.image = book?.coverImage != nil ? UIImage(data: book!.coverImage!) : nil
        
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