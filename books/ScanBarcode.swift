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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    private func setupAvSession() {
        guard let input = try? AVCaptureDeviceInput(device: AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)) else {
            return
        }
        let output = AVCaptureMetadataOutput()
        
        // Check that we can add the input and output to the session
        guard session.canAddInput(input) && session.canAddOutput(output) else { scanningNotPossible(); return }
        
        // Prepare the metadata output and add to the session
        session.addInput(input)
        
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [AVMetadataObjectTypeEAN13Code]
        session.addOutput(output)
        
        // Begin the capture session.
        session.startRunning()
        
        // We want to view what the camera is seeing
        previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        previewLayer!.frame = view.layer.bounds
        previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        DispatchQueue.main.sync {
            view.layer.addSublayer(previewLayer!)
        }
    }
    
    func scanningNotPossible() {
        // Let the user know that scanning isn't possible with the current device.
        let alert = UIAlertController(title: "Can't Scan Barcode.", message: "The device's camera cannot be found.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        guard let avMetadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
            
        // Store the detected value of the barcode. The output metadata object types was restricted to EAN13.
        detectedIsbn13 = avMetadata.stringValue
            
        // Since we have a result, stop the session and pop to the next page
        self.session.stopRunning()
        performSegue(withIdentifier: "isbnDetectedSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let searchResultsController = segue.destination as? SearchByIsbn {
            searchResultsController.isbn13 = detectedIsbn13!
        }
    }
}
