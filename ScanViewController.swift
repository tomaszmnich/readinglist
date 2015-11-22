import UIKit
import AVFoundation
import Alamofire
import SwiftyJSON
import CoreData


class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    let session         : AVCaptureSession = AVCaptureSession()
    var previewLayer    : AVCaptureVideoPreviewLayer!
    var highlightView   : UIView = UIView()
    lazy var coreData = CoreDataStack()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Allow the view to resize freely
        self.highlightView.autoresizingMask =   [.FlexibleTopMargin,
            .FlexibleBottomMargin,
            .FlexibleLeftMargin,
            .FlexibleRightMargin]
        
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
            print("error")
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
        session.startRunning()
        
    }
    
    // This is called when we find a known barcode type with the camera.
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        var highlightViewRect = CGRectZero
        
        var barCodeObject : AVMetadataObject!
        
        var detectionString : String!
        
        
        // The scanner is capable of capturing multiple 2-dimensional barcodes in one scan.
        for metadata in metadataObjects {
            
                if metadata.type == AVMetadataObjectTypeEAN13Code {

                    let avMetadata = metadata as! AVMetadataMachineReadableCodeObject
                    
                    barCodeObject = self.previewLayer.transformedMetadataObjectForMetadataObject(avMetadata)
                    highlightViewRect = barCodeObject.bounds
                    detectionString = avMetadata.stringValue
                    
                    self.session.stopRunning()
                    break
                }
        }
        
        //navigationController?.popViewControllerAnimated(true)
        print(detectionString)
        self.highlightView.frame = highlightViewRect
        self.view.bringSubviewToFront(self.highlightView)
        
        
        Alamofire.request(.GET, "https://www.googleapis.com/books/v1/volumes?q=isbn:" + detectionString)
            .responseJSON { response in
                let jResponse = JSON(response.result.value!)
                if let title = jResponse["items"][0]["volumeInfo"]["title"].string{
                    print(title)
                    if let author = jResponse["items"][0]["volumeInfo"]["authors"][0].string{
                        print(author)
                        
                        let newBook = NSEntityDescription.insertNewObjectForEntityForName("Book", inManagedObjectContext: self.coreData.managedObjectContext) as! Book
                        newBook.title = title
                        newBook.author = author
                        let _ = try? self.coreData.managedObjectContext.save()
                        
                    }
                }
                self.navigationController?.popViewControllerAnimated(true)
        }
        
        
    }
    
    
}