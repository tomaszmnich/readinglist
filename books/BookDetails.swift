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

class BookDetailsViewModel {
    let book: Book
    let title: String
    let authors: String?
    let description: String?
    let readingState: String
    let cover: UIImage
    
    init(book: Book) {
        self.book = book
        title = book.title
        authors = book.authorList
        description = book.bookDescription
        readingState = {
            switch book.readState {
                case .toRead:
                    return "Not Started"
                case .reading:
                    return "Started: \(book.startedReading!.toString(withDateFormat: "dd MMM yyyy"))"
                case .finished:
                    return "Read: \(book.startedReading!.toString(withDateFormat: "dd MMM yyyy")) - \(book.finishedReading!.toString(withDateFormat: "dd MMM yyyy"))"
            }
        }()
        cover = book.coverImage == nil ? #imageLiteral(resourceName: "CoverPlaceholder") : UIImage(data: book.coverImage!)!
    }
}

class BookDetails: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorsLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var readStateLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var readStateContainerView: UIView!
    
    var viewModel: BookDetailsViewModel? {
        didSet {
            guard let viewModel = viewModel else {
                view.isHidden = true
                navigationItem.rightBarButtonItem?.isEnabled = false
                return
            }
            
            view.isHidden = false
            navigationItem.rightBarButtonItem?.isEnabled = true
            titleLabel.text = viewModel.title
            authorsLabel.text = viewModel.authors
            descriptionTextView.text = viewModel.description
            readStateLabel.text = viewModel.readingState
            imageView.image = viewModel.cover
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        readStateContainerView.layer.borderColor = UIColor.lightGray.cgColor
        view.backgroundColor = UIColor.white
        
        if let uiImage = imageView.image,
            let imageViewHeight = (imageView.constraints.filter{$0.firstAttribute == .height}).first?.constant,
            let widthConstraint = (imageView.constraints.filter{$0.firstAttribute == .width}).first {
            widthConstraint.constant = (imageViewHeight / uiImage.size.height) * uiImage.size.width
        }

        descriptionTextView.textContainer.lineBreakMode = .byTruncatingTail
        descriptionTextView.textContainer.lineFragmentPadding = 0
        descriptionTextView.textContainerInset = UIEdgeInsets.zero
        
        appDelegate.booksStore.addSaveObserver(self, selector: #selector(bookChanged(_:)))
    }
    
    @objc private func bookChanged(_ notification: Notification) {
        guard let viewModel = viewModel, let userInfo = (notification as NSNotification).userInfo else { return }
        
        if let updatedObjects = userInfo[NSUpdatedObjectsKey] as? NSSet, updatedObjects.contains(viewModel.book) {
            // If the book was updated, update this page.
            self.viewModel = BookDetailsViewModel(book: viewModel.book)
        }
        else if let deletedObjects = userInfo[NSDeletedObjectsKey] as? NSSet, deletedObjects.contains(viewModel.book) {
            // If the book was deleted, set our book to nil and update this page
            self.viewModel = nil

            // Pop back to the book table if necessary
            appDelegate.splitViewController.masterNavigationController.popToRootViewController(animated: false)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navController = segue.destination as? UINavigationController
        if let editBookController = navController?.viewControllers.first as? EditBook {
            editBookController.bookToEdit = viewModel?.book
        }
        else if let changeReadState = navController?.viewControllers.first as? EditReadState {
            changeReadState.bookToEdit = viewModel?.book
        }
    }

    override var previewActionItems: [UIPreviewActionItem] {
        get {
            guard let book = viewModel?.book else { return [UIPreviewActionItem]() }
            
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
