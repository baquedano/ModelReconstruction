//
//  ViewController.swift
//  ARDetection
//
//  Created by David Baquedano on 9/2/23.
//

import UIKit
import RealityKit
import QuickLook

class ViewController: UIViewController {
    
    @IBOutlet weak var arView: ARView!
        
    @IBOutlet weak var scopeImageView: UIImageView!
    
    @IBOutlet weak var snapshotButtonContainer: UIView!
    @IBOutlet weak var snapshotButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var LoadingContainer: UIView!
    
    @IBOutlet var imagePreviews: [UIImageView]!
    
    var images: [UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for imagePreview in self.imagePreviews {
            let tapGR = UITapGestureRecognizer(target: self, action: #selector(self.onPreviewClicked))
            imagePreview.addGestureRecognizer(tapGR)
            imagePreview.isUserInteractionEnabled = true
        }
        
        
        self.snapshotButtonContainer.layer.cornerRadius = self.snapshotButtonContainer.bounds.width / 2
        self.snapshotButtonContainer.layer.masksToBounds = true
        self.snapshotButtonContainer.layer.borderColor = UIColor.white.cgColor
        self.snapshotButtonContainer.layer.borderWidth = 3
        
        self.snapshotButton.layer.cornerRadius = self.snapshotButton.bounds.width / 2
        self.snapshotButton.layer.masksToBounds = true
        
    }
    
    @IBAction func onSnapshotClicked() {
        self.snapshotButtonContainer.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        
        UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: CGFloat(0.2), initialSpringVelocity: CGFloat(6.0), options: UIView.AnimationOptions.allowUserInteraction, animations:  {
            self.snapshotButtonContainer.transform = CGAffineTransform.identity
        }, completion: {Void in()})
        
        self.arView.snapshot(saveToHDR: false) { image in
            
            let frame = self.arView.convert(self.scopeImageView.frame, to: self.view)
            
            let refX = frame.minX / self.view.frame.width
            let refY = frame.minY / self.view.frame.height
            let refW = frame.width / self.view.frame.width
            let refH = frame.height / self.view.frame.height
            
            let imgW = Double(image?.cgImage?.width ?? 0)
            let imgH = Double(image?.cgImage?.height ?? 0)
            let cropFrame = CGRect(x: refX * imgW, y: refY * imgH, width: refW * imgW, height: refH * imgH)
            guard let cropped = image?.cgImage?.cropping(to: cropFrame) else {return}
            self.images.append(UIImage(cgImage: cropped))
        
            
            for (index, preview) in self.imagePreviews.enumerated() {
                let imgIndex = self.images.count - self.imagePreviews.count + index
                if imgIndex >= 0 {
                    preview.image = self.images[imgIndex]
                }
            }
        }
    }
    
    @objc func onPreviewClicked(sender: UITapGestureRecognizer) {
        uploadImages()
    }
    
    
    @IBAction func onCreateModel(_ sender: Any) {
        uploadImages()
    }
    
    
    func uploadImages() {
        // setup loading ui
        self.LoadingContainer.isHidden = false
        self.activityIndicator.startAnimating()
        
        
        let url = URL(string: "http://192.168.1.182:3000/uploadImages")
        
        // generate boundary string using a unique per-app string
        let boundary = UUID().uuidString

        let session = URLSession.shared

        // Set the URLRequest to POST and to the specified URL
        var urlRequest = URLRequest(url: url!)
        urlRequest.httpMethod = "POST"

        // Set Content-Type Header to multipart/form-data, this is equivalent to submitting form data with file upload in a web browser
        // And the boundary is also set here
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var data = Data()
        // Add the image data to the raw http request data
        for image in self.images {
            let name = "photos"
            let filename = UUID()
            
            data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename).png\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
            data.append(image.pngData()!)

            data.append("\r\n--\(boundary)".data(using: .utf8)!)
        }
        // Close the boundaries.
        data.append("--\r\n".data(using: .utf8)!)
        
        // Send a POST request to the URL, with the data we created earlier
        session.uploadTask(with: urlRequest, from: data, completionHandler: { responseData, response, error in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.LoadingContainer.isHidden = true
                if error == nil {
                    self.saveDataToUSDZ(data: responseData)
                }
            }
            print(error, responseData, response)
        }).resume()
    }
    
    
    func saveDataToUSDZ(data: Data?) {
        if data == nil { return }
        
        let path = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask)[0].appendingPathComponent(UUID().uuidString).appendingPathExtension("usdz")
        do {
            try data?.write(to: path)
            let modelEntity = try Entity.loadModel(contentsOf: path)
            modelEntity.scale = SIMD3(0.5, 0.5, 0.5)
           
            let anchor = AnchorEntity(plane: .any)
            anchor.addChild(modelEntity)
            arView.scene.anchors.append(anchor)
        } catch let err {
            print(err)
        }
            
        
    }
}
