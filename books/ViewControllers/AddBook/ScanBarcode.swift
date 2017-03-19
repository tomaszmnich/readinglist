//
//  BookTableViewController.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import UIKit
import AVFoundation
import SVProgressHUD

class ScanBarcode: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var session: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var foundMetadata: BookMetadata?
    
    @IBOutlet weak var cameraPreviewView: UIView!
    @IBOutlet weak var previewOverlay: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        guard let input = try? AVCaptureDeviceInput(device: camera) else {
            presentCameraSetupError()
            return
        }
        
        if camera?.isFocusPointOfInterestSupported == true {
            try? camera!.lockForConfiguration()
            camera!.focusPointOfInterest = cameraPreviewView.center
        }
        
        let output = AVCaptureMetadataOutput()
        session = AVCaptureSession()
        
        // Check that we can add the input and output to the session
        guard session!.canAddInput(input) && session!.canAddOutput(output) else {
            presentCameraSetupError()
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
        
        // Check that the book hasn't already been added
        if appDelegate.booksStore.isbnExists(avMetadata.stringValue) {
            SVProgressHUD.showInfo(withStatus: "You have already added this book")
            return
        }
        
        // Since we have a result, stop the session and hide the preview
        session?.stopRunning()
        SVProgressHUD.show(withStatus: "Searching...")
        
        // We've found an ISBN-13. Let's search for it online in a background thread.
        DispatchQueue.global(qos: .background).async {
            GoogleBooksAPI.get(isbn: avMetadata.stringValue) { result, error in
                
                // Jump back to the main thread to process the result
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    
                    guard error == nil else {
                        self.onSearchError(error!)
                        return
                    }
                    guard let bookMetadata = result else {
                        self.presentInfoAlert(title: "No Results", message: "No matching books found online")
                        return
                    }
                    
                    self.foundMetadata = bookMetadata
                    self.performSegue(withIdentifier: "barcodeScanResult", sender: self)
                }
            }
        }
    }
    
    func onSearchError(_ error: Error) {
        var message: String!
        switch (error as NSError).code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost:
                message = "There seems to be no internet connection."
            default:
                message = "Something went wrong when searching online. Maybe try again?"
        }
        presentInfoAlert(title: "Error ⚠️", message: message)
    }
    
    func presentInfoAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { _ in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func presentCameraSetupError() {
        presentInfoAlert(title: "Error ⚠️", message: "The camera could not be used. Sorry about that.")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let createReadStateController = segue.destination as? CreateReadState {
            createReadStateController.bookMetadata = foundMetadata
        }
    }
}
