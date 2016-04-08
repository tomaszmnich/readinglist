//
//  EditBookDetails.swift
//  books
//
//  Created by Andrew Bennet on 06/04/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit

class EditBookDetails: UITableViewController {
    
    var book: Book?
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        navigationItem.title = book != nil ? "Edit Book" : "Create Book"
    }
    
    var settings: [EditableBookField] = [.Title, .Author]
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return settings[section].rawValue
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell =  self.tableView!.dequeueReusableCellWithIdentifier("SettingCell") ?? UITableViewCell()
        
        if let book = book{
            cell.textLabel?.text = settings[indexPath.section].textFromBook(book)
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section <= settings.count{
            return 1
        }
        else {
            return 0
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return settings.count
    }
}

enum EditableBookField: String{
    case Title = "Title"
    case Author = "Author"
    
    func textFromBook(book: Book) -> String? {
        switch self{
        case .Title:
            return book.title
        case .Author:
            return book.authorList
        }
    }
}