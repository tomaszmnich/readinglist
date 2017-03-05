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
    private let pageCountKey = "page-count"
    private let publicationDateKey = "publication-date"
    private let descriptionKey = "description"
    private let imageKey = "image"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title and Author
        let titleAuthorSection = Section()
        titleAuthorSection.append(TextRow(titleKey) {
            $0.placeholder = "Title"
        }.onChange{_ in
            self.onChange()
        })
        titleAuthorSection.append(TextRow(authorListKey) {
            $0.placeholder = "Author"
        }.onChange{ _ in
            self.onChange()
        })
        form.append(titleAuthorSection)
        
        // Page count and Publication date
        let pagePublicationSection = Section()
        pagePublicationSection.append(IntRow(pageCountKey) {
            $0.title = "Number of Pages"
        })
        pagePublicationSection.append(DateRow(publicationDateKey) {
            $0.title = "Publication Date"
        })
        pagePublicationSection.append(TextAreaRow(descriptionKey){
            $0.placeholder = "Description"
        }.cellSetup{
            $0.0.height = {return 200}
        })
        
        pagePublicationSection.append(ImageRow(imageKey){
            $0.title = "Cover Image"
            $0.cell.height = {return 100}
        })
        form.append(pagePublicationSection)
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
        get { return form.values()[publicationDateKey] as? Date }
        set { form.setValues([publicationDateKey: newValue]) }
    }
    
    var descriptionField: String? {
        get { return form.values()[descriptionKey] as? String }
        set { form.setValues([descriptionKey: newValue]) }
    }
    
    var image: UIImage? {
        get { return form.values()[imageKey] as? UIImage }
        set { form.setValues([imageKey: newValue]) }
    }
    
    func onChange() {
        // Should be overriden
    }
    
    func dismiss() {
        self.view.endEditing(true)
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    var isValid: Bool {
        return titleField?.isEmptyOrWhitespace == false && authorList?.isEmptyOrWhitespace == false
    }
}
