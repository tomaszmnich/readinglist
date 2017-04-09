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
        
        // Setup the camera preview asynchronously
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
            #if DEBUG
                // In debug mode, when we are running via fastlane snapshot, just use an image of a barcode
                if UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
                    useExampleBarcodeImage()
                    return
                }
            #endif
            presentCameraPermissionsAlert()
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
            presentInfoAlert(title: "Error ⚠️", message: "The camera could not be used. Sorry about that.")
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
        guard let connection = self.previewLayer?.connection, connection.isVideoOrientationSupported else { return }
        
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
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        guard let avMetadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
        guard let _ = Isbn13.tryParse(inputString: avMetadata.stringValue) else { return }
        
        // Since we have a result, stop the session and hide the preview
        session?.stopRunning()
        
        // Check that the book hasn't already been added
        if let existingBook = appDelegate.booksStore.getIfExists(isbn: avMetadata.stringValue) {
            let alert = duplicateBookAlertController(existingBook, modalControllerToDismiss: self) {
                self.session?.startRunning()
            }
            
            self.present(alert, animated: true)
        }
        else {
            searchForFoundIsbn(isbn: avMetadata.stringValue)
        }
    }
    
    func searchForFoundIsbn(isbn: String) {
        SVProgressHUD.show(withStatus: "Searching...")
        
        // We've found an ISBN-13. Let's search for it online
        GoogleBooksAPI.fetchIsbn(isbn) { result in
            DispatchQueue.main.async {
                
                SVProgressHUD.dismiss()
                
                guard result.isSuccess else { self.onSearchError(result.failureError!); return }
                
                if let bookMetadata = result.successValue {
                    // We may now have a book which matches the Google Books ID (but didn't match the ISBN), so check again
                    if let existingBook = appDelegate.booksStore.getIfExists(googleBooksId: bookMetadata?.googleBooksId, isbn: bookMetadata?.isbn13) {
                        let alert = duplicateBookAlertController(existingBook, modalControllerToDismiss: self) {
                            self.session?.startRunning()
                        }
                        
                        self.present(alert, animated: true)
                    }
                    else {
                        self.foundMetadata = bookMetadata
                        self.performSegue(withIdentifier: "barcodeScanResult", sender: self)
                    }
                }
                else {
                    let alert = UIAlertController(title: "No Exact Match", message: "We couldn't find an exact match. Would you like to do a more general search instead?", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.cancel, handler: { _ in
                        self.session?.startRunning()
                    }))
                    alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { _ in
                        self.dismiss(animated: true){
                            appDelegate.splitViewController.tabbedViewController.performSegue(withIdentifier: "searchByText", sender: isbn)
                        }
                    }))
                    self.present(alert, animated: true, completion: nil)
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
    
    func presentCameraPermissionsAlert() {
        let alert = UIAlertController(title: "Permission Required", message: "You'll need to change your settings to allow Reading List to use your device's camera.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Settings", style: UIAlertActionStyle.default, handler: { _ in
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                UIApplication.shared.openUrlPlatformSpecific(url: appSettings)
                self.dismiss(animated: false)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { _ in
            self.dismiss(animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let createReadStateController = segue.destination as? CreateReadState {
            createReadStateController.bookMetadata = foundMetadata
        }
    }
    
    #if DEBUG
    
    func useExampleBarcodeImage() {
        let imageView = UIImageView(frame: view.frame)
        imageView.contentMode = .scaleAspectFill
        imageView.image = #imageLiteral(resourceName: "example_barcode.jpg")
        view.addSubview(imageView)
        imageView.addSubview(previewOverlay)
    }
    
    #endif
}
