//
//  SearchByText.swift
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

class SearchByText: UIViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    let disposeBag = DisposeBag()
    let indicator = ActivityIndicator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prepare the progress display style
        SVProgressHUD.setDefaultAnimationType(.native)
        SVProgressHUD.setDefaultMaskType(.black)
        
        // The search bar delegate is used only to dismiss the keyboard when Done is pressed
        searchBar.returnKeyType = .done
        searchBar.delegate = self
        
        // Bring up the keyboard
        searchBar.becomeFirstResponder()
        
        // Remove cell separators between blank cells
        tableView.tableFooterView = UIView()
        
        // Activity drives the spinner
        indicator.drive(spinner.rx.isAnimating).addDisposableTo(disposeBag)
        
        // Map the search bar text to a google books search, and bind the result to the table cells
        searchBar.rx.text
            .orEmpty
            .throttle(1, scheduler: MainScheduler.instance)
            .distinctUntilChanged{ str1, str2 in
                str1.trimming() == str2.trimming()
            }
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMapLatest { searchText in
                // Blank search terms produce empty array...
                searchText.isEmptyOrWhitespace ? Observable.just([]) :
                    
                    // Otherwise, search on the Google API
                    GoogleBooksAPI.search(searchText)
                        .trackActivity(self.indicator)
                        .do(onError: { error in
                            // handle errors - display error message?
                        })
                        .map { $0.map(SearchResultViewModel.init) }
            }
            .observeOn(MainScheduler.instance)
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(cellIdentifier: "SearchResultCell", cellType: SearchResultCell.self)) { _, viewModel, cell in
                cell.viewModel = viewModel
            }
            .addDisposableTo(disposeBag)
        
        // On cell selection, go to the next page
        tableView.rx.modelSelected(SearchResultViewModel.self).subscribe(onNext: { value in
            self.segueWhenCoverDownloaded(value.searchResult, secondsWaited: 0)
        })
        .addDisposableTo(disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    func segueWhenCoverDownloaded(_ bookMetadata: BookMetadata, secondsWaited: Int) {
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
}
