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

class BookDetails: UIViewController {
    
    var book: Book?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func viewWillAppear(animated: Bool) {
        updateUi()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editBookSegue" {
            let navController = segue.destinationViewController as! UINavigationController
            let editBookController = navController.viewControllers.first as! EditBook
            editBookController.book = self.book
        }
    }
    
    func switchState(newState: BookReadState) {
        if let book = book {
            book.readState = newState
            appDelegate.booksStore.UpdateSpotlightIndex(book)
            appDelegate.booksStore.Save()
            self.navigationController?.popViewControllerAnimated(true)
        }
    }

    func delete(){
        if let book = book {
            appDelegate.booksStore.DeleteBookAndDeindex(book)
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func updateUi(){
        titleLabel.text = book?.title
        authorLabel.text = book?.authorList
        if let coverImg = book?.coverImage {
            imageView.image = UIImage(data: coverImg)
        }
        else{
            imageView.image = nil
        }
        descriptionLabel.text = book?.bookDescription
    }
}