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
import Fabric
import Crashlytics

class SearchOnline: UIViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var initialSearchString: String?
    
    let disposeBag = DisposeBag()
    
    let emptyDatasetView = UINib(nibName: "SearchBooksEmptyDataset", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! SearchBooksEmptyDataset
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.emptyDataSetSource = self
        
        // The search bar delegate is used only to dismiss the keyboard when Done is pressed
        searchBar.returnKeyType = .search
        searchBar.delegate = self
        searchBar.text = initialSearchString
        
        // Bring up the keyboard
        searchBar.becomeFirstResponder()
        
        // Hide the keyboard when scrolling
        tableView.keyboardDismissMode = .onDrag
        
        // Remove cell separators between blank cells
        tableView.tableFooterView = UIView()
        
        let autoSearch = Observable<Void>.create { [unowned self] observer in
            // If we arrived with a search string, we want to fire off the search
            if self.initialSearchString != nil {
                observer.onNext()
            }
            return Disposables.create()
        }
        
        // Map the click of the Search button (when there is non whitespace text)
        // to a google books searchcells
        let searchButtonClicked = searchBar.rx.searchButtonClicked.observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
        let searchResults = Observable.merge([autoSearch, searchButtonClicked])
            .flatMapLatest { [unowned self] Void -> Observable<GoogleBooks.SearchResultsPage> in
                SVProgressHUD.show(withStatus: "Searching...")

                if self.searchBar.text?.isEmptyOrWhitespace == false {
                
                    // Search on the Google API
                    return GoogleBooks.searchTextObservable(self.searchBar.text!)
                        .observeOn(MainScheduler.instance)
                }
                return Observable.just(GoogleBooks.SearchResultsPage.empty())
            }
            .shareReplay(1)
        
        // The Clear Result button should map to an empty set of results. Hook into the text observable
        // and filter to only include the events where the text box is empty
        let clearResults = searchBar.rx.text.orEmpty
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .filter { return $0.isEmpty }
            .map { _ in GoogleBooks.SearchResultsPage.empty() }
            .shareReplay(1)
        
        let aggregateResults = Observable.merge([searchResults, clearResults])
        
        // Map the sucess/failure state to the reason property on the empty data set
        aggregateResults
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] resultPage in
                SVProgressHUD.dismiss()
                if !resultPage.searchResults.isSuccess {
                    Crashlytics.sharedInstance().recordError(resultPage.searchResults.error!)
                    self.setEmptyDatasetReason(.error)
                }
                else if resultPage.searchText?.isEmptyOrWhitespace != false {
                    self.tableView.setContentOffset(CGPoint.zero, animated: false)
                    self.setEmptyDatasetReason(.noSearch)
                }
                else {
                    self.setEmptyDatasetReason(.noResults)
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
    }
    
    func onModelSelected(_ model: SearchResultViewModel) {
        UserEngagement.logEvent(.searchOnline)
        
        // Duplicate check
        if let existingBook = appDelegate.booksStore.getIfExists(googleBooksId: model.googleBooksId, isbn: model.isbn13) {
            
            let alert = duplicateBookAlertController(goToExistingBook: { [unowned self] in
                self.dismiss(animated: true) {
                    appDelegate.splitViewController.tabbedViewController.simulateBookSelection(existingBook)
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
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Dismiss the keyboard when the Done button is clicked. That is all.
        searchBar.endEditing(true)
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
        return -scrollView.frame.size.height/4
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
        self.author = searchResult.authors
        
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

