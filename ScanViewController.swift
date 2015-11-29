//
//  BookTableViewController.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire
import SwiftyJSON
import CoreData


class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var highlightView = UIView()
    lazy var booksStore = appDelegate().booksStore
    
    @IBAction func CancelWasPressed(sender: UIBarButtonItem) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Allow the view to resize freely
        self.highlightView.autoresizingMask = [.FlexibleTopMargin, .FlexibleBottomMargin, .FlexibleLeftMargin, .FlexibleRightMargin]
        
        // We'll draw a thin blue box on the barcode when we detect it
        self.highlightView.layer.borderColor = UIColor.blueColor().CGColor
        self.highlightView.layer.borderWidth = 1
        self.view.addSubview(self.highlightView)
        
        // Setup the input
        let input: AVCaptureDeviceInput!
        do {
            // The default device with Video media type is the camera
            input = try AVCaptureDeviceInput(device: AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo))
            session.addInput(input)
        }
        catch {
            // TODO: Handle this error properly
            print("AVCaptureDeviceInput failed to initialise.")
            self.navigationController?.popViewControllerAnimated(true)
        }
        
        // Prepare the metadata output and add to the session
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        session.addOutput(output)
        output.metadataObjectTypes = output.availableMetadataObjectTypes
        
        // We want to view what the camera is seeing
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = self.view.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResize
        self.view.layer.addSublayer(previewLayer)
        
        // Start the scanner. We'll end it once we catch anything.
        print("AVCaptureSession starting")
        session.startRunning()
    }
    
    // This is called when we find a known barcode type with the camera.
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        // The scanner is capable of capturing multiple 2-dimensional barcodes in one scan.
        // Filter out everything which is not a EAN13 code.
        let ean13MetadataObjects = metadataObjects.filter{metadata in
            return metadata.type == AVMetadataObjectTypeEAN13Code
        }
        
        if let avMetadata = ean13MetadataObjects.first as? AVMetadataMachineReadableCodeObject{
            // Store the detected value of the barcode
            let detectedIsbn13 = avMetadata.stringValue
            print("Barcode decoded: " + detectedIsbn13!)
            
            // Draw a rectangle on the barcode
            self.highlightView.frame = self.previewLayer.transformedMetadataObjectForMetadataObject(avMetadata).bounds
            self.view.bringSubviewToFront(self.highlightView)
            
            // Since we have a result, stop the session
            self.session.stopRunning()
        
            // We've found an ISBN-13. Let's search for it online and if we
            // find anything useful use it to build a Book object.
            GoogleBooksApiClient.SearchByIsbn(detectedIsbn13, callback: ProcessSearchResult)
        }
 
    }
    
    /// Responds to a search result completion
    func ProcessSearchResult(result: BookMetadata?){
        if(result != nil){
            // Construct a new book
            let newBook = booksStore.newBook()
            
            // Populate the book metadata
            newBook.PopulateFromParsedResult(result!)
            
            for authorString in result!.authors{
                let newAuthor = booksStore.newAuthor()
                newAuthor.name = authorString
                newAuthor.authorOf = newBook
            }
            
            // Save the book!
            self.booksStore.save()
        }
        
        // TODO: Do something other than just going back at this point
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    
}