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
import RxSwiftUtilities
import SVProgressHUD
import DZNEmptyDataSet

class SearchOnline: UIViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var initialSearchString: String?
    
    let disposeBag = DisposeBag()
    let indicator = ActivityIndicator()
    
    let emptyDataSet = EmptyDataSet()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.emptyDataSetSource = emptyDataSet
        
        // The search bar delegate is used only to dismiss the keyboard when Done is pressed
        searchBar.returnKeyType = .done
        searchBar.delegate = self
        searchBar.text = initialSearchString
        
        // Bring up the keyboard
        searchBar.becomeFirstResponder()
        
        // Hide the keyboard when scrolling
        tableView.keyboardDismissMode = .onDrag
        
        // Remove cell separators between blank cells
        tableView.tableFooterView = UIView()
        
        // Activity drives the spinner
        indicator.drive(spinner.rx.isAnimating).addDisposableTo(disposeBag)
        
        // Map the search bar text to a google books search, and bind the result to the table cells
        let searchTextAndResults = searchBar.rx.text
            .orEmpty
            .throttle(1, scheduler: MainScheduler.instance)
            .distinctUntilChanged{$0.trimming() == $1.trimming()}
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .flatMapLatest { searchText in
                // Blank search terms produce empty array...
                searchText.isEmptyOrWhitespace ? Observable.just((searchText, Result.success([]))) :
                    
                    // Otherwise, search on the Google API
                    GoogleBooksAPI.searchText(searchText)
                        .observeOn(MainScheduler.instance)
                        .trackActivity(self.indicator)
                        .map { (searchText, $0) }
            }
        
        // Map the sucess/failure state to the reason property on the empty data set
        searchTextAndResults
            .subscribe(onNext: {
                if $0.0.isEmptyOrWhitespace {
                    self.emptyDataSet.reason = .noSearch
                }
                else if $0.1.isSuccess {
                    self.emptyDataSet.reason = .noResults
                }
                else {
                    NSLog("Error searching online: \($0.1.failureError.debugDescription)")
                    self.emptyDataSet.reason = .error
                }
            })
            .addDisposableTo(disposeBag)
        
        // Map the actual results to SearchResultViewModel items (or empty if failure)
        // and use them to drive the table cells
        searchTextAndResults.map{$0.1.successValue?.map(SearchResultViewModel.init) ?? []}
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(cellIdentifier: "SearchResultCell", cellType: SearchResultCell.self)) { _, viewModel, cell in
                cell.viewModel = viewModel
            }
            .addDisposableTo(disposeBag)
        
        // On cell selection, go to the next page
        tableView.rx.modelSelected(SearchResultViewModel.self)
            .subscribe(onNext: onModelSelected)
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
        // Duplicate check
        if let isbn = model.searchResult.isbn13, let existingBook = appDelegate.booksStore.get(isbn: isbn) {
            
            let alert = duplicateBookAlertController(existingBook, modalControllerToDismiss: self) {
                // Deselect the row after dismissing the alert
                if let selectedRow = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: selectedRow, animated: true)
                }
            }
            self.present(alert, animated: true)
        }
        else {
            self.fetchAndSegue(searchResult: model.searchResult)
        }
    }

    func fetchAndSegue(searchResult: GoogleBooksSearchResult) {
        SVProgressHUD.show(withStatus: "Loading...")
        DispatchQueue.global(qos: .userInitiated).async {
            GoogleBooksAPI.fetch(googleBooksId: searchResult.id) { result in
                SVProgressHUD.dismiss()
                if result.isSuccess {
                    self.performSegue(withIdentifier: "searchResultSelected", sender: result.successValue!)
                }
                else {
                    SVProgressHUD.showError(withStatus: "ERROR")
                }
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Dismiss the keyboard when the Done button is clicked. That is all.
        searchBar.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let createReadState = segue.destination as? CreateReadState, let bookMetadata = sender as? BookMetadata {
            createReadState.bookMetadata = bookMetadata
        }
    }
    
    @IBAction func cancelWasPressed(_ sender: AnyObject) {
        searchBar.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
    
    /** 
     Empty Data Set for when no searches have yet been performed
    */
    class EmptyDataSet : NSObject, DZNEmptyDataSetSource {
        
        enum emptySetReason {
            case noSearch
            case noResults
            case error
        }
        
        var reason = emptySetReason.noSearch
        
        func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
            let reasonString: String
            switch reason {
            case .noSearch:
                reasonString = "🔍 Search Online"
            case .noResults:
                reasonString = "😞 No Results"
            case .error:
                reasonString = "⚠️ Error!"
            }
            return NSAttributedString(string: reasonString, withFont: UIFont.systemFont(ofSize: 36, weight: UIFontWeightThin))
        }
        
        func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
            let descriptionString: String
            switch reason {
            case .noSearch:
                descriptionString = "Type anything to start searching: a title, an author, an ISBN - or a mixture!"
            case .noResults:
                descriptionString =  "We didn't find anything online which matched. Try changing your search string."
            case .error:
                descriptionString = "Something went wrong! It might be your Internet connection..."
            }
            return NSAttributedString(string: descriptionString, withFont: UIFont.preferredFont(forTextStyle: .body))
        }
        
        func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
            return -scrollView.frame.size.height/4
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
    
    let searchResult: GoogleBooksSearchResult
    let title: String
    let author: String
    let coverImage: Driver<UIImage?>
    
    init(searchResult: GoogleBooksSearchResult) {
        self.searchResult = searchResult
        self.title = searchResult.title
        self.author = searchResult.authors

        // If we have a cover URL, we should use that to drive the cell image
        guard let coverURL = searchResult.thumbnailCoverUrl else { coverImage = Driver.just(#imageLiteral(resourceName: "CoverPlaceholder")); return }
        
        // Observe the the web request on a background thread
        coverImage = URLSession.shared.rx.data(request: URLRequest(url: coverURL))
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map(Optional.init)
            .startWith(nil)
            // Observe the results of web request on the main thread to update the search result cover image
            .observeOn(MainScheduler.instance)
            .map(UIImage.init)
            .asDriver(onErrorJustReturn: #imageLiteral(resourceName: "CoverPlaceholder"))
    }
}

