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
    var foundMetadata: BookMetadata?
    
    @IBOutlet weak var cameraPreviewView: UIView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var previewOverlay: UIView!
    @IBOutlet weak var previewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var previewBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.stopAnimating()
        
        // Setup the camera preview on another thread
        DispatchQueue.main.async {
            self.setupAvSession()
            self.previewOverlay.layer.borderColor = UIColor.red.cgColor
            self.previewOverlay.layer.borderWidth = 1.0
        }
    }
    
    @IBAction func cancelWasPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        previewOverlay.isHidden = false
        previewTopConstraint.constant = 0
        previewBottomConstraint.constant = 0
        cameraPreviewView.layoutIfNeeded()
        
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
        let camera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        if camera?.isFocusPointOfInterestSupported == true {
            try? camera!.lockForConfiguration()
            camera!.focusPointOfInterest = cameraPreviewView.center
        }
        
        guard let input = try? AVCaptureDeviceInput(device: camera) else {
            presentInfoAlert(title: "Can't Scan Barcode.", message: "The device's camera cannot be found."); return
        }
        
        let output = AVCaptureMetadataOutput()
        session = AVCaptureSession()
        
        // Check that we can add the input and output to the session
        guard session!.canAddInput(input) && session!.canAddOutput(output) else {
            presentInfoAlert(title: "Can't Scan Barcode.", message: "The device's camera cannot be found.")
            return
        }
        
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
        
        cameraPreviewView.layer.addSublayer(previewLayer!)
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
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        guard let avMetadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
            
        // Since we have a result, stop the session and hide the preview
        session?.stopRunning()
        previewTopConstraint.constant = cameraPreviewView.frame.height / 2
        previewBottomConstraint.constant = cameraPreviewView.frame.height / 2
        previewOverlay.isHidden = true
        UIView.animate(withDuration: 0.3, animations: self.view.layoutIfNeeded) { _ in
            self.spinner.startAnimating()
        }
        
        // We've found an ISBN-13. Let's search for it online.
        GoogleBooksAPI.search(isbn: avMetadata.stringValue) { bookMetadata, error in
            if let error = error {
                self.onSearchError(error)
            }
            else {
                self.isbnSearchComplete(bookMetadata?.first)
            }
        }
    }
    
    func isbnSearchComplete(_ metadata: BookMetadata?) {
        spinner.stopAnimating()
        
        if metadata == nil {
            presentInfoAlert(title: "No Results", message: "No matching books found online")
        }
        else {
            foundMetadata = metadata
            self.performSegue(withIdentifier: "barcodeScanResult", sender: self)
        }
    }
    
    func onSearchError(_ error: Error) {
        spinner.stopAnimating()
        
        var message: String!
        switch (error as NSError).code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost:
                message = "No internet connection."
            default:
                message = "An error occurred."
        }
        presentInfoAlert(title: "Error", message: message)
    }
    
    func presentInfoAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { _ in
            self.spinner.stopAnimating()
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let createReadStateController = segue.destination as? CreateReadState {
            createReadStateController.bookMetadata = foundMetadata
        }
    }
}
