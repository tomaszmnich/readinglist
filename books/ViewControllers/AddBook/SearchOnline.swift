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
    
    let defaultEmptyDataSet = DefaultEmptyDataSet()
    let errorEmptyDataSet = ErrorEmptyDataSet()
    let noResultsEmptyDataSet = NoResultsEmptyDataSet()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.emptyDataSetSource = defaultEmptyDataSet
        
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
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMapLatest { searchText in
                // Blank search terms produce empty array...
                searchText.isEmptyOrWhitespace ? Observable.just((searchText, Result.success([]))) :
                    
                    // Otherwise, search on the Google API
                    GoogleBooksAPI.search(searchText)
                        .observeOn(MainScheduler.instance)
                        .trackActivity(self.indicator)
                        .map { (searchText, $0) }
            }
        
        // Map the sucess/failure state to the hidden property of the error label
        searchTextAndResults
            .subscribe(onNext: {
                if $0.0.isEmptyOrWhitespace {
                    self.tableView.emptyDataSetSource = self.defaultEmptyDataSet
                }
                else if $0.1.isSuccess {
                    self.tableView.emptyDataSetSource = self.noResultsEmptyDataSet
                }
                else {
                    NSLog("Error searching online: \($0.1.failureError.debugDescription)")
                    self.tableView.emptyDataSetSource = self.errorEmptyDataSet
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
        tableView.rx.modelSelected(SearchResultViewModel.self).subscribe(onNext: { value in
            
            // Display an alert if the book already exists in the store
            if let isbn = value.searchResult.isbn13, let existingBook = appDelegate.booksStore.get(isbn: isbn) {
                
                let alert = duplicateBookAlertController(addDuplicateHandler: {
                    self.segueWhenCoverDownloaded(value.searchResult, secondsWaited: 0)
                }, goToExistingBookHander: {
                    self.dismiss(animated: true) {
                        appDelegate.splitViewController.tabbedViewController.simulateBookSelection(existingBook)
                    }
                }, cancelHandler: {
                    // Deselect the row after dismissing the alert
                    if let selectedRow = self.tableView.indexPathForSelectedRow {
                        self.tableView.deselectRow(at: selectedRow, animated: true)
                    }
                })
                self.present(alert, animated: true)
            }
            else {
                self.segueWhenCoverDownloaded(value.searchResult, secondsWaited: 0)
            }
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
    
    func segueWhenCoverDownloaded(_ bookMetadata: BookMetadata, secondsWaited: Int) {
        // TODO: This should be re-written in reactive style...
        // If we have not yet downloaded the cover image, and we have not waited more than 6 seconds
        // This is not perfect - the first request may have failed and we are waiting for nothing...
        if bookMetadata.coverUrl != nil && bookMetadata.coverImage == nil && secondsWaited <= 6 {
            SVProgressHUD.show(withStatus: "Loading...")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                self.segueWhenCoverDownloaded(bookMetadata, secondsWaited: secondsWaited + 1)
            }
        }
        else {
            SVProgressHUD.dismiss()
            self.performSegue(withIdentifier: "searchResultSelected", sender: bookMetadata)
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
    class DefaultEmptyDataSet : NSObject, DZNEmptyDataSetSource {
        func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
            return NSAttributedString(string: "🔍 Search Online", withFont: UIFont.systemFont(ofSize: 36, weight: UIFontWeightThin))
        }
        
        func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
            return NSAttributedString(string: "Type anything to start searching: a title, an author, an ISBN - or a mixture!", withFont: UIFont.preferredFont(forTextStyle: .body))
        }
        
        func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
            return -scrollView.frame.size.height/4
        }
    }
    
    /**
     Empty Data Set for when a search was performed, but it returned no results
    */
    class NoResultsEmptyDataSet : NSObject, DZNEmptyDataSetSource {
        func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
            return NSAttributedString(string: "😞 No Results", withFont: UIFont.systemFont(ofSize: 36, weight: UIFontWeightThin))
        }
        
        func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
            return NSAttributedString(string: "We didn't find anything online which matched. Try changing your search string.", withFont: UIFont.preferredFont(forTextStyle: .body))
        }
        
        func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
            return -scrollView.frame.size.height/4
        }
    }
    
    /**
     Empty Data Set for when an error occurred.
    */
    class ErrorEmptyDataSet : NSObject, DZNEmptyDataSetSource {
        func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
            return NSAttributedString(string: "⚠️ Error!", withFont: UIFont.systemFont(ofSize: 36, weight: UIFontWeightThin))
        }
        
        func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
            return NSAttributedString(string: "Something went wrong! It might be your Internet connection...", withFont: UIFont.preferredFont(forTextStyle: .body))
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
    
    let searchResult: BookMetadata
    let title: String
    let author: String?
    let coverImage: Driver<UIImage?>
    
    init(searchResult: BookMetadata) {
        self.searchResult = searchResult
        self.title = searchResult.title
        self.author = searchResult.authorList
        
        // If we have a cover URL, we should use that to drive the cell image,
        // and also store the data in the search result.
        if let coverURL = searchResult.coverUrl {
            
            // Observe the the web request on a background thread
            coverImage = URLSession.shared.rx.data(request: URLRequest(url: coverURL))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .map(Optional.init)
                .startWith(nil)
                // Observe the results of web request on the main thread to update the search result cover image
                .observeOn(MainScheduler.instance)
                .do(onNext: {
                    searchResult.coverImage = $0
                })
                .map(UIImage.init)
                .asDriver(onErrorJustReturn: #imageLiteral(resourceName: "CoverPlaceholder"))
        }
        else {
            coverImage = Driver.just(#imageLiteral(resourceName: "CoverPlaceholder"))
        }
    }
}

