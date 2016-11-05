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
    @IBOutlet weak var authorsLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var publicationDate: UILabel!
    @IBOutlet weak var pageCount: UILabel!
    
    @IBOutlet weak var readStateLabel: UILabel!
    @IBOutlet var descriptionHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var moreDescriptionButton: UIButton!
    
    var descriptionConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        // Keep an eye on changes to the book store
        appDelegate.booksStore.addSaveObserver(self, selector: #selector(bookChanged(_:)))
        view.backgroundColor = UIColor.white
        updateUi()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return book != nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navController = segue.destination as! UINavigationController
        if let editBookController = navController.viewControllers.first as? EditBook {
            editBookController.bookToEdit = book
        }
        else if let changeReadState = navController.viewControllers.first as? EditReadState {
            changeReadState.bookToEdit = book
        }
    }
    
    @objc private func bookChanged(_ notification: Notification) {
        guard let currentBook = book, let userInfo = (notification as NSNotification).userInfo else { return }
        
        if let updatedObjects = userInfo[NSUpdatedObjectsKey] as? NSSet, updatedObjects.contains(currentBook) {
            // If the book was updated, update this page
            updateUi()
        }
        else if let deletedObjects = userInfo[NSDeletedObjectsKey] as? NSSet, deletedObjects.contains(currentBook) {
            // If the book was deleted, clear this page, and pop back if necessary
            view.isHidden = true
            book = nil
            appDelegate.splitViewController.masterNavigationController.popToRootViewController(animated: false)
        }
    }
    
    private func updateUi() {
        guard let book = book else { view.isHidden = true; return }

        view.isHidden = false
        titleLabel.text = book.title
        authorsLabel.text = book.authorList
        descriptionLabel.text = book.bookDescription
        imageView.image = UIImage(optionalData: book.coverImage)
        pageCount.text = book.pageCount == nil ? nil : "\(book.pageCount!) pages"
        publicationDate.text = book.publishedDate?.toString(withDateFormat: "dd MMM yyyy")
        
        readStateLabel.text = BookDetails.readStateDescription(for: book)
    }
    
    private static func readStateDescription(for book: Book) -> String {
        if book.readState == .toRead {
            return "Not Started"
        }
        var result = "\(book.startedReading!.toString(withDateFormat: "dd MMM yyyy"))"
        if book.readState == .finished {
            result += " - \(book.finishedReading!.toString(withDateFormat: "dd MMM yyyy"))"
        }
        return result
    }
    
    @IBAction func moreButtonPressed(_ sender: UIButton) {
        if descriptionLabel.constraints.contains(descriptionHeightConstraint) {
            descriptionLabel.removeConstraint(descriptionHeightConstraint)
            moreDescriptionButton.setTitle("Less", for: .normal)
        }
        else {
            descriptionLabel.addConstraint(descriptionHeightConstraint)
            moreDescriptionButton.setTitle("More", for: .normal)
        }
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        get {
            guard let book = book else { return [UIPreviewActionItem]() }
            
            func readStatePreviewAction() -> UIPreviewAction? {
                guard book.readState != .finished else { return nil }
                
                return UIPreviewAction(title: book.readState == .toRead ? "Started" : "Finished", style: .default) {_,_ in
                    book.readState = book.readState == .toRead ? .reading : .finished
                    book.setDate(Date(), forState: book.readState)
                    appDelegate.booksStore.save()
                }
            }
            
            var previewActions = [UIPreviewActionItem]()
            if let readStatePreviewAction = readStatePreviewAction() {
                previewActions.append(readStatePreviewAction)
            }
            previewActions.append(UIPreviewAction(title: "Delete", style: .destructive){_,_ in
                appDelegate.booksStore.delete(book)
            })
            
            return previewActions
        }
    }
}
