import UIKit
import AVFoundation
import Alamofire
import SwiftyJSON
import CoreData


class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var highlightView = UIView()
    lazy var coreDataStack = appDelegate().coreDataStack
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Allow the view to resize freely
        self.highlightView.autoresizingMask = [.FlexibleTopMargin, .FlexibleBottomMargin, .FlexibleLeftMargin, .FlexibleRightMargin]
        
        // Select the color you want for the completed scan reticle
        self.highlightView.layer.borderColor = UIColor.greenColor().CGColor
        self.highlightView.layer.borderWidth = 3
        
        // Add it to our controller's view as a subview.
        self.view.addSubview(self.highlightView)
        
        
        // For the sake of discussion this is the camera
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        let input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: device)
            session.addInput(input)
        }
        catch {
            // This is fine for a demo, do something real with this in your app. :)
            print("AVCaptureDeviceInput failed to initialise.")
            self.navigationController?.popViewControllerAnimated(true)
        }
        
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        session.addOutput(output)
        output.metadataObjectTypes = output.availableMetadataObjectTypes
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = self.view.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.view.layer.addSublayer(previewLayer)
        
        // Start the scanner. You'll have to end it yourself later.
        print("AVCaptureSession starting")
        session.startRunning()
    }
    
    // This is called when we find a known barcode type with the camera.
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        var highlightViewRect = CGRectZero

        var barCodeObject: AVMetadataObject!
        var detectedIsbn13: String?
        
        // The scanner is capable of capturing multiple 2-dimensional barcodes in one scan.
        for metadata in metadataObjects {
            
            if metadata.type == AVMetadataObjectTypeEAN13Code {

                    if let avMetadata = metadata as? AVMetadataMachineReadableCodeObject{
                    
                    barCodeObject = self.previewLayer.transformedMetadataObjectForMetadataObject(avMetadata)
                    highlightViewRect = barCodeObject.bounds
                    detectedIsbn13 = avMetadata.stringValue
                    print("Barcode decoded: " + detectedIsbn13!)
                    
                    self.session.stopRunning()
                    break
                }
            }
        }
        
        // If we found an ISBN 13, let's search for it online and, if we
        // find anything useful, use it to build a Book object.
        if (detectedIsbn13 != nil) {

            // Draw a rectangle on the barcode
            self.highlightView.frame = highlightViewRect
            self.view.bringSubviewToFront(self.highlightView)
            
            // Search on GoogleBooks
            GoogleBooksApiClient.SearchByIsbn(detectedIsbn13, callback: ProcessSearchResult)
        }
 
    }
    
    // Responds to a search result completion
    func ProcessSearchResult(result: ParsedBookResult?){
        if(result != nil){
            // Construct a new book
            let newBook = NSEntityDescription.insertNewObjectForEntityForName("Book", inManagedObjectContext: self.coreDataStack.managedObjectContext) as! Book
            
            // Populate the book metadata
            newBook.PopulateFromParsedResult(result!)
            
            // Save the book!
            let _ = try? self.coreDataStack.managedObjectContext.save()
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    
}