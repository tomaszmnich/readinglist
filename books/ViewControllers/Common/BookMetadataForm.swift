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
    
    private let titleKey = "title"
    private let authorListKey = "author"
    private let pageCountKey = "pageCount"
    private let publishedDateKey = "publishedDate"
    private let descriptionKey = "description"
    private let imageKey = "image"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title and Author
        form +++ Section()
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
        
        // Validate on load
        form.validate()
    }
    
    var titleField: String? {
        get { return form.values()[titleKey] as? String }
        set { form.setValues([titleKey: newValue]) }
    }
    
    var authorList: String? {
        get { return form.values()[authorListKey] as? String }
        set { form.setValues([authorListKey: newValue]) }
    }
    
    var pageCount: Int? {
        get { return form.values()[pageCountKey] as? Int }
        set { form.setValues([pageCountKey: newValue]) }
    }
    
    var publicationDate: Date? {
        get { return form.values()[publishedDateKey] as? Date }
        set { form.setValues([publishedDateKey: newValue]) }
    }
    
    var descriptionField: String? {
        get { return form.values()[descriptionKey] as? String }
        set { form.setValues([descriptionKey: newValue]) }
    }
    
    var image: UIImage? {
        get { return form.values()[imageKey] as? UIImage }
        set { form.setValues([imageKey: newValue]) }
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
