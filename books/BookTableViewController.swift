//
//  BookTableViewController.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit
import DZNEmptyDataSet

@objc protocol BookTableViewControllerDelegate {
    func editViewDidCancel(editController: EditBookViewController)
    func editViewDidSave(editController: EditBookViewController)
}

class BookTableViewController: UITableViewController, DZNEmptyDataSetSource {
    
    var reloadData = true
    var books = [
        Book(title: "Title", author: "Author"),
        Book(title: "Title2", author: "Author2")
    ]
    
    override func viewWillAppear(animated: Bool) {
        if reloadData {
            tableView.reloadData()
            reloadData = false
        }
    }
    
    override func viewDidLoad() {
        tableView.emptyDataSetSource = self
        tableView.tableFooterView = UIView()
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Welcome"
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Tap the button above to add your first book."
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Get a spare cell
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        // Configure the cell from the corresponding book
        let book: Book = bookFromIndexPath(indexPath)
        cell.textLabel?.text = book.title
        cell.detailTextLabel?.text = book.author
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "detailsSegue" {
            if let cell = sender as? UITableViewCell {
                let indexPath = tableView.indexPathForCell(cell)!
                let bookDetails = segue.destinationViewController as! BookDetailsViewController
                bookDetails.book = bookFromIndexPath(indexPath)
            }
        }
        else if segue.identifier == "addSegue" {
            let addBookController = segue.destinationViewController as! EditBookViewController
            addBookController.bookListDelegate = self
        }
    }
    
    func bookFromIndexPath(indexPath: NSIndexPath) -> Book{
        return books[indexPath.row]
    }
}

extension BookTableViewController : BookTableViewControllerDelegate{
    func editViewDidCancel(editController: EditBookViewController) {}
    
    func editViewDidSave(editController: EditBookViewController) {
        books.append(editController.book)
        reloadData = true
    }
}
