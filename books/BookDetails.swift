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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navController = segue.destination as! UINavigationController
        if let editBookController = navController.viewControllers.first as? EditBook {
            editBookController.bookToEdit = self.book
        }
        else if let changeReadState = navController.viewControllers.first as? EditReadState {
            changeReadState.bookToEdit = self.book
        }
    }
    
    func updateDisplayedBook(_ newBook: Book) {
        book = newBook
        UpdateUi()
        self.dismiss(animated: false, completion: nil)
    }
    
    @objc fileprivate func bookChanged(_ notification: Notification) {
        guard let book = book, let userInfo = (notification as NSNotification).userInfo else { return }
        
        if let updatedObjects = userInfo[NSUpdatedObjectsKey] as? NSSet , updatedObjects.contains(book) {
            // If the book was updated, update this page
            UpdateUi()
        }
        else if let deletedObjects = userInfo[NSDeletedObjectsKey] as? NSSet , deletedObjects.contains(book) {
            // If the book was deleted, clear this page, and pop back if necessary
            ClearUi()
            appDelegate.splitViewController.masterNavigationController.popToRootViewController(animated: false)
        }
    }
    
    fileprivate func UpdateUi() {
        guard let book = book else { ClearUi(); return }

        // Setup the title label
        titleLabel.attributedText = NSMutableAttributedString.byConcatenating(withNewline: true,
            book.title.withTextStyle(UIFontTextStyle.title1),
            book.subtitle?.withTextStyle(UIFontTextStyle.subheadline),
            book.authorList?.withTextStyle(UIFontTextStyle.subheadline))
        
        // Setup the description label
        let pageCountText: NSAttributedString? = book.pageCount == nil ? nil : "\(book.pageCount!) pages.".withTextStyle(UIFontTextStyle.callout)
        let publishedWhenText: NSAttributedString? = book.publishedDate == nil ? nil : "Published \(book.publishedDate!.toString(withDateStyle: DateFormatter.Style.long))".withTextStyle(UIFontTextStyle.callout)
        descriptionLabel.attributedText = NSMutableAttributedString.byConcatenating(withNewline: true,
            pageCountText, publishedWhenText, book.bookDescription?.withTextStyle(UIFontTextStyle.callout))
        
        // Setup the image
        imageView.image = UIImage(optionalData: book.coverImage)
    }
    
    fileprivate func ClearUi() {
        titleLabel.attributedText = nil
        descriptionLabel.attributedText = nil
        imageView.image = nil
    }
}
