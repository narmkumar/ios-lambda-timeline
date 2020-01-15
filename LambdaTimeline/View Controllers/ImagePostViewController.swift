//
//  ImagePostViewController.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/12/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import Photos
import CoreImage
import CoreImage.CIFilterBuiltins
import AVFoundation


class ImagePostViewController: ShiftableViewController {
    
    // MARK: - Variables
    var postController: PostController!
    var post: Post?
    var imageData: Data?
    
    
    let context = CIContext(options: nil)
    
    var originalImage: UIImage?
    
    
    // MARK: - Filters
    
    private let vibranceFilter = CIFilter.vibrance()
    private let fadeFilter = CIFilter.photoEffectFade()
    private let processFilter = CIFilter.photoEffectProcess()
    private let sepiaFilter = CIFilter.sepiaTone()
    private let noirFilter = CIFilter.photoEffectNoir()
    
    
    // MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var chooseImageButton: UIButton!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var postButton: UIBarButtonItem!
    @IBOutlet weak var filterSegmentedControl: UISegmentedControl!
    @IBOutlet weak var intensitySlider: UISlider!
    
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setImageViewHeight(with: 1.0)
        
        updateViews()
    }
    // MARK: - IBActions
    
    @IBAction func filterChanged(_ sender: Any) {
        updateImage()
    }
    @IBAction func intensityChanged(_ sender: Any) {
        updateImage()
    }
    
    
    @IBAction func createPost(_ sender: Any) {
        
        view.endEditing(true)
        
        guard let imageData = imageView.image?.jpegData(compressionQuality: 0.1),
            let title = titleTextField.text, title != "" else {
                presentInformationalAlertController(title: "Uh-oh", message: "Make sure that you add a photo and a caption before posting.")
                return
        }
        
        postController.createPost(with: title, ofType: .image, mediaData: imageData, ratio: imageView.image?.ratio) { (success) in
            guard success else {
                DispatchQueue.main.async {
                    self.presentInformationalAlertController(title: "Error", message: "Unable to create post. Try again.")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func chooseImage(_ sender: Any) {
        
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch authorizationStatus {
        case .authorized:
            presentImagePickerController()
        case .notDetermined:
            
            PHPhotoLibrary.requestAuthorization { (status) in
                
                guard status == .authorized else {
                    NSLog("User did not authorize access to the photo library")
                    self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
                    return
                }
                
                self.presentImagePickerController()
            }
            
        case .denied:
            self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
        case .restricted:
            self.presentInformationalAlertController(title: "Error", message: "Unable to access the photo library. Your device's restrictions do not allow access.")
            
        @unknown default:
            NSLog("Problem occuring")
        }
        presentImagePickerController()
    }
    
    // MARK: - Image & Filtered Functions
    
    private func updateImage() {
        if let originalImage = originalImage {
            let filteredImage = filterImage(originalImage)
            imageView.image = filteredImage
        } else {
            imageView.image = nil
        }
    }
    
    private func filterImage(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        var ciImage = CIImage(cgImage: cgImage)
        
        
        vibranceFilter.setValue(ciImage, forKey: kCIInputImageKey)
        vibranceFilter.setValue(intensitySlider.value, forKey: kCIInputAmountKey)
        if let outputVibranceCIImage = vibranceFilter.outputImage {
            ciImage = outputVibranceCIImage
        }
        
        var aFilter = CIFilter()
        
        if filterSegmentedControl.selectedSegmentIndex > 0 {
            switch filterSegmentedControl.selectedSegmentIndex {
            case 1:
                aFilter = noirFilter
            case 2:
                aFilter = processFilter
            case 3:
                aFilter = sepiaFilter
            case 4:
                aFilter = fadeFilter
            default:
                break
            }
            aFilter.setValue(ciImage, forKey: kCIInputImageKey)
            if let outputCIImage = aFilter.outputImage {
                ciImage = outputCIImage
            }
        }
        
        let bounds = CGRect(origin: CGPoint.zero, size: image.size)
        
        // Rendering Image Again
        guard let outputCGImage = context.createCGImage(ciImage, from: bounds) else { return image }
        
        return UIImage(cgImage: outputCGImage)
    }
    
    // MARK: - Given Functions
    func updateViews() {
        
        guard let imageData = imageData,
            let image = UIImage(data: imageData) else {
                title = "New Post"
                return
        }
        
        title = post?.title
        
        setImageViewHeight(with: image.ratio)
        
        imageView.image = image
        
        chooseImageButton.setTitle("", for: [])
    }
    
    private func presentImagePickerController() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            presentInformationalAlertController(title: "Error", message: "The photo library is unavailable")
            return
        }
        
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func setImageViewHeight(with aspectRatio: CGFloat) {
        
        imageHeightConstraint.constant = imageView.frame.size.width * aspectRatio
        
        view.layoutSubviews()
    }
    
}

// MARK: - Extensions
extension ImagePostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        chooseImageButton.setTitle("", for: [])
        
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        
        originalImage = image
        
        setImageViewHeight(with: image.ratio)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
