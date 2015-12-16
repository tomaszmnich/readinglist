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
    
    @IBOutlet weak var cameraPreviewPlaceholder: UIView!
    let session = AVCaptureSession()
    lazy var booksStore = appDelegate.booksStore
    
    var bookReadState: BookReadState!
    
    @IBAction func cancelWasPressed(sender: UIBarButtonItem) {
        session.stopRunning()
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        // We need access to the camera in order to access this page at all
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: respondToMediaAccessResult)
        super.viewDidLoad()
    }
    
    func respondToMediaAccessResult(access: Bool) {
        if access{
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
        
            // Add a metadata output to the session
            session.addOutput({
                let output = AVCaptureMetadataOutput()
                output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
                output.metadataObjectTypes = output.availableMetadataObjectTypes
                return output
            }())
        
            // Add a sublayer to preview what the camera sees
            self.view.layer.addSublayer({
                let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                previewLayer.frame = cameraPreviewPlaceholder.frame
                previewLayer.videoGravity = AVLayerVideoGravityResize
                return previewLayer
            }())
        
            // Start the scanner. We'll end it once we catch anything.
            print("AVCaptureSession starting")
            session.startRunning()
        }
        else{
            let alertController = UIAlertController(title: "Camera Access Denied", message: "Cannot scan book barcode.", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Return", style: UIAlertActionStyle.Default, handler: nil))
            
            self.dismissViewControllerAnimated(true, completion: nil)

        }
    }
    
    // This is called when we find a known barcode type with the camera.
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        // The scanner is capable of capturing multiple 2-dimensional barcodes in one scan.
        // Filter out everything which is not a EAN13 code.
        let ean13MetadataObjects = metadataObjects.filter{$0.type == AVMetadataObjectTypeEAN13Code}
        
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