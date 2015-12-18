//
//  BookTableViewController.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import UIKit
import AVFoundation

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var cameraPreviewPlaceholder: UIView!
    let session = AVCaptureSession()
    lazy var booksStore = appDelegate.booksStore
    var bookReadState: BookReadState!
    
    @IBAction func cancelWasPressed(sender: UIBarButtonItem) {
        session.stopRunning()
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            // Setup the camera
            self.setupAvSession()
        }
    }
    
    private func setupAvSession(){
        // Setup the input
        let input: AVCaptureDeviceInput!
        do {
            // The default device with Video media type is the camera
            input = try AVCaptureDeviceInput(device: AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo))
            self.session.addInput(input)
        }
        catch {
            // TODO: Handle this error properly
            print("AVCaptureDeviceInput failed to initialise.")
            self.navigationController?.popViewControllerAnimated(true)
        }
        
        // Prepare the metadata output and add to the session
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        self.session.addOutput(output)
        output.metadataObjectTypes = output.availableMetadataObjectTypes
        
        // We want to view what the camera is seeing
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        previewLayer.frame = self.cameraPreviewPlaceholder.frame
        previewLayer.videoGravity = AVLayerVideoGravityResize
        dispatch_async(dispatch_get_main_queue()) {
            self.view.layer.addSublayer(previewLayer)
        }
        
        // Start the scanner. We'll end it once we catch anything.
        print("AVCaptureSession starting")
        self.session.startRunning()
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
            
            // Since we have a result, stop the session
            self.session.stopRunning()
            
            // Pop to the next page
            performSegueWithIdentifier("isbnDetectedSegue", sender: detectedIsbn13)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "isbnDetectedSegue" {
            let searchResultsController = segue.destinationViewController as! SearchResultsViewController
            searchResultsController.isbn13 = sender as! String
            searchResultsController.bookReadState = bookReadState
        }
    }
}