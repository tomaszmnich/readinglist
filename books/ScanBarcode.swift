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
        DispatchQueue.main.async {
            self.setupAvSession()
        }
    }
    
    @IBAction func cancelWasPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        session.stopRunning()
    }
    
    private func setupAvSession() {
        guard let input = try? AVCaptureDeviceInput(device: AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)) else {
            return
        }
        self.session.addInput(input)
        
        // Prepare the metadata output and add to the session
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        self.session.addOutput(output)
        output.metadataObjectTypes = output.availableMetadataObjectTypes
        
        // We want to view what the camera is seeing
        previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        previewLayer!.frame = self.cameraPreviewPlaceholder.frame
        previewLayer!.videoGravity = AVLayerVideoGravityResize
        
        DispatchQueue.main.async {
            self.view.layer.addSublayer(self.previewLayer!)
        }
        
        // Start the scanner. We'll end it once we catch anything.
        self.session.startRunning()
    }
    
    // This is called when we find a known barcode type with the camera.
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        // The scanner is capable of capturing multiple 2-dimensional barcodes in one scan.
        // Filter out everything which is not a EAN13 code.
        let ean13MetadataObjects = metadataObjects.filter { return ($0 as AnyObject).type == AVMetadataObjectTypeEAN13Code }
        
        if let avMetadata = ean13MetadataObjects.first as? AVMetadataMachineReadableCodeObject {
            // Store the detected value of the barcode
            detectedIsbn13 = avMetadata.stringValue
            
            // Since we have a result, stop the session and pop to the next page
            self.session.stopRunning()
            performSegue(withIdentifier: "isbnDetectedSegue", sender: self)
        }
    }
    
    override func viewWillLayoutSubviews() {
        // Accomodate for device rotation.
        // This is kind of annoyingly juddery, but I can't find a simple way to stop that.
        
        if let connection = self.previewLayer?.connection , connection.isVideoOrientationSupported {
            switch UIDevice.current.orientation {
            case .landscapeRight:
                connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            case .landscapeLeft:
                connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            case .portraitUpsideDown:
                connection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            default:
                connection.videoOrientation = AVCaptureVideoOrientation.portrait
            }
        }
        
        self.previewLayer?.frame = self.view.bounds;
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let searchResultsController = segue.destination as? SearchByIsbn {
            searchResultsController.isbn13 = detectedIsbn13!
        }
    }
}
