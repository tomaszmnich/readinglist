//
//  BookTableViewController.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import CoreData
import CoreSpotlight

class BookTableViewCell: UITableViewCell, ConfigurableCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorsLabel: UILabel!
    @IBOutlet weak var bookCover: UIImageView!
    @IBOutlet weak var readTimeLabel: UILabel!
    
    typealias ResultType = Book
    
    func configureFrom(_ book: BookMetadata) {
        titleLabel.text = book.title
        authorsLabel.text = book.authors
        bookCover.image = UIImage(optionalData: book.coverImage)
    }
    
    func configureFrom(_ book: Book) {
        titleLabel.text = book.title
        authorsLabel.text = book.authorList
        bookCover.image = UIImage(optionalData: book.coverImage) ?? #imageLiteral(resourceName: "CoverPlaceholder")
        if book.readState == .reading {
            readTimeLabel.text = book.startedReading!.toPrettyString()
        }
        else if book.readState == .finished {
            readTimeLabel.text = book.finishedReading!.toPrettyString()
        }
        else {
            readTimeLabel.text = nil
        }
        
        #if DEBUG
            if DebugSettings.showSortNumber {
                titleLabel.text =  "(" + (book.sort?.stringValue ?? "none") + ") " + book.title
            }
        #endif
    }
}

class BookTable: AutoUpdatingTableViewController {
    var resultsController: NSFetchedResultsController<Book>!
    var resultsFilterer: FetchedResultsFilterer<Book, BookPredicateBuilder>!
    var readStates: [BookReadState]!
    var searchController: UISearchController!
    
    var parentSplitViewController: SplitViewController {
        get { return splitViewController as! SplitViewController }
    }
    
    /// Whether there are any books in this screen. Does not consider the impact of searching - there
    /// may be no results on screen due to a search, but this property might still be true.
    var anyBooksExist = true
    
    override func viewDidLoad() {
        
        let readStatePredicate = NSPredicate.Or(readStates.map{BookPredicate.readState(equalTo: $0)})
        
        // Set up the results controller
        resultsController = appDelegate.booksStore.fetchedResultsController(readStatePredicate, initialSortDescriptors: BooksStore.standardSortOrder)
    
        // Assign the table updator, which will deal with changes to the data
        tableUpdater = TableUpdater<Book, BookTableViewCell>(table: tableView, controller: resultsController)
        
        /// The UISearchController to which this UITableViewController will be connected.
        searchController = UISearchController(searchResultsController: nil)
        let predicateBuilder = BookPredicateBuilder(readStatePredicate: readStatePredicate)
        resultsFilterer = FetchedResultsFilterer(uiSearchController: searchController, tableView: self.tableView, fetchedResultsController: resultsController, predicateBuilder: predicateBuilder)
        
        // Search Controller UI decisions
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.returnKeyType = .done
        searchController.searchBar.placeholder = "Your Library"
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.backgroundColor = tableView.backgroundColor!
        searchController.hidesNavigationBarDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
        
        // We will manage the clearing of selections ourselves.
        clearsSelectionOnViewWillAppear = false
        
        // Setting the table footer removes the cell separators.
        tableView.tableFooterView = UIView()
        
        // Set the DZN data set source
        tableView.emptyDataSetSource = self
        
        // The left button should be an edit button
        navigationItem.leftBarButtonItem = editButtonItem

        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Deselect selected rows, so they don't stay highlighted, but only when in non-split mode
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow, !parentSplitViewController.detailIsPresented {
            self.tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
        
        super.viewDidAppear(animated)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        let numberOfSections = super.numberOfSections(in: tableView)
        
        // Remember whether we have any books
        if !resultsFilterer.showingSearchResults {
            let currentlyAnyBooks = numberOfSections != 0
            if currentlyAnyBooks != anyBooksExist {
                anyBooksExist = currentlyAnyBooks
                searchController.searchBar.isHidden = !anyBooksExist
                // If we hide the search bar, we should make sure the keyboard is gone too.
                // This can happen in slightly tenious circumstances - if a user deletes or removes
                // the last book on the screen whilst in a search mode, then dismisses the search, 
                // brings it back, and then dismisses it again.
                if searchController.searchBar.isHidden {
                    DispatchQueue.main.async {
                        self.searchController.searchBar.resignFirstResponder()
                    }
                }
            }
        }

        return numberOfSections
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Turn the section name into a BookReadState and use its description property
        let sectionAsInt = Int32(self.resultsController.sections![section].name)!
        return BookReadState(rawValue: sectionAsInt)!.description
    }
    
    func triggerBookSelection(_ book: Book){
        // There must be a row corresponding to this book
        guard let indexPathOfSelectedBook = self.resultsController.indexPath(forObject: book) else { return }
            
        // Dismiss the search if there is one
        resultsFilterer.dismissSearch()
        
        // Scroll to and select the row
        self.tableView.scrollToRow(at: indexPathOfSelectedBook, at: .none, animated: false)
        self.tableView.selectRow(at: indexPathOfSelectedBook, animated: false, scrollPosition: .none)
        
        // If there is a detail view presented, pop back to the tabbed page.
        if parentSplitViewController.detailIsPresented {
            (parentSplitViewController.displayedDetailViewController as? BookDetails)?.viewModel = BookDetailsViewModel(book: book)
        }
        else{
            // Segue to the details view, with the cell corresponding to the book as the sender
            self.performSegue(withIdentifier: "showDetail", sender: tableView.cellForRow(at: indexPathOfSelectedBook))
        }
        
        // Get rid of any modal controllers (e.g. edit views, etc)
        self.presentedViewController?.dismiss(animated: false, completion: nil)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // No clicking on books in edit mode, even if you force-press
        return !tableView.isEditing
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navWithReadState = segue.destination as? NavWithReadState {
            navWithReadState.readState = readStates.first!
            
            // If this is going to the SearchOnline page, and our sender was Text, prepopulate with that text
            if let searchOnline = navWithReadState.topViewController as? SearchOnline, let searchText = sender as? String {
                searchOnline.initialSearchString = searchText
            }
        }
        if let detailsViewController = (segue.destination as? UINavigationController)?.topViewController as? BookDetails,
            let cell = sender as? UITableViewCell,
            let selectedIndex = self.tableView.indexPath(for: cell) {
         
            detailsViewController.viewModel = BookDetailsViewModel(book: self.resultsController.object(at: selectedIndex))
        }
    }

    @IBAction func addWasPressed(_ sender: UIBarButtonItem) {
    
        func segueAction(title: String, identifier: String) -> UIAlertAction {
            return UIAlertAction(title: title, style: .default){[unowned self] _ in
                self.performSegue(withIdentifier: identifier, sender: self)
            }
        }
        
        let optionsAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        optionsAlert.addAction(segueAction(title: "Scan Barcode", identifier: "scanBarcode"))
        optionsAlert.addAction(segueAction(title: "Search Books", identifier: "searchByText"))
        optionsAlert.addAction(segueAction(title: "Enter Manually", identifier: "addManually"))
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // For iPad, set the popover presentation controller's source
        if let popPresenter = optionsAlert.popoverPresentationController {
            popPresenter.barButtonItem = sender
        }
        
        self.present(optionsAlert, animated: true, completion: nil)
    }
    
    /// Returns the row actions to be used for a book in a given state
    func rowActionsForBookInState(_ readState: BookReadState) -> [UITableViewRowAction] {
        
        func getBookFromIndexPath(rowAction: UITableViewRowAction, indexPath: IndexPath) -> Book {
            return self.resultsController.object(at: indexPath)
        }
        
        // Start with the delete action
        var rowActions = [UITableViewRowAction(style: .destructive, title: "Delete") { [unowned self] rowAction, indexPath in
            
            let bookToDelete = getBookFromIndexPath(rowAction: rowAction, indexPath: indexPath)
            let confirmDeleteAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            // TODO: Can't work out how to setup the popover presentation controller for iPad.
            // Don't bother with the confirm delete alert for iPad
            if confirmDeleteAlert.popoverPresentationController != nil {
                appDelegate.booksStore.deleteBook(bookToDelete)
                UserEngagement.logEvent(.deleteBook)
            }
            else {
                confirmDeleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                confirmDeleteAlert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                    appDelegate.booksStore.deleteBook(bookToDelete)
                })
                self.present(confirmDeleteAlert, animated: true) {
                    UserEngagement.logEvent(.deleteBook)
                }
            }
        }]
        
        // Add the other state change actions where appropriate
        if readState == .toRead {
            let transitionToReading = Book.transistionToReadingStateAction.toUITableViewRowAction(getActionableObject: getBookFromIndexPath)
            transitionToReading.backgroundColor = UIColor.buttonBlue
            rowActions.append(transitionToReading)
        }
        else if readState == .reading {
            let transitionToFinished = Book.transistionToFinishedStateAction.toUITableViewRowAction(getActionableObject: getBookFromIndexPath)
            transitionToFinished.backgroundColor = UIColor.flatGreen
            rowActions.append(transitionToFinished)
        }
        
        #if DEBUG
            if DebugSettings.showCellReloadControl {
                let reloadCell = UITableViewRowAction(style: .default, title: "Reload") {[unowned self] _, indexPath in
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
                reloadCell.backgroundColor = UIColor.gray
                rowActions.append(reloadCell)
            }
        #endif
        
        return rowActions
    }
}

/// DZNEmptyDataSetSource functions
extension BookTable : DZNEmptyDataSetSource {
    

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let titleText: String!
        if resultsFilterer.showingSearchResults {
            titleText = "🔍 No Results"
        }
        else if readStates.contains(.reading) {
            titleText = "📚 To Read"
        }
        else {
            titleText = "🎉 Finished"
        }
        
        return NSAttributedString(string: titleText, attributes: [NSFontAttributeName: UIFont(name: "GillSans", size: 32)!, NSForegroundColorAttributeName: UIColor.gray])
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        if resultsFilterer.showingSearchResults {
            return -scrollView.frame.height / 4 + self.tableView.tableHeaderView!.frame.size.height / 2.0
        }
        else {
            return 0
        }
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let bodyFont = UIFont(name: "GillSans", size: 18)!
        let boldFont = UIFont(name: "GillSans-Semibold", size: 18)!
        
        let descriptionText: NSMutableAttributedString
        if resultsFilterer.showingSearchResults {
            descriptionText = NSMutableAttributedString("Try changing your search, or add a new book by tapping the ", withFont: bodyFont)
                .chainAppend("+", withFont: boldFont)
                .chainAppend(" button above.", withFont: bodyFont)
        }
        else if readStates.contains(.reading) {
            descriptionText = NSMutableAttributedString("Books you add to your ", withFont: bodyFont)
                .chainAppend("To Read", withFont: boldFont)
                .chainAppend(" list, or mark as currently ", withFont: bodyFont)
                .chainAppend("Reading", withFont: boldFont)
                .chainAppend(", will show up here.\n\nAdd a book by tapping the ", withFont: bodyFont)
                .chainAppend("+", withFont: boldFont)
                .chainAppend(" button above.", withFont: bodyFont)
        }
        else {
            descriptionText = NSMutableAttributedString("Books you mark as ", withFont: bodyFont)
                .chainAppend("Finished", withFont: boldFont)
                .chainAppend(" will show up here.\n\nAdd a book by tapping the ", withFont: bodyFont)
                .chainAppend("+", withFont: boldFont)
                .chainAppend(" button above.", withFont: bodyFont)
        }
        
        return descriptionText
    }
}
