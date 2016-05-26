//
//  EditBookViewController.swift
//  books
//
//  Created by Andrew Bennet on 28/04/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Eureka
import UIKit

struct BookPageInputs {
    var title: String?
    var author: String?
    var pageCount: Int?
    var publicationDate: NSDate?
    var description: String?
}

class ChangeBook: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title and Author
        let titleAuthorSection = Section()
        titleAuthorSection.append(TextRow("title") {
            $0.placeholder = "Title"
        }.onChange{_ in
            self.onChange()
        })
        titleAuthorSection.append(TextRow("author") {
            $0.placeholder = "Author"
        }.onChange{ _ in
            self.onChange()
        })
        form.append(titleAuthorSection)
        
        // Page count and Publication date
        let pagePublicationSection = Section()
        pagePublicationSection.append(IntRow("page-count") {
            $0.title = "Number of Pages"
        })
        pagePublicationSection.append(DateRow("publication-date") {
            $0.title = "Publication Date"
        })
        pagePublicationSection.append(TextAreaRow("description"){
            $0.placeholder = "Description"
        }.cellSetup{
            $0.cell.height = {return 200}
        })
        form.append(pagePublicationSection)
    }
    
    func setValues(inputs: BookPageInputs) {
        form.setValues([
            "title": inputs.title,
            "author": inputs.author,
            "page-count": inputs.pageCount,
            "publication-date": inputs.publicationDate,
            "description": inputs.description])
    }
    
    func getValues() -> BookPageInputs {
        let formValues = form.values()
        let currentValues = BookPageInputs(title: formValues["title"] as? String,
                                           author: formValues["author"] as? String,
                                           pageCount: formValues["page-count"] as? Int,
                                           publicationDate: formValues["publication-date"] as? NSDate,
                                           description: formValues["description"] as? String)
        return currentValues
    }
    
    func onChange() {
        // Should be overriden
    }
    
    func isValid() -> Bool {
        let formValues = getValues()
        
        if formValues.title?.isEmpty ?? true {
            return false
        }
        if formValues.author?.isEmpty ?? true {
            return false
        }
        return true
    }
}