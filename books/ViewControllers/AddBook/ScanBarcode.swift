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
import Fabric
import Crashlytics

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
        #if DEBUG
        if DebugSettings.useFixedBarcodeScanImage {
            useExampleBarcodeImage()
        }
        if let debugSimulation = DebugSettings.barcodeScanSimulation {
            switch debugSimulation {
            case .normal:
                // In "normal" mode we want to ignore any actual errors, like not having a camera
                return
            case .validIsbn:
                respondToCapturedIsbn("9781781100264")
                return
            case .unfoundIsbn:
                // Use a string which isn't an ISBN
                respondToCapturedIsbn("9781111111111")
                return
            case .existingIsbn:
                respondToCapturedIsbn(DebugSettings.existingIsbn)
                return
            case .noCameraPermissions:
                presentCameraPermissionsAlert()
                return
            }
        }
        #endif
    
        let camera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        guard let input = try? AVCaptureDeviceInput(device: camera) else {
            presentCameraPermissionsAlert()
            return
        }
        
        // Try to focus the camera if possible
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
        
        if let videoOrientation = UIDevice.current.orientation.videoOrientation {
            connection.videoOrientation = videoOrientation
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        guard let avMetadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let isbn = Isbn13.tryParse(inputString: avMetadata.stringValue) else { return }
        respondToCapturedIsbn(isbn)
    }
    
    func respondToCapturedIsbn(_ isbn: String) {
        // Since we have a result, stop the session and hide the preview
        session?.stopRunning()
        
        // Event logging
        UserEngagement.logEvent(.scanBarcode)
        
        // Check that the book hasn't already been added
        if let existingBook = appDelegate.booksStore.getIfExists(isbn: isbn) {
            presentDuplicateAlert(existingBook)
        }
        else {
            searchForFoundIsbn(isbn: isbn)
        }
    }
    
    func presentDuplicateAlert(_ book: Book) {
        let alert = duplicateBookAlertController(goToExistingBook: { [unowned self] in
            self.dismiss(animated: true) {
                appDelegate.splitViewController.tabbedViewController.simulateBookSelection(book)
            }
        }, cancel: { [unowned self] in
            self.session?.startRunning()
        })
        
        self.present(alert, animated: true)
    }
    
    func searchForFoundIsbn(isbn: String) {

        // We're going to be doing a search online, so bring up a spinner
        SVProgressHUD.show(withStatus: "Searching...")
        GoogleBooks.fetchIsbn(isbn) { resultPage in
            DispatchQueue.main.async {
                
                SVProgressHUD.dismiss()
                
                guard resultPage.result.isSuccess else {
                    let error = resultPage.result.error!
                    if (error as? GoogleBooks.GoogleErrorType) == .noResult {
                        self.presentNoExactMatchAlert(forIsbn: isbn)
                    }
                    else {
                        self.onSearchError(error)
                    }
                    return
                }
                
                let fetchResult = resultPage.result.value!
                // We may now have a book which matches the Google Books ID (but didn't match the ISBN), so check again
                if let existingBook = appDelegate.booksStore.getIfExists(googleBooksId: fetchResult.id) {
                    self.presentDuplicateAlert(existingBook)
                }
                else {
                    // If there is no duplicate, we can safely go to the next page
                    self.foundMetadata = fetchResult.toBookMetadata()
                    self.performSegue(withIdentifier: "barcodeScanResult", sender: self)
                }
            }
        }
    }
    
    func presentNoExactMatchAlert(forIsbn isbn: String) {
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

extension UIDeviceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        default: return nil
        }
    }
}
