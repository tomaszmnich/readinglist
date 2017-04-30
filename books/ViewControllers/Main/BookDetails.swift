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
    let authors: String
    let description: String?
    let readingLog: NSAttributedString
    let cover: UIImage
    
    init(book: Book) {
        self.book = book
        title = book.title
        authors = book.authorList
        
        var mutableDescription = ""
        if book.publicationDate != nil {
            mutableDescription += book.publicationDate!.toString(withDateStyle: .medium)
        }
        if book.pageCount != nil && book.publicationDate != nil {
            mutableDescription += " • "
        }
        if book.pageCount != nil {
            mutableDescription += String(describing: book.pageCount!) + " pages"
        }
        if !mutableDescription.isEmpty {
            mutableDescription += "\n\n"
        }
        if book.bookDescription != nil {
            mutableDescription += book.bookDescription!
        }
        description = mutableDescription
        
        let headerFont = UIFont.preferredFont(forTextStyle: .body)
        let subheaderFond = UIFont.preferredFont(forTextStyle: .caption1)
        switch book.readState {
        case .toRead:
            readingLog = NSMutableAttributedString("To Read 📚", withFont: headerFont)
            break
        case .reading:
            readingLog = NSMutableAttributedString("Currently Reading 📖\n", withFont: headerFont)
                .chainAppend("Started \(book.startedReading!.toShortPrettyString())", withFont: subheaderFond)
            break
        case .finished:
            readingLog = NSMutableAttributedString("Finished 🎉\n", withFont: headerFont)
                .chainAppend("\(book.startedReading!.toShortPrettyString()) - \(book.finishedReading!.toShortPrettyString())", withFont: subheaderFond)
            break
        }
        
        if let coverData = book.coverImage, let image = UIImage(data: coverData) {
            cover = image
        }
        else {
           cover = #imageLiteral(resourceName: "CoverPlaceholder")
        }
    }
}

class BookDetails: UIViewController {
    
    @IBOutlet weak var readingLogBackground: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorsLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var readingLogHeader: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
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
            readingLogHeader.attributedText = viewModel.readingLog
            imageView.image = viewModel.cover
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white
        readingLogBackground.layer.cornerRadius = 8
        
        // Initialise the view, so that by default a blank page is shown.
        // This is required for starting the app in split-screen mode, where this view is
        // shown without any books being selected.
        view.isHidden = true
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        if let uiImage = imageView.image,
            let imageViewHeight = (imageView.constraints.filter{$0.firstAttribute == .height}).first?.constant,
            let widthConstraint = (imageView.constraints.filter{$0.firstAttribute == .width}).first {
            widthConstraint.constant = (imageViewHeight / uiImage.size.height) * uiImage.size.width
        }

        descriptionTextView.textContainer.lineBreakMode = .byTruncatingTail
        descriptionTextView.textContainer.lineFragmentPadding = 0
        descriptionTextView.textContainerInset = UIEdgeInsets.zero
        
        // Watch for changes in the managed object context
        NotificationCenter.default.addObserver(self, selector: #selector(bookChanged(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: appDelegate.booksStore.managedObjectContext)
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
            
            // Very simple function, exists to shorten the method calls below
            func getBook(previewAction: UIPreviewAction, viewController: UIViewController) -> Book { return book }
            
            var previewActions = [UIPreviewActionItem]()
            if book.readState == .toRead {
                previewActions.append(Book.transistionToReadingStateAction.toUIPreviewAction(getActionableObject: getBook))
            }
            else if book.readState == .reading {
                previewActions.append(Book.transistionToFinishedStateAction.toUIPreviewAction(getActionableObject: getBook))
            }
            previewActions.append(Book.deleteAction.toUIPreviewAction(getActionableObject: getBook))
            return previewActions
        }
    }
}
