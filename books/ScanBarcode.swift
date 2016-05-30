//
//  BookTableViewController.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import UIKit
import AVFoundation

class ScanBarcode: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var cameraPreviewPlaceholder: UIView!
    
    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var detectedIsbn13: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the camera preview on another thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.setupAvSession()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        session.stopRunning()
    }
    
    private func setupAvSession() {
        guard let input = try? AVCaptureDeviceInput(device: AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)) else {
            // TODO: User error message and pop?
            print("AVCaptureDeviceInput failed to initialise.")
            return
        }
        self.session.addInput(input)
        
        // Prepare the metadata output and add to the session
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        output.metadataObjectTypes = output.availableMetadataObjectTypes
        self.session.addOutput(output)
        
        // We want to view what the camera is seeing
        previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        previewLayer!.frame = self.cameraPreviewPlaceholder.frame
        previewLayer!.videoGravity = AVLayerVideoGravityResize
        
        dispatch_async(dispatch_get_main_queue()) {
            self.view.layer.addSublayer(self.previewLayer!)
        }
        
        // Start the scanner. We'll end it once we catch anything.
        self.session.startRunning()
    }
    
    // This is called when we find a known barcode type with the camera.
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        // The scanner is capable of capturing multiple 2-dimensional barcodes in one scan.
        // Filter out everything which is not a EAN13 code.
        let ean13MetadataObjects = metadataObjects.filter { return $0.type == AVMetadataObjectTypeEAN13Code }
        
        if let avMetadata = ean13MetadataObjects.first as? AVMetadataMachineReadableCodeObject {
            // Store the detected value of the barcode
            detectedIsbn13 = avMetadata.stringValue
            
            // Since we have a result, stop the session and pop to the next page
            self.session.stopRunning()
            performSegueWithIdentifier("isbnDetectedSegue", sender: self)
        }
    }
    
    override func viewWillLayoutSubviews() {
        // Accomodate for device rotation.
        // This is kind of annoyingly juddery, but I can't find a simple way to stop that.
        
        if let connection = self.previewLayer?.connection where connection.supportsVideoOrientation {
            switch UIDevice.currentDevice().orientation {
            case .LandscapeRight:
                connection.videoOrientation = AVCaptureVideoOrientation.LandscapeLeft
            case .LandscapeLeft:
                connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
            case .PortraitUpsideDown:
                connection.videoOrientation = AVCaptureVideoOrientation.PortraitUpsideDown
            default:
                connection.videoOrientation = AVCaptureVideoOrientation.Portrait
            }
        }
        
        self.previewLayer?.frame = self.view.bounds;
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "isbnDetectedSegue" {
            let searchResultsController = segue.destinationViewController as! SearchByIsbn
            searchResultsController.isbn13 = detectedIsbn13!
        }
    }
}