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
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        // Keep an eye on changes to the book store
        appDelegate.booksStore.addSaveObserver(self, selector: #selector(bookChanged(_:)))
        updateUi()
        
        scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0.0, 44.0, 0.0)
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
    
    @objc private func bookChanged(_ notification: Notification) {
        guard let book = book, let userInfo = (notification as NSNotification).userInfo else { return }
        
        if let updatedObjects = userInfo[NSUpdatedObjectsKey] as? NSSet , updatedObjects.contains(book) {
            // If the book was updated, update this page
            updateUi()
        }
        else if let deletedObjects = userInfo[NSDeletedObjectsKey] as? NSSet , deletedObjects.contains(book) {
            // If the book was deleted, clear this page, and pop back if necessary
            clearUi()
            appDelegate.splitViewController.masterNavigationController.popToRootViewController(animated: false)
        }
    }
    
    private func updateUi() {
        guard let book = book else { clearUi(); return }

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
    
    private func clearUi() {
        titleLabel.attributedText = nil
        descriptionLabel.attributedText = nil
        imageView.image = nil
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        get {
            var previewActions = [UIPreviewActionItem]()
            
            if let book = book {
                if book.readState == .toRead {
                    previewActions.append(UIPreviewAction(title: "Started", style: .default) {_,_ in
                        book.readState = .reading
                        book.startedReading = Date()
                        appDelegate.booksStore.save()
                    })
                }
                
                if book.readState == .reading {
                    previewActions.append(UIPreviewAction(title: "Finished", style: .default) {_,_ in
                        book.readState = .finished
                        book.finishedReading = Date()
                        appDelegate.booksStore.save()
                    })
                }
            
                previewActions.append(UIPreviewAction(title: "Delete", style: .destructive){_,_ in
                    appDelegate.booksStore.delete(book)
                })
            }
            return previewActions
        }
    }
}
