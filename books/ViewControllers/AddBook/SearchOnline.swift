//
//  SearchOnline.swift
//  books
//
//  Created by Andrew Bennet on 25/08/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import SVProgressHUD
import DZNEmptyDataSet
import Crashlytics

class SearchOnline: UIViewController, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var selectManyOrSingleToggle: UIBarButtonItem!
    @IBOutlet weak var addAllButton: UIBarButtonItem!
    @IBOutlet weak var toolbar: UIToolbar!

    let feedbackGeneratorWrapper = UIFeedbackGeneratorWrapper()

    var searchBar: UISearchBar!
    
    var initialSearchString: String?
    let disposeBag = DisposeBag()
    
    let emptyDatasetView = UINib(nibName: "SearchBooksEmptyDataset", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! SearchBooksEmptyDataset

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fixes issue at https://stackoverflow.com/q/46228862/5513562
        self.definesPresentationContext = true
        
        // Set DZN source and delegate
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self

        if #available(iOS 11.0, *) {
            let searchController = NoCancelButtonSearchController(searchResultsController: nil)
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.hidesNavigationBarDuringPresentation = false
            
            searchBar = searchController.searchBar
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        else {
            searchBar = UISearchBar()
            stackView.insertArrangedSubview(searchBar, at: 0)
            // We need to make the navigation bar non-translucent to avoid a big blank space being scrollable to
            navigationController!.navigationBar.isTranslucent = false
            
            // Pop up the keyboard, if not in a pre-populated search mode.
            // Doing this here doesn't work in iOS 11 - instead it is done in viewDidAppear
            if initialSearchString == nil {
                DispatchQueue.main.async { [weak self] in
                    self?.searchBar.becomeFirstResponder()
                }
            }
        }
        
        // The search bar delegate is used only to dismiss the keyboard when Done is pressed
        searchBar.returnKeyType = .search
        searchBar.text = initialSearchString
        searchBar.delegate = self
        
        // Hide the keyboard when scrolling
        tableView.keyboardDismissMode = .onDrag
        
        // Remove cell separators between blank cells
        tableView.tableFooterView = UIView()
        
        let autoSearch = Observable<String>.create { [unowned self] observer in
            // If we arrived with a search string, we want to fire off the search
            if let initialSearchString = self.initialSearchString {
                observer.onNext(initialSearchString)
            }
            return Disposables.create()
        }
        
        let searchTriggered = searchBar.rx.searchButtonClicked
            .map{ [unowned self] in
                self.searchBar.text!
            }
        
        let searchText = Observable.merge([autoSearch, searchTriggered])

        if #available(iOS 10.0, *) {
            searchText.subscribe(onNext: { [unowned self] _ in
                self.feedbackGeneratorWrapper.generator.prepare()
            }).disposed(by: disposeBag)
        }

        let searchResults = searchText
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .flatMapLatest { searchText -> Observable<GoogleBooks.SearchResultsPage> in
                SVProgressHUD.show(withStatus: "Searching...")

                if searchText.isEmptyOrWhitespace == false {
                
                    // Search on the Google API
                    return GoogleBooks.searchTextObservable(searchText)
                        .observeOn(MainScheduler.instance)
                }
                return Observable.just(GoogleBooks.SearchResultsPage.empty())
            }
            .share(replay: 1)
        
        // The clear search button should map to an empty set of results. Hook into the text observable
        // and filter to only include the events where the text box is empty
        let clearResults = searchBar.rx.text.orEmpty.filter { return $0.isEmpty }
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .map { _ in GoogleBooks.SearchResultsPage.empty() }
            .share(replay: 1)
        
        let aggregateResults = Observable.merge([searchResults, clearResults])
        
        // Map the sucess/failure state to the reason property on the empty data set
        aggregateResults
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] resultPage in
                SVProgressHUD.dismiss()
                if resultPage.searchText?.isEmptyOrWhitespace != false {
                    self.tableView.setContentOffset(CGPoint.zero, animated: false)
                    self.setEmptyDatasetReason(.noSearch)
                }
                else if !resultPage.searchResults.isSuccess {
                    if #available(iOS 10.0, *) {
                        self.feedbackGeneratorWrapper.generator.notificationOccurred(.error)
                    }
                    if let googleError = resultPage.searchResults.error as? GoogleBooks.GoogleError {
                        Crashlytics.sharedInstance().recordError(googleError, withAdditionalUserInfo: ["GoogleErrorMessage": googleError.message])
                    }
                    self.setEmptyDatasetReason(.error)
                }
                else if resultPage.searchResults.value!.count == 0 {
                    if #available(iOS 10.0, *) {
                        self.feedbackGeneratorWrapper.generator.notificationOccurred(.warning)
                    }
                    self.setEmptyDatasetReason(.noResults)
                }
                else {
                    if #available(iOS 10.0, *) {
                        self.feedbackGeneratorWrapper.generator.notificationOccurred(.success)
                    }
                }
            })
            .disposed(by: disposeBag)
        
        // Set up the table footer; hide it until there are results
        let poweredByGoogle = UIImageView(image: #imageLiteral(resourceName: "PoweredByGoogle"))
        poweredByGoogle.contentMode = .scaleAspectFit
        tableView.tableFooterView = poweredByGoogle
        tableView.tableFooterView!.isHidden = true
        
        aggregateResults.map{ ($0.searchResults.value?.count ?? 0) == 0 }
            .asDriver(onErrorJustReturn: true)
            .drive(tableView.tableFooterView!.rx.isHidden)
            .disposed(by: disposeBag)
        
        // Map the actual results to SearchResultViewModel items (or empty if failure)
        // and use them to drive the table cells
        aggregateResults.map { ($0.searchResults.value ?? []).map(SearchResultViewModel.init) }
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(cellIdentifier: "SearchResultCell", cellType: SearchResultCell.self)) { _, viewModel, cell in
                cell.viewModel = viewModel
            }
            .disposed(by: disposeBag)
        
        // On cell deselection, disable the Add button if there are no selected rows
        tableView.rx.modelDeselected(SearchResultViewModel.self)
            .subscribe(onNext: { [unowned self] _ in
                guard self.tableView.isEditing else { return }
                if (self.tableView.indexPathsForSelectedRows?.count ?? 0) == 0 {
                    self.addAllButton.isEnabled = false
                }
            })
            .disposed(by: disposeBag)

        // On cell selection, go to the next page (or enable the Add button)
        tableView.rx.itemSelected
            .subscribe(onNext: { [unowned self] indexPath in
                self.onBookSelection(indexPath)
            })
            .disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Deselect any selected row
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        
        // Becoming active in viewDidLoad doesn't seem to work in iOS 11
        // Do it here instead
        if #available(iOS 11.0, *) {
            DispatchQueue.main.async { [weak self] in
                self?.searchBar.becomeFirstResponder()
            }
        }
    }
    
    func onBookSelection(_ indexPath: IndexPath) {
        let model = (tableView.cellForRow(at: indexPath) as! SearchResultCell).viewModel!
        
        // Duplicate check
        let existingBook = appDelegate.booksStore.getIfExists(googleBooksId: model.googleBooksId, isbn: model.isbn13)
        guard existingBook == nil else {
            let alert = duplicateBookAlertController(goToExistingBook: { [unowned self] in
                self.presentingViewController!.dismiss(animated: true) {
                    appDelegate.tabBarController.simulateBookSelection(existingBook!, allowTableObscuring: true)
                }
            }, cancel: { [unowned self] in
                self.tableView.deselectRow(at: indexPath, animated: true)
            })
            if let presentedController = presentedViewController {
                presentedController.present(alert, animated: true)
            }
            else {
                present(alert, animated: true)
            }
            return
        }

        // If we are in multiple selection mode (i.e. Edit mode), switch the Add All button on
        if self.tableView.isEditing {
            self.addAllButton.isEnabled = true
        }
        else {
            // Otherwise, fetch and segue
            fetchAndSegue(googleBooksId: model.googleBooksId)
        }
    }
    
    func fetchAndSegue(googleBooksId: String) {
        UserEngagement.logEvent(.searchOnline)
        SVProgressHUD.show(withStatus: "Loading...")
        GoogleBooks.fetch(googleBooksId: googleBooksId) { resultPage in
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                if resultPage.result.isSuccess {
                    self.performSegue(withIdentifier: "searchResultSelected", sender: resultPage.result.value!)
                }
                else {
                    SVProgressHUD.showError(withStatus: "An error occurred. Please try again later.")
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let createReadState = segue.destination as? CreateReadState, let fetchResult = sender as? GoogleBooks.FetchResult {
            createReadState.bookMetadata = fetchResult.toBookMetadata()
        }
    }
    
    @IBAction func cancelWasPressed(_ sender: AnyObject) {
        if #available(iOS 11.0, *) {
            self.navigationItem.searchController!.isActive = false
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func selectManyOrSingleTogglePressed(_ sender: Any) {
        tableView.setEditing(!tableView.isEditing, animated: true)
        selectManyOrSingleToggle.title = tableView.isEditing ? "Select Single" : "Select Many"
        if !tableView.isEditing {
            addAllButton.isEnabled = false
        }
    }
    
    @IBAction func addAllPressed(_ sender: Any) {
        guard tableView.isEditing, let selectedRows = tableView.indexPathsForSelectedRows, selectedRows.count > 0 else { return }
        
        // If there is only 1 cell selected, we might as well proceed as we would in single selection mode
        guard selectedRows.count > 1 else {
            let model: SearchResultViewModel = try! self.tableView.rx.model(at: selectedRows[0])
            fetchAndSegue(googleBooksId: model.googleBooksId)
            return
        }

        let alert = UIAlertController(title: "Add \(selectedRows.count) books", message: "Are you sure you want to add all \(selectedRows.count) selected books? They will be added to the 'To Read' section.", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Add All", style: .default, handler: {[unowned self] _ in
            UserEngagement.logEvent(.searchOnlineMultiple)
            SVProgressHUD.show(withStatus: "Adding...")
            let fetches = DispatchGroup()
            var lastAddedBook: Book?
            var errorCount = 0
            
            // Queue up the fetches
            for selectedIndex in selectedRows {
                let model: SearchResultViewModel = try! self.tableView.rx.model(at: selectedIndex)
                
                fetches.enter()
                GoogleBooks.fetch(googleBooksId: model.googleBooksId) { resultPage in
                    DispatchQueue.main.async {
                        if let metadata = resultPage.result.value?.toBookMetadata() {
                            lastAddedBook = appDelegate.booksStore.create(from: metadata, readingInformation: BookReadingInformation.toRead())
                        }
                        else {
                            errorCount += 1
                        }
                        fetches.leave()
                    }
                }
            }
            
            // On completion, dismiss this view (or show an error if they all failed)
            fetches.notify(queue: .main) {
                SVProgressHUD.dismiss()
                if errorCount == selectedRows.count {
                    // If they all errored, don't dismiss and show an error
                    SVProgressHUD.showError(withStatus: "An error occurred. No books were added.")
                }
                else {
                    self.presentingViewController!.dismiss(animated: true) {
                        if let lastAddedBook = lastAddedBook {
                            // Scroll to the last added book. This is a bit random, but better than nothing probably
                            appDelegate.tabBarController.simulateBookSelection(lastAddedBook, allowTableObscuring: false)
                        }
                        // Display an error if any books could not be added
                        if errorCount != 0 {
                            SVProgressHUD.showInfo(withStatus: "\(selectedRows.count - errorCount) book\(selectedRows.count - errorCount == 1 ? "" : "s") successfully added; \(errorCount) book\(errorCount == 1 ? "" : "s") could not be added due to an error.")
                        }
                    }
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func setEmptyDatasetReason(_ reason: SearchBooksEmptyDataset.EmptySetReason) {
        emptyDatasetView.setEmptyDatasetReason(reason)
        tableView.reloadData()
    }
}

extension SearchOnline: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {
        return emptyDatasetView
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -(tableView.frame.height - 250)/2
    }
    
    func emptyDataSetDidAppear(_ scrollView: UIScrollView!) {
        toolbar.isHidden = true
    }
    
    func emptyDataSetDidDisappear(_ scrollView: UIScrollView!) {
        toolbar.isHidden = false
    }
}

class SearchBooksEmptyDataset: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    enum EmptySetReason {
        case noSearch
        case noResults
        case error
    }
    
    func setEmptyDatasetReason(_ reason: EmptySetReason) {
        self.reason = reason
        titleLabel.text = title
        descriptionLabel.text = descriptionString
    }
    
    private var reason = EmptySetReason.noSearch
    
    var title: String {
        get {
            switch reason {
            case .noSearch:
                return "🔍 Search Books"
            case .noResults:
                return "😞 No Results"
            case .error:
                return "⚠️ Error!"
            }
        }
    }
    
    var descriptionString: String {
        get {
            switch reason {
            case .noSearch:
                return "Search books by title, author, ISBN - or a mixture!"
            case .noResults:
                return "There were no Google Books search results. Try changing your search text."
            case .error:
                return "Something went wrong! It might be your Internet connection..."
            }
        }
    }
}

/// A table cell used in the Search Online table
class SearchResultCell : UITableViewCell {
    @IBOutlet weak var titleOutlet: UILabel!
    @IBOutlet weak var authorOutlet: UILabel!
    @IBOutlet weak var imageOutlet: UIImageView!
    
    var disposeBag: DisposeBag?
    
    var viewModel: SearchResultViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }
            
            titleOutlet.font = Fonts.gillSans(forTextStyle: .headline)
            authorOutlet.font = Fonts.gillSans(forTextStyle: .subheadline)
            
            titleOutlet.text = viewModel.title
            authorOutlet.text = viewModel.author
            
            disposeBag = DisposeBag()
            viewModel.coverImage.drive(imageOutlet.rx.image).disposed(by: disposeBag!)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
        disposeBag = nil
    }
}

/// The ViewModel corresponding to the SearchResultCell view
class SearchResultViewModel {
    
    let googleBooksId: String
    let isbn13: String?
    let title: String
    let author: String
    let coverImage: Driver<UIImage?>
    
    init(searchResult: GoogleBooks.SearchResult) {
        self.googleBooksId = searchResult.id
        self.isbn13 = searchResult.isbn13
        self.title = searchResult.title
        self.author = searchResult.authors.joined(separator: ", ")
        
        // If we have a cover URL, we should use that to drive the cell image
        guard let coverURL = searchResult.thumbnailCoverUrl else { coverImage = Driver.just(#imageLiteral(resourceName: "CoverPlaceholder")); return }
        
        // Observe the the web request on a background thread
        coverImage = URLSession.shared.rx.data(request: URLRequest(url: coverURL))
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .map(Optional.init)
            .startWith(nil)
            // Observe the results of web request on the main thread to update the search result cover image
            .observeOn(MainScheduler.instance)
            .map(UIImage.init)
            .asDriver(onErrorJustReturn: #imageLiteral(resourceName: "CoverPlaceholder"))
    }
}

