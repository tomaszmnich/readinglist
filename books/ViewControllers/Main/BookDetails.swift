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
import SVProgressHUD
import StoreKit

class BookDetailsViewModel {
    let book: Book
    let readState: String
    let readDates: String
    let cover: UIImage
    
    init(book: Book) {
        self.book = book

        // Read state
        switch book.readState {
        case .toRead:
            readState = "📚 To Read"
            break
        case .reading:
            readState = "📖 Currently Reading"
            break
        case .finished:
            readState = "🎉 Finished"
            break
        }
        
        // Read dates
        var readDatesPieces = [String]()
        if book.readState == .toRead {
            readDatesPieces.append("Added: \(book.createdWhen.toPrettyString(short: false))")
        }
        if let started = book.startedReading {
            readDatesPieces.append("Started: \(started.toPrettyString(short: false))")
        }
        if let finished = book.finishedReading {
            readDatesPieces.append("Finished: \(finished.toPrettyString(short: false))")
        }
        if book.readState != .toRead,
            let dayCount = NSCalendar.current.dateComponents([.day], from: book.startedReading!.startOfDay(), to: (book.finishedReading ?? Date()).startOfDay()).day{
            // Don't bother including the read time if currently reading and started today
            if dayCount <= 0 && book.readState == .finished {
                readDatesPieces.append("Read Time: within a day")
            }
            else if dayCount == 1 {
                readDatesPieces.append("Read Time: 1 day")
            }
            else if dayCount > 1 {
                readDatesPieces.append("Read Time: \(dayCount) days")
            }
        }
        readDates = readDatesPieces.joined(separator: "\n")
        
        if let coverData = book.coverImage, let image = UIImage(data: coverData) {
            cover = image
        }
        else {
           cover = #imageLiteral(resourceName: "CoverPlaceholder")
        }
    }
}

class BookDetails: UIViewController {
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorsLabel: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var readStateLabel: UILabel!
    @IBOutlet weak var readDatesLabel: UILabel!
    @IBOutlet weak var changeReadState: BorderedButton!
    
    @IBOutlet weak var informationHeadingSeparator: UIView!
    @IBOutlet weak var informationStack: UIStackView!
    @IBOutlet weak var pagesLabel: UILabel!
    @IBOutlet weak var publishedLabel: UILabel!
    @IBOutlet weak var subjectsLabel: UILabel!
    
    @IBOutlet weak var descriptionHeadingSeparator: UIView!
    @IBOutlet weak var descriptionStack: UIStackView!
    @IBOutlet weak var descriptionTextView: UILabel!
    
    @IBOutlet weak var readingLogHeadingSeparator: UIView!
    @IBOutlet weak var readingLogStack: UIStackView!
    @IBOutlet weak var readingLogNotes: UILabel!
    
    var viewModel: BookDetailsViewModel? {
        didSet {
            guard let viewModel = viewModel else {
                // Hide the whole view and nav bar buttons
                view.isHidden = true
                navigationItem.rightBarButtonItem?.toggleHidden(hidden: true)
                shareButton.toggleHidden(hidden: true)
                return
            }
            
            // Show the whole view and nav bar buttons
            view.isHidden = false
            navigationItem.rightBarButtonItem?.toggleHidden(hidden: false)
            shareButton.toggleHidden(hidden: false)
            
            titleLabel.text = viewModel.book.title
            authorsLabel.text = viewModel.book.authorList
            
            readStateLabel.text = viewModel.readState
            readDatesLabel.text = viewModel.readDates
            
            let hideInfoStack = viewModel.book.pageCount == nil && viewModel.book.publicationDate == nil && viewModel.book.subjects.count == 0
            informationHeadingSeparator.isHidden = hideInfoStack
            informationStack.isHidden = hideInfoStack
            pagesLabel.isHidden = viewModel.book.pageCount == nil
            pagesLabel.text = "Pages: \(viewModel.book.pageCount ?? 0)"
            publishedLabel.isHidden = viewModel.book.publicationDate == nil
            publishedLabel.text = "Published: \(viewModel.book.publicationDate?.toPrettyString() ?? "")"
            subjectsLabel.isHidden = viewModel.book.subjects.count == 0
            subjectsLabel.text = "Subjects: " + viewModel.book.subjectsArray.map{$0.name}.joined(separator: "; ")
            
            descriptionHeadingSeparator.isHidden = viewModel.book.bookDescription == nil
            descriptionStack.isHidden = viewModel.book.bookDescription == nil
            descriptionTextView.text = viewModel.book.bookDescription
            
            readingLogHeadingSeparator.isHidden = viewModel.book.notes == nil
            readingLogStack.isHidden = viewModel.book.notes == nil
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
        
        UserEngagement.logEvent(.transitionReadState)
        UserEngagement.onReviewTrigger()
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
        optionsAlert.addAction(UIAlertAction(title: "Update from Google Books", style: .default) { _ in
            SVProgressHUD.show(withStatus: "Downloading...")
            GoogleBooks.fetch(googleBooksId: googleBooksId) { [unowned self] fetchResultPage in
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    guard fetchResultPage.result.isSuccess else {
                        SVProgressHUD.showError(withStatus: "Could not update book details")
                        return
                    }
                    appDelegate.booksStore.update(book: self.viewModel!.book, withMetadata: fetchResultPage.result.value!.toBookMetadata())
                }
            }
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
