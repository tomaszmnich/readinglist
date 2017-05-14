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
    let readingLog: String
    let information: String?
    let cover: UIImage
    
    init(book: Book) {
        self.book = book
        
        var mutableInformation = ""
        if book.publicationDate != nil {
            mutableInformation = "Published \(book.publicationDate!.toString(withDateStyle: .medium))"
        }
        if book.pageCount != nil && book.publicationDate != nil {
            mutableInformation += "\n"
        }
        if book.pageCount != nil {
            mutableInformation += "\(book.pageCount!) pages"
        }
        information = mutableInformation.isEmpty ? nil : mutableInformation
        
        switch book.readState {
        case .toRead:
            readingLog = "To Read 📚"
            break
        case .reading:
            readingLog = "Currently Reading 📖\nStarted \(book.startedReading!.toShortPrettyString(fullMonth: true))"
            break
        case .finished:
            let sameDay = book.startedReading!.startOfDay() == book.finishedReading!.startOfDay()
            readingLog = "Finished 🎉\n\(book.startedReading!.toShortPrettyString(fullMonth: true))"
                + (sameDay ? "" : " - \(book.finishedReading!.toShortPrettyString(fullMonth: true))")
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
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorsLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var changeReadState: BorderedButton!
    @IBOutlet weak var informationLabel: UILabel!
    @IBOutlet weak var readingLogLabel: UILabel!
    @IBOutlet weak var informationHeaderContraint: NSLayoutConstraint!
    @IBOutlet weak var readingLogNotes: UILabel!
    @IBOutlet weak var readingLogHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionHeaderHeightConstraint: NSLayoutConstraint!
    
    var viewModel: BookDetailsViewModel? {
        didSet {
            guard let viewModel = viewModel else {
                view.isHidden = true
                navigationItem.rightBarButtonItem?.toggleHidden(hidden: true)
                shareButton.toggleHidden(hidden: true)
                return
            }
            
            view.isHidden = false
            navigationItem.rightBarButtonItem?.toggleHidden(hidden: false)
            shareButton.toggleHidden(hidden: false)
            
            titleLabel.text = viewModel.book.title
            authorsLabel.text = viewModel.book.authorList
            
            informationHeaderContraint.highPriorityIff(viewModel.information == nil)
            informationLabel.text = viewModel.information
            readingLogLabel.text = viewModel.readingLog
            
            descriptionHeaderHeightConstraint.highPriorityIff(viewModel.book.bookDescription == nil)
            descriptionTextView.text = viewModel.book.bookDescription
            
            readingLogHeightConstraint.highPriorityIff(viewModel.book.notes == nil)
            readingLogNotes.text = viewModel.book.notes
            
            imageView.image = viewModel.cover
            
            shareButton.toggleHidden(hidden: viewModel.book.googleBooksId == nil)
            changeReadState.isHidden = viewModel.book.readState == .finished
            switch viewModel.book.readState {
            case .toRead:
                changeReadState.setColor(UIColor.buttonBlue)
                changeReadState.setTitle("Start", for: .normal)
            
            case .reading:
                changeReadState.setColor(UIColor.flatGreen)
                changeReadState.setTitle("Finish", for: .normal)
            case .finished:
                changeReadState.isHidden = true
            }
        }
    }
    
    @IBAction func readStateButtonPressed(_ sender: BorderedButton) {
        guard let viewModel = viewModel else { return }
        let readState = viewModel.book.readState
        guard readState == .toRead || readState == .reading else { return }
        
        let readingInfo: BookReadingInformation
        if readState == .toRead {
            readingInfo = BookReadingInformation.reading(started: Date())
        }
        else {
            readingInfo = BookReadingInformation.finished(started: viewModel.book.startedReading!, finished: Date())
        }
        appDelegate.booksStore.update(book: viewModel.book, withReadingInformation: readingInfo)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white
        
        // Initialise the view, so that by default a blank page is shown.
        // This is required for starting the app in split-screen mode, where this view is
        // shown without any books being selected.
        view.isHidden = true
        navigationItem.rightBarButtonItem?.toggleHidden(hidden: true)
        shareButton.toggleHidden(hidden: true)
        
        if let uiImage = imageView.image,
            let imageViewHeight = (imageView.constraints.filter{$0.firstAttribute == .height}).first?.constant,
            let widthConstraint = (imageView.constraints.filter{$0.firstAttribute == .width}).first {
            widthConstraint.constant = (imageViewHeight / uiImage.size.height) * uiImage.size.width
        }
/*
        descriptionTextView.textContainer.lineBreakMode = .byTruncatingTail
        descriptionTextView.textContainer.lineFragmentPadding = 0
        descriptionTextView.textContainerInset = UIEdgeInsets.zero
*/
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
    
    @IBAction func editPressed(_ sender: UIBarButtonItem) {
        let optionsAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        optionsAlert.addAction(UIAlertAction(title: "Edit Reading Log", style: .default) { [unowned self] _ in
            self.performSegue(withIdentifier: "editReadStateSegue", sender: self)
        })
        optionsAlert.addAction(UIAlertAction(title: "Edit Book Details", style: .default){ [unowned self] _ in
            self.performSegue(withIdentifier: "editBookSegue", sender: self)
        })
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // For iPad, set the popover presentation controller's source
        if let popPresenter = optionsAlert.popoverPresentationController {
            popPresenter.barButtonItem = sender
        }
        
        self.present(optionsAlert, animated: true, completion: nil)
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
    
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        guard let googleBooksId = viewModel?.book.googleBooksId else { return }
        
        let optionsAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        optionsAlert.addAction(UIAlertAction(title: "Open on Google Books", style: .default) { _ in
            UIApplication.shared.openURL(GoogleBooks.Request.webpage(googleBooksId).url)
        })
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // For iPad, set the popover presentation controller's source
        if let popPresenter = optionsAlert.popoverPresentationController {
            popPresenter.barButtonItem = sender
        }
        
        self.present(optionsAlert, animated: true, completion: nil)
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
