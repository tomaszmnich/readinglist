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
    private let subjectsKey = "subjects"
    private let publishedDateKey = "publishedDate"
    private let descriptionKey = "description"
    private let imageKey = "image"
    private let deleteKey = "delete"
    
    var subjects = [String]() {
        didSet {
            guard isViewLoaded else { return }
            subjectsButton.updateCell()
        }
    }
    
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
        
        // Details section
        +++ Section(header: "Additional Information", footer: "")
            <<< IntRow(pageCountKey) {
                $0.title = "Page Count"
            }
            <<< DateRow(publishedDateKey) {
                $0.title = "Publication Date"
            }
            <<< ButtonRow(subjectsKey){
                $0.title = "Subjects"
                $0.presentationMode = .segueName(segueName: "editSubjectsSegue", onDismiss: nil)
                $0.cellStyle = .value1
            }.cellUpdate { [unowned self] cell, _ in
                cell.detailTextLabel?.text = self.subjects.joined(separator: ", ")
            }
        
        // Description section
        +++ Section(header: "Description", footer: "")
            <<< TextAreaRow(descriptionKey){
                $0.placeholder = "Description"
            }.cellSetup{
                $0.0.height = {return 200}
            }
        
        +++ Section()
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
    
    var subjectsButton: ButtonRow {
        get { return form.rowBy(tag: subjectsKey) as! ButtonRow }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let subjectsVc = segue.destination as? BookSubjectsForm {
            subjectsVc.subjects = subjects
        }
    }
}


class BookSubjectsForm: FormViewController {
    var subjects = [String]()
    
    var bookMetadataForm: BookMetadataForm {
        get { return navigationController!.viewControllers.first! as! BookMetadataForm }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        form +++ MultivaluedSection(multivaluedOptions: [.Insert, .Delete, .Reorder], header: "Subjects", footer: "Add subjects to catergorise this book") {
            $0.addButtonProvider = { _ in
                return ButtonRow(){
                    $0.title = "Add New Subject"
                }.cellUpdate { cell, row in
                    cell.textLabel?.textAlignment = .left
                }
            }
            $0.multivaluedRowToInsertAt = { _ in
                return TextRow() {
                    $0.placeholder = "Subject"
                }
            }
            for subject in subjects {
                $0 <<< TextRow() {
                    $0.value = subject
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        bookMetadataForm.subjects = form.rows.flatMap{($0 as? TextRow)?.value?.trimming().nilIfWhitespace()}.distinct()
        super.viewWillDisappear(animated)
    }
}
