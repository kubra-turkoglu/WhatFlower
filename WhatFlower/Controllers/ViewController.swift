//
//  ViewController.swift
//  WhatFlower
//
//  Created by Kubra Bozdogan on 4/3/25.
//

import UIKit
import PhotosUI
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
    }

    @IBAction func cameraPressedButton(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: "Choose a photo", message: "You must choose a photo.", preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { alert in
                self.openCamera()
            }))
        }
        actionSheet.addAction(UIAlertAction(title: "Select from Gallery", style: .default, handler: { alert in
            self.openPhotoLibrary()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    func openCamera() {
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    
    func openPhotoLibrary() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userTakedPhoto = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = userTakedPhoto
            
            guard let convertedCIImage = CIImage(image: userTakedPhoto) else {
                fatalError("Could not convert the UIImage to CIImage")
            }
            detect(image: convertedCIImage)
        }
        //Once the user finished picking the image, we need to dismiss this imagePicker
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML Model Failed.")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Model failed to process image.")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            
        }
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider else {return}
        
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
                    if let selectedImage = image as? UIImage {
                        self.imageView.image = selectedImage
                    }
                }
            }
        }
        
    }
    
}

