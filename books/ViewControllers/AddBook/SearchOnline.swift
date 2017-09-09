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

class SearchOnline: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var stackView: UIStackView!
    
    let feedbackGeneratorWrapper = UIFeedbackGeneratorWrapper()
    
    var searchBar: UISearchBar!
    
    var initialSearchString: String?
    let disposeBag = DisposeBag()
    
    let emptyDatasetView = UINib(nibName: "SearchBooksEmptyDataset", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! SearchBooksEmptyDataset
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set DZN delegate
        tableView.emptyDataSetSource = self

        if #available(iOS 11.0, *) {
            let searchController = UISearchController(searchResultsController: nil)
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
        }
        
        // The search bar delegate is used only to dismiss the keyboard when Done is pressed
        searchBar.returnKeyType = .search
        searchBar.text = initialSearchString
        
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
        
        let searchTest = Observable.merge([autoSearch, searchTriggered])
        if #available(iOS 10.0, *) {
            searchTest.subscribe(onNext: { [unowned self] _ in
                self.feedbackGeneratorWrapper.generator.prepare()
            }).addDisposableTo(disposeBag)
        }

        let searchResults = searchTest
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
            .shareReplay(1)
        
        // The Cancel button should map to an empty set of results. Hook into the text observable
        // and filter to only include the events where the text box is empty
        let emptySearch = searchBar.rx.text.orEmpty.filter { return $0.isEmpty }.map{_ in return}
        
        let clearResults = Observable.merge([searchBar.rx.cancelButtonClicked.asObservable(), emptySearch])
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .map { _ in GoogleBooks.SearchResultsPage.empty() }
            .shareReplay(1)
        
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
            .addDisposableTo(disposeBag)
        
        // Set up the table footer; hide it until there are results
        let poweredByGoogle = UIImageView(image: #imageLiteral(resourceName: "PoweredByGoogle"))
        poweredByGoogle.contentMode = .scaleAspectFit
        tableView.tableFooterView = poweredByGoogle
        tableView.tableFooterView!.isHidden = true
        
        aggregateResults.map{ ($0.searchResults.value?.count ?? 0) == 0 }
            .asDriver(onErrorJustReturn: true)
            .drive(tableView.tableFooterView!.rx.isHidden)
            .addDisposableTo(disposeBag)
        
        // Map the actual results to SearchResultViewModel items (or empty if failure)
        // and use them to drive the table cells
        aggregateResults.map { ($0.searchResults.value ?? []).map(SearchResultViewModel.init) }
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(cellIdentifier: "SearchResultCell", cellType: SearchResultCell.self)) { _, viewModel, cell in
                cell.viewModel = viewModel
            }
            .addDisposableTo(disposeBag)
        
        // On cell selection, go to the next page
        tableView.rx.modelSelected(SearchResultViewModel.self)
            .subscribe(onNext: { [unowned self] model in
                self.onModelSelected(model)
            })
            .addDisposableTo(disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Deselect any selected row
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        
        // Pop up the keyboard
        DispatchQueue.main.async { [weak self] in
            self?.searchBar.becomeFirstResponder()
        }
    }
    
    func onModelSelected(_ model: SearchResultViewModel) {
        UserEngagement.logEvent(.searchOnline)
        
        // Duplicate check
        if let existingBook = appDelegate.booksStore.getIfExists(googleBooksId: model.googleBooksId, isbn: model.isbn13) {
            
            let alert = duplicateBookAlertController(goToExistingBook: { [unowned self] in
                self.dismiss(animated: true) {
                    appDelegate.tabBarController.simulateBookSelection(existingBook)
                }
            }, cancel: { [unowned self] in
                // Deselect the row after dismissing the alert
                if let selectedRow = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: selectedRow, animated: true)
                }
            })
            present(alert, animated: true)
        }
        else {
            fetchAndSegue(googleBooksId: model.googleBooksId)
        }
    }
    
    func fetchAndSegue(googleBooksId: String) {
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
        searchBar.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
    
    func setEmptyDatasetReason(_ reason: SearchBooksEmptyDataset.EmptySetReason) {
        emptyDatasetView.setEmptyDatasetReason(reason)
        tableView.reloadData()
    }
}

extension SearchOnline: DZNEmptyDataSetSource {
    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {
        return emptyDatasetView
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -(tableView.frame.height - 250)/2
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
            viewModel.coverImage.drive(imageOutlet.rx.image).addDisposableTo(disposeBag!)
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

