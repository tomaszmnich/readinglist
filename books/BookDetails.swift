//
//  BookDetailsViewController.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import UIKit
import CoreData
import CoreSpotlight

class BookDetails: UIViewController {
    
    var book: Book?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        // Keep an eye on changes to the book store
        appDelegate.booksStore.AddSaveObserver(self, callbackSelector: #selector(bookChanged(_:)))
        UpdateUi()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navController = segue.destinationViewController as! UINavigationController
        if segue.identifier == "editBookSegue" {
            let editBookController = navController.viewControllers.first as! EditBook
            editBookController.bookToEdit = self.book
        }
        else if segue.identifier == "editReadStateSegue" {
            let changeReadState = navController.viewControllers.first as! EditReadState
            changeReadState.bookToEdit = self.book
        }
    }
    
    func updateDisplayedBook(newBook: Book) {
        book = newBook
        UpdateUi()
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    @objc private func bookChanged(notification: NSNotification) {
        guard let book = book, let userInfo = notification.userInfo else { return }
        
        if let updatedObjects = userInfo[NSUpdatedObjectsKey] as? NSSet where updatedObjects.containsObject(book) {
            // If the book was updated, update this page
            UpdateUi()
        }
        else if let deletedObjects = userInfo[NSDeletedObjectsKey] as? NSSet where deletedObjects.containsObject(book) {
            // If the book was deleted, clear this page, and pop back if necessary
            ClearUi()
            appDelegate.splitViewController.masterNavigationController.popToRootViewControllerAnimated(false)
        }
    }
    
    private func UpdateUi() {
        guard let book = book else { ClearUi(); return }

        // Setup the title label
        titleLabel.attributedText = NSMutableAttributedString.byConcatenating(withNewline: true,
            book.title.withTextStyle(UIFontTextStyleTitle1),
            book.subtitle?.withTextStyle(UIFontTextStyleSubheadline),
            book.authorList?.withTextStyle(UIFontTextStyleSubheadline))
        
        // Setup the description label
        let pageCountText: NSAttributedString? = book.pageCount == nil ? nil : "\(book.pageCount!) pages.".withTextStyle(UIFontTextStyleCallout)
        let publishedWhenText: NSAttributedString? = book.publishedDate == nil ? nil : "Published \(book.publishedDate!.toLongStyleString())".withTextStyle(UIFontTextStyleCallout)
        descriptionLabel.attributedText = NSMutableAttributedString.byConcatenating(withNewline: true,
            pageCountText, publishedWhenText, book.bookDescription?.withTextStyle(UIFontTextStyleCallout))
        
        // Setup the image
        imageView.image = UIImage(optionalData: book.coverImage)
    }
    
    private func ClearUi() {
        titleLabel.attributedText = nil
        descriptionLabel.attributedText = nil
        imageView.image = nil
    }
}