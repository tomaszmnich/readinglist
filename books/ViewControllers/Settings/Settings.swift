//
//  Settings.swift
//  books
//
//  Created by Andrew Bennet on 23/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import Foundation
import SVProgressHUD
import SwiftyJSON

class Settings: UITableViewController {

    @IBOutlet weak var addTestDataCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if !DEBUG
        addTestDataCell.isHidden = true
        #endif
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row == 0 {
            loadTestData()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func loadTestData() {
        
        SVProgressHUD.show(withStatus: "Loading")
        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        let testDataFile = Bundle.main.path(forResource: "testdata", ofType: "json")!
        let testJsonData = JSON(data: try! NSData(contentsOfFile: testDataFile) as Data)
        appDelegate.booksStore.deleteAllData()
        
        let requestDispatchGroup = DispatchGroup()
        var sortIndex = -1
        
        for testBook in testJsonData.array! {
            let parsedData = BookImport.fromJson(testBook)
            
            if parsedData.1.readState == .toRead {
                sortIndex += 1
            }
            
            requestDispatchGroup.enter()
            DispatchQueue.global(qos: .background).async {
                let thisSort = sortIndex
                GoogleBooksAPI.supplementMetadataWithImage(parsedData.0) {
                    DispatchQueue.main.sync {
                        let book = appDelegate.booksStore.create(from: parsedData.0, readingInformation: parsedData.1)
                        if book.readState == .toRead {
                            book.sort = thisSort as NSNumber
                            appDelegate.booksStore.save()
                        }
                        requestDispatchGroup.leave()
                    }
                }
            }
        }

        requestDispatchGroup.notify(queue: .main) {
            SVProgressHUD.dismiss()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
}
