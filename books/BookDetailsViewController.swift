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

class BookDetailsViewController: UIViewController, BookSelectionDelegate {
    
    var book: Book?
    var newState: BookReadState?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func viewDidLoad() {
        //self.navigationController!.navigationBar.topItem!.title = "";
        updateUi()
    }
    
    @IBAction func moreIsPressed(sender: UIBarButtonItem) {
        // We are going to show an action sheet
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        // For a BookReadState, adds the option
        func addOptionToSwitchToState(state: BookReadState){
            optionMenu.addAction(pageActions.forReadState(state).makeUIAlertAction{self.switchState(state)})
        }
        
        // Add the options to switch read state. We will exclude the state we are currenly in.
        [.Reading, .ToRead, .Finished].filter(){$0 != book?.readState}.forEach(addOptionToSwitchToState)
        
        // Always add the delete and cancel options
        optionMenu.addAction(pageActions.delete.makeUIAlertAction{self.delete()})
        optionMenu.addAction(pageActions.cancel.makeUIAlertAction{})
        
        // Bring up the action sheet
        self.presentViewController(optionMenu, animated: true, completion: nil)
    }
    
    func switchState(newState: BookReadState){
        if let book = book {
        self.newState = newState
        if newState == .Finished{
            performSegueWithIdentifier("dateEntrySegue", sender: self)
        }
        else{
            book.readState = newState
            appDelegate.booksStore.SaveAndUpdateIndex(book)
            self.navigationController?.popViewControllerAnimated(true)
            }
        }
    }

    func delete(){
        if let book = book {
            appDelegate.booksStore.DeleteBook(book)
            appDelegate.booksStore.SaveAndUpdateIndex(book)
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "dateEntrySegue"{
            let dateViewController = segue.destinationViewController as! DateEntryViewController
            dateViewController.book = self.book
            dateViewController.completionHandler = {
                book in
                book.readState = self.newState!
                appDelegate.booksStore.SaveAndUpdateIndex(book)
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
        super.prepareForSegue(segue, sender: sender)
    }
    
    func bookSelected(book: Book) {
        self.book = book
        updateUi()
    }
    
    func updateUi(){
        titleLabel.text = book?.title
        authorLabel.text = book?.authorList
        if let coverImg = book?.coverImage {
            imageView.image = UIImage(data: coverImg)
        }
        descriptionLabel.text = book?.bookDescription
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
        
        static func forReadState(state: BookReadState) -> pageActions {
            switch state{
            case .Reading:
                return .markAsReading
            case .ToRead:
                return .markAsToRead
            case .Finished:
                return .markAsFinished
            }
        }
        
        func makeUIAlertAction(bookFunction: (Void -> Void)) -> UIAlertAction{
            // Wrap the supplied function in one whose signature matches the UIAlertAction constructor
            func bookFunctionWithInput(_: UIAlertAction) -> Void{
                bookFunction()
            }
            return UIAlertAction(title: titleText, style: style, handler: bookFunctionWithInput)
        }
    }
}