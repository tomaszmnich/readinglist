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
    
    var session: AVCaptureSession?
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
        
        if session?.isRunning == false {
            session!.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if session?.isRunning == true {
            session!.stopRunning()
        }
    }
    
    private func setupAvSession() {
        guard let input = try? AVCaptureDeviceInput(device: AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)) else {
            scanningNotPossible(); return
        }
        let output = AVCaptureMetadataOutput()
        session = AVCaptureSession()
        
        // Check that we can add the input and output to the session
        guard session!.canAddInput(input) && session!.canAddOutput(output) else { scanningNotPossible(); return }
        
        // Prepare the metadata output and add to the session
        session!.addInput(input)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        session!.addOutput(output)
        
        // This line must be after session outputs are added
        output.metadataObjectTypes = [AVMetadataObjectTypeEAN13Code]
        
        // Begin the capture session.
        session!.startRunning()
        
        // We want to view what the camera is seeing
        previewLayer = AVCaptureVideoPreviewLayer(session: session!)
        previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer!.frame = view.bounds
        setVideoOrientation()
        
        view.layer.addSublayer(previewLayer!)
    }
    
    // TODO: check whether this is needed
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setVideoOrientation()
    }
    
    private func setVideoOrientation() {
        if let connection = self.previewLayer?.connection, connection.isVideoOrientationSupported {
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
    }
    
    func scanningNotPossible() {
        // Let the user know that scanning isn't possible with the current device.
        let alert = UIAlertController(title: "Can't Scan Barcode.", message: "The device's camera cannot be found.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default){ _ in
            self.dismiss(animated: true)
        })
        self.present(alert, animated: true)
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        guard let avMetadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
            
        // Store the detected value of the barcode. The output metadata object types was restricted to EAN13.
        detectedIsbn13 = avMetadata.stringValue
            
        // Since we have a result, stop the session and pop to the next page
        session!.stopRunning()
        performSegue(withIdentifier: "isbnDetectedSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let searchResultsController = segue.destination as? SearchByIsbn {
            searchResultsController.isbn13 = detectedIsbn13!
        }
    }
}
