//
//  EditBookViewController.swift
//  books
//
//  Created by Andrew Bennet on 28/04/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Eureka
import ImageRow
import UIKit

class BookMetadataForm: FormViewController {
    
    private let isbnKey = "isbn"
    private let titleKey = "title"
    private let authorListKey = "author"
    private let pageCountKey = "pageCount"
    private let publishedDateKey = "publishedDate"
    private let descriptionKey = "description"
    private let imageKey = "image"
    private let deleteKey = "delete"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        form +++ Section()
            <<< TextRow(isbnKey) {
                $0.title = "ISBN"
                $0.add(rule: RuleClosure<String> { rowValue in
                    if rowValue != nil && !rowValue!.isEmpty && Isbn13.tryParse(inputString: rowValue!) == nil {
                        // We allow blank ISBN fields, but not present, invalid text.
                        return ValidationError(msg: "Invalid ISBN")
                    }
                    return nil
                })
                $0.validationOptions = .validatesOnChange
            }.onRowValidationChanged{[unowned self] _ in
                self.validationChanged()
            }
            
        // Title and Author
        +++ Section()
            <<< TextRow(titleKey) {
                $0.title = "Title"
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }.onRowValidationChanged{[unowned self] _ in
                self.validationChanged()
            }
            <<< TextRow(authorListKey) {
                $0.title = "Author"
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }.onRowValidationChanged{[unowned self] _ in
                self.validationChanged()
            }
        
        // Description section
        +++ Section()
            <<< IntRow(pageCountKey) {
                $0.title = "Page Count"
            }
            <<< DateRow(publishedDateKey) {
                $0.title = "Publication Date"
            }
            <<< TextAreaRow(descriptionKey){
                $0.placeholder = "Description"
            }.cellSetup{
                $0.0.height = {return 200}
            }
            <<< ImageRow(imageKey){
                $0.title = "Cover Image"
                $0.cell.height = {return 100}
            }
        
        // Delete button
        +++ Section()
            <<< ButtonRow(deleteKey){
                $0.title = "Delete"
            }.cellSetup{ cell, row in
                cell.tintColor = UIColor.red
            }
        
        // Validate on load
        form.validate()
    }
    
    var isbnField: TextRow {
        get { return form.rowBy(tag: isbnKey) as! TextRow }
    }
    
    var titleField: TextRow {
        get { return form.rowBy(tag: titleKey) as! TextRow }
    }
    
    var authorList: TextRow {
        get { return form.rowBy(tag: authorListKey) as! TextRow }
    }
    
    var pageCount: IntRow {
        get { return form.rowBy(tag: pageCountKey) as! IntRow }
    }
    
    var publicationDate: DateRow {
        get { return form.rowBy(tag: publishedDateKey) as! DateRow }
    }
    
    var descriptionField: TextAreaRow {
        get { return form.rowBy(tag: descriptionKey) as! TextAreaRow }
    }
    
    var image: ImageRow {
        get { return form.rowBy(tag: imageKey) as! ImageRow }
    }
    
    var deleteRow: ButtonRow {
        get { return form.rowBy(tag: deleteKey) as! ButtonRow }
    }

    private func validationChanged() {
        formValidated(isValid: form.rows.flatMap{$0.validationErrors}.isEmpty)
    }
    
    func formValidated(isValid: Bool) {
        // Should be overriden
    }
    
    func dismiss() {
        self.view.endEditing(true)
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}
