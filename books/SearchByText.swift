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
import Alamofire

class SearchResultCell : UITableViewCell {
    @IBOutlet weak var titleOutlet: UILabel!
    @IBOutlet weak var authorOutlet: UILabel!
    @IBOutlet weak var imageOutlet: UIImageView!
    
    var disposeBag: DisposeBag?
    
    var viewModel: SearchResultViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }
            
            disposeBag = DisposeBag()
            
            titleOutlet.text = viewModel.title
            authorOutlet.text = viewModel.author
            viewModel.coverImage.drive(imageOutlet.rx.image).addDisposableTo(disposeBag!)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
        disposeBag = nil
    }
}

class SearchResultViewModel {
    let searchResult: BookMetadata
    
    let title: String
    let author: String?
    let coverImage: Driver<UIImage?>
    
    init(searchResult: BookMetadata) {
        self.searchResult = searchResult
        
        self.title = searchResult.title
        self.author = searchResult.authorList
        if let coverURL = searchResult.coverUrl {
            print("requesting \(coverURL)")
            coverImage = URLSession.shared.rx.data(request: URLRequest(url: coverURL))
                .map(Optional.init)
                .startWith(nil)
                .do(onNext: {searchResult.coverImage = $0})
                .map(UIImage.init)
                .asDriver(onErrorJustReturn: nil)
        }
        else {
            coverImage = Driver.just(#imageLiteral(resourceName: "CoverPlaceholder"))
        }
    }
}

class SearchByText: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    let disposeBag = DisposeBag()
    let indicator = ActivityIndicator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Bring up the keyboard
        searchBar.becomeFirstResponder()
        
        // Remove cell separators between blank cells
        tableView.tableFooterView = UIView()
        
        indicator.drive(spinner.rx.isAnimating)
            .addDisposableTo(disposeBag)
        
        // Map the search bar text to a google books search, and bind the result to the table cells
        let cancelNoResults = searchBar.rx.cancelButtonClicked.asDriver()
            .map { _ -> [BookMetadata] in
                []
            }
        .asObservable()
        
        let searchResults = searchBar.rx.text.orEmpty.asDriver()
            .throttle(1)
            .distinctUntilChanged{ str1, str2 in
                str1.trimming() == str2.trimming()
            }
            .filter { !$0.isEmptyOrWhitespace }
            .flatMapLatest {
                GoogleBooksAPI.search($0)
                    .trackActivity(self.indicator)
                    .asDriver(onErrorJustReturn: [])
            }
            .asObservable()
        
        Observable.of(cancelNoResults, searchResults)
            .merge()
            .asDriver(onErrorJustReturn: [])
            .map{ results in
                results.map(SearchResultViewModel.init)
            }
            .drive(tableView.rx.items(cellIdentifier: "SearchResultCell", cellType: SearchResultCell.self)) {
                (_, viewModel, cell) in
                cell.viewModel = viewModel
            }
            .addDisposableTo(disposeBag)
        
        tableView.rx.modelSelected(SearchResultViewModel.self)
            .subscribe(onNext: { value in
                self.performSegue(withIdentifier: "searchResultSelected", sender: value.searchResult)
            })
            .addDisposableTo(disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let createBook = segue.destination as? CreateBook, let bookMetadata = sender as? BookMetadata {
            createBook.initialBookMetadata = bookMetadata
        }
    }
    
    @IBAction func cancelWasPressed(_ sender: AnyObject) {
        searchBar.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
}
