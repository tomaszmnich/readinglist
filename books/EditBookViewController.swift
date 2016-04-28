//
//  EditBookViewController.swift
//  books
//
//  Created by Andrew Bennet on 28/04/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import Eureka
import UIKit

class EditBookViewController: FormViewController {
    
    var book: Book!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bookDetailsSection = Section()
        bookDetailsSection.append(SegmentedRow<BookReadState>("book-read-state") {
            $0.options = [.ToRead, .Reading, .Finished]
            $0.value = book.readState
            })
        bookDetailsSection.append(TextRow("title") {
            $0.placeholder = "Title"
            $0.value = book.title
            }.onChange{ _ in
                self.setStateOfDoneButton()
            })
        bookDetailsSection.append(TextRow("author") {
            $0.placeholder = "Author"
            $0.value = book.authorList
            }.onChange{ _ in
                self.setStateOfDoneButton()
            })
        bookDetailsSection.append(TextAreaRow("description") {
            $0.placeholder = "Description"
            $0.value = book.bookDescription
            })
        form.append(bookDetailsSection)
    }
    
    func setStateOfDoneButton() {
        
    }
}