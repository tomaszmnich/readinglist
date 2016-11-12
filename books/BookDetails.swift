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
    @IBOutlet weak var descriptionTextView: UITextView!
    
    @IBOutlet weak var readStateContainerView: UIView!
    @IBOutlet weak var readStateLabel: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var moreDescriptionButton: UIButton!
    
    var descriptionHeightConstraint: NSLayoutConstraint!
    
    /// Nil means that a "See more" toggle should not be visible
    var descriptionExpanded: Bool? {
        didSet {
            if descriptionExpanded == true {
                descriptionTextView.removeConstraint(descriptionHeightConstraint)
                moreDescriptionButton.isHidden = false
                moreDescriptionButton.setTitle("See Less", for: .normal)
            }
            else if descriptionExpanded == false {
                descriptionTextView.addConstraint(descriptionHeightConstraint)
                moreDescriptionButton.isHidden = false
                moreDescriptionButton.setTitle("See More", for: .normal)
            }
            else {
                descriptionTextView.removeConstraint(descriptionHeightConstraint)
                moreDescriptionButton.isHidden = true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionHeightConstraint = NSLayoutConstraint(item: descriptionTextView, attribute: .height, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 130.0)
        
        readStateContainerView.layer.borderColor = UIColor.lightGray.cgColor
        view.backgroundColor = UIColor.white
        
        // Weave the description text around the image; get the '...' at the end of the
        // description if it is truncated; remove the padding from the top of the description.
        descriptionTextView.textContainer.exclusionPaths = [UIBezierPath(rect: CGRect(x: imageView.bounds.origin.x, y: imageView.bounds.origin.y, width: imageView.bounds.width + 8, height: imageView.bounds.height))]
        descriptionTextView.textContainer.lineBreakMode = .byTruncatingTail
        descriptionTextView.textContainer.lineFragmentPadding = 0
        descriptionTextView.textContainerInset = UIEdgeInsets.zero
        
        descriptionExpanded = nil
        
        updateUi()
        
        appDelegate.booksStore.addSaveObserver(self, selector: #selector(bookChanged(_:)))
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
            // If the book was updated, update this page.
            updateUi()
        }
        else if let deletedObjects = userInfo[NSDeletedObjectsKey] as? NSSet, deletedObjects.contains(currentBook) {
            // If the book was deleted, set our book to nil and update this page
            book = nil
            updateUi()
            
            // Pop back to the book table if necessary
            appDelegate.splitViewController.masterNavigationController.popToRootViewController(animated: false)
        }
    }
    
    private func updateUi() {
        guard let book = book else {
            view.isHidden = true
            navigationItem.rightBarButtonItem?.isEnabled = false
            return
        }

        // Enable the UI
        view.isHidden = false
        navigationItem.rightBarButtonItem?.isEnabled = true
        
        // Set the values according to the book
        titleLabel.text = book.title
        authorsLabel.text = book.authorList
        descriptionTextView.text = book.bookDescription
        readStateLabel.text = BookDetails.readStateDescription(for: book)
        
        if let uiImage = UIImage(optionalData: book.coverImage) {
            imageView.image = uiImage
        }
        
        updateLayout()
    }
    
    private func updateLayout() {
        view.layoutIfNeeded()
        
        if let uiImage = imageView.image,
            let imageViewHeight = (imageView.constraints.filter{$0.firstAttribute == .height}).first?.constant,
            let widthConstraint = (imageView.constraints.filter{$0.firstAttribute == .width}).first {
            widthConstraint.constant = (imageViewHeight / uiImage.size.height) * uiImage.size.width
        }
        if descriptionExpanded == nil && descriptionTextView.bounds.height > descriptionHeightConstraint.constant {
            descriptionExpanded = false
        }
        if descriptionExpanded == true && descriptionTextView.bounds.height <= descriptionHeightConstraint.constant {
            descriptionExpanded = nil
        }
    }
        
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        updateLayout()
    }
    
    private static func readStateDescription(for book: Book) -> String {
        switch book.readState {
        case .toRead:
            return "Not Started"
        case .reading:
            return "Started: \(book.startedReading!.toString(withDateFormat: "dd MMM yyyy"))"
        case .finished:
            return "Read: \(book.startedReading!.toString(withDateFormat: "dd MMM yyyy")) - \(book.finishedReading!.toString(withDateFormat: "dd MMM yyyy"))"
        }
    }
    
    @IBAction func moreButtonPressed(_ sender: UIButton) {
        guard descriptionExpanded != nil else { return }
            
        descriptionExpanded = !descriptionExpanded!
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        get {
            guard let book = book else { return [UIPreviewActionItem]() }
            
            func readStatePreviewAction() -> UIPreviewAction? {
                guard book.readState != .finished else { return nil }
                
                return UIPreviewAction(title: book.readState == .toRead ? "Start" : "Finish", style: .default) {_,_ in
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
