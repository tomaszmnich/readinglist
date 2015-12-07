//
//  BookDetailsViewController.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class BookDetailsViewController: UIViewController{
    
    var book: Book!
    lazy var booksStore = appDelegate().booksStore
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pageCountLabel: UILabel!
    @IBOutlet weak var publishedByLabel: UILabel!
    @IBOutlet weak var publicationDateLabel: UILabel!
    
    override func viewDidLoad() {
        self.navigationController!.navigationBar.topItem!.title = "";
        titleLabel.text = book.title
        authorLabel.text = book.authorListString
        if let coverImg = book.coverImage {
            imageView.image = UIImage(data: coverImg)
        }
        pageCountLabel.text = book.pageCount != nil ? "\(book.pageCount!) pages" : ""
        publishedByLabel.text = book.publisher != nil ? "Published by \(book.publisher!)" : ""
        publicationDateLabel.text = book.publishedDate
    }
    
    @IBAction func moreIsPressed(sender: UIBarButtonItem) {
        // We are going to show an action sheet
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        // Add the options to switch read state. We will exclude the state we are currenly in.
        if book.readState != .Reading{
            optionMenu.addAction(pageActions.markAsReading.makeUIAlertAction({alertAction in
                self.switchState(.Reading)
            }))
        }
        if book.readState != .ToRead{
            optionMenu.addAction(pageActions.markAsToRead.makeUIAlertAction({alertAction in
                self.switchState(.ToRead)
            }))
        }
        if book.readState != .Finished{
            optionMenu.addAction(pageActions.markAsFinished.makeUIAlertAction({alertAction in
                self.switchState(.Finished)
            }))
        }
        
        // Always add the delete and cancel options
        optionMenu.addAction(pageActions.delete.makeUIAlertAction({alertAction in
            self.delete()
        }))
        
        optionMenu.addAction(pageActions.cancel.makeUIAlertAction(nil))
        
        // Bring up the action sheet
        self.presentViewController(optionMenu, animated: true, completion: nil)
    }
    
    func switchState(newState: BookReadState){
        book.readState = newState
        booksStore.Save()
        self.navigationController?.popViewControllerAnimated(true)
    }

    func delete(){
        booksStore.DeleteBook(book)
        booksStore.Save()
        self.navigationController?.popViewControllerAnimated(true)
    }

    
    /// Combines all the possible actions which this page can show
    enum pageActions{
        case markAsReading
        case markAsToRead
        case markAsFinished
        case delete
        case cancel
        
        private var titleText: String{
            switch self{
            case .markAsReading:
                return "Mark as Reading"
            case .markAsToRead:
                return "Mark as To Read"
            case .markAsFinished:
                return "Mark as Finished"
            case .delete:
                return "Delete"
            case .cancel:
                return "Cancel"
            }
        }
        
        private var style: UIAlertActionStyle! {
            switch self{
            case .delete:
                return .Destructive
            case .cancel:
                return .Cancel
            default:
                return .Default
            }
        }
        
        func makeUIAlertAction(bookFunction: (UIAlertAction -> Void)?) -> UIAlertAction{
            return UIAlertAction(title: titleText, style: style, handler: bookFunction)
        }
    }
}