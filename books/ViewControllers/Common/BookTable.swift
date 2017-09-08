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
    
    func configureFrom(_ book: Book) {
        titleLabel.font = Fonts.gillSans(forTextStyle: .headline)
        authorsLabel.font = Fonts.gillSans(forTextStyle: .subheadline)
        readTimeLabel.font = Fonts.gillSans(forTextStyle: .footnote)
        
        titleLabel.text = book.title
        authorsLabel.text = book.authorsFirstLast
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

class BookTableUpdater: TableUpdater<Book, BookTableViewCell> {
    
    let onChange: (() -> ())
    
    init(table: UITableView, controller: NSFetchedResultsController<Book>, onChange: @escaping (() -> ())) {
        self.onChange = onChange
        super.init(table: table, controller: controller)
    }
    
    override func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange object: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)  {
        super.controller(controller, didChange: object, at: indexPath, for: type, newIndexPath: newIndexPath)
        
        onChange()
    }
    
    override func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        super.controller(controller, didChange: sectionInfo, atSectionIndex: sectionIndex, for: type)
        
        onChange()
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

    @IBOutlet weak var tableFooter: UILabel!
    
    override func viewDidLoad() {
    
        /// The UISearchController to which this UITableViewController will be connected.
        configureSearchController()
        
        // Handle the data fetch, sort and filtering
        buildResultsController()
        
        // We will manage the clearing of selections ourselves.
        clearsSelectionOnViewWillAppear = false
        
        // Some search bar styles are slightly different on iOS 11
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationController!.navigationBar.prefersLargeTitles = true
        }
        else {
            searchController.searchBar.backgroundColor = tableView.backgroundColor!
            searchController.hidesNavigationBarDuringPresentation = false
            tableView.tableHeaderView = searchController.searchBar
            tableView.setContentOffset(CGPoint(x: 0, y: searchController.searchBar.frame.height), animated: false)
        }
        
        // Set the table footer text
        tableFooter.text = footerText()
        tableFooter.font = Fonts.gillSans(forTextStyle: .subheadline)
        
        // Set the DZN data set source
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        // The left button should be an edit button
        navigationItem.leftBarButtonItem = editButtonItem

        // Watch for changes in book sort order
        NotificationCenter.default.addObserver(self, selector: #selector(bookSortChanged), name: NSNotification.Name.onBookSortOrderChanged, object: nil)
        
        super.viewDidLoad()
    }
    
    @objc func bookSortChanged() {
        buildResultsController()
        tableView.reloadData()
    }
    
    func footerText() -> String? {
        // Override to configure table footer label text
        return nil
    }
    
    func sectionIndex(forReadState readState: BookReadState) -> Int? {
        if let sectionIndex = resultsController.sections?.index(where: {$0.name == String.init(describing: readState.rawValue)}) {
            return resultsController.sections!.startIndex.distance(to: sectionIndex)
        }
        return nil
    }
    
    func readStateForSection(_ section: Int) -> BookReadState {
        return readStates.first{sectionIndex(forReadState: $0) == section}!
    }
    
    func buildResultsController() {
        let readStatePredicate = NSPredicate.Or(readStates.map{BookPredicate.readState(equalTo: $0)})
        resultsController = appDelegate.booksStore.fetchedResultsController(readStatePredicate, initialSortDescriptors: UserSettings.selectedSortOrder)
        tableUpdater = BookTableUpdater(table: tableView, controller: resultsController){ [unowned self] in
            self.tableFooter.text = self.footerText()
        }
        
        let predicateBuilder = BookPredicateBuilder(readStatePredicate: readStatePredicate)
        resultsFilterer = FetchedResultsFilterer(uiSearchController: searchController, tableView: self.tableView, fetchedResultsController: resultsController, predicateBuilder: predicateBuilder){ [unowned self] in
            self.tableFooter.text = self.footerText()
        }
    }
    
    func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.returnKeyType = .done
        searchController.searchBar.placeholder = "Your Library"
        searchController.searchBar.searchBarStyle = .minimal
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Deselect selected rows, so they don't stay highlighted, but only when in non-split mode
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow, !parentSplitViewController.detailIsPresented {
            self.tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
        
        super.viewDidAppear(animated)
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
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let toReadIndex = sectionIndex(forReadState: .toRead)
        let readingIndex = sectionIndex(forReadState: .reading)
        
        // Start with the delete action
        var rowActions = [UITableViewRowAction(style: .destructive, title: "Delete") { [unowned self] _, indexPath in
            self.presentDeleteBookAlert(indexPath: indexPath, callback: nil)
        }]
        
        // Add the other state change actions where appropriate
        if indexPath.section == toReadIndex {
            let startAction = UITableViewRowAction(style: .normal, title: "Start") { [unowned self] rowAction, indexPath in
                self.resultsController.object(at: indexPath).transistionToReading()
            }
            startAction.backgroundColor = UIColor.buttonBlue
            rowActions.append(startAction)
        }
        else if indexPath.section == readingIndex {
            let finishAction = UITableViewRowAction(style: .normal, title: "Finish") { [unowned self] rowAction, indexPath in
                self.resultsController.object(at: indexPath).transistionToFinished()
            }
            finishAction.backgroundColor = UIColor.flatGreen
            rowActions.append(finishAction)
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
    
    @available(iOS 11.0, *)
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [unowned self] _,_,callback in
            self.presentDeleteBookAlert(indexPath: indexPath, callback: callback)
        }
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    func presentDeleteBookAlert(indexPath: IndexPath, callback: ((Bool) -> ())?) {
        let bookToDelete = self.resultsController.object(at: indexPath)
        let confirmDeleteAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if let popPresenter = confirmDeleteAlert.popoverPresentationController {
            let cell = self.tableView.cellForRow(at: indexPath)!
            popPresenter.sourceRect = cell.frame
            popPresenter.sourceView = self.tableView
            popPresenter.permittedArrowDirections = .any
        }
        
        confirmDeleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            callback?(false)
        })
        confirmDeleteAlert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            bookToDelete.deleteAndLog()
            callback?(true)
        })
        self.present(confirmDeleteAlert, animated: true, completion: nil)
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
        
        return NSAttributedString(string: titleText, attributes: [NSAttributedStringKey.font: Fonts.gillSans(ofSize: 32),
                                                                  NSAttributedStringKey.foregroundColor: UIColor.gray])
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        if resultsFilterer.showingSearchResults {
            // Shift the "no search results" view up a bit, so the keyboard doesn't obscure it
            return -(tableView.frame.height - 150)/4
        }
        
        // The large titles make the empty data set look weirdly low down. Adjust this,
        // by - fairly randomly - the height of the nav bar
        if #available(iOS 11.0, *), navigationController!.navigationBar.prefersLargeTitles {
            return -navigationController!.navigationBar.frame.height
        }
        else {
            return 0
        }
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let bodyFont = Fonts.gillSans(forTextStyle: .title2)
        let boldFont = Fonts.gillSansSemiBold(forTextStyle: .title2)
        
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

extension BookTable: DZNEmptyDataSetDelegate {
    // We want to hide the Edit button when there are no items on the screen; show it when there are
    // items on the screen.
    // We want to hide the Search Bar when there are no items, but not due to a search filtering everything out.
    func emptyDataSetDidAppear(_ scrollView: UIScrollView!) {
        if !resultsFilterer.showingSearchResults {
            self.searchController.searchBar.isHidden = true
        }
        navigationItem.leftBarButtonItem!.toggleHidden(hidden: true)
    }
    
    func emptyDataSetDidDisappear(_ scrollView: UIScrollView!) {
        self.searchController.searchBar.isHidden = false
        navigationItem.leftBarButtonItem!.toggleHidden(hidden: false)
    }
}
