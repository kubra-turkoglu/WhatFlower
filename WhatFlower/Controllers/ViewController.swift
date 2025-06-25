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
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate, WikipediaManagerDelegate {
    func didUpdateWikipediaData(title: String, extract: String, imageURL: String) {
    }
    
    func didFailWithError(error: any Error) {
        print("error happened in ViewController delegate: \(error)")
    }
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var LabelView: UIView!
    @IBOutlet weak var bookmarksButton: UIBarButtonItem!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var textLabel: UILabel!
    
    
    let imagePicker = UIImagePickerController()
    
    var wikipediaManager = WikipediaManager()
    
    let url = "https://en.wikipedia.org/w/api.php"
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        bookmarksButton.isEnabled = false
        bookmarksButton.tintColor = .clear
        wikipediaManager.delegate = self
        LabelView.layer.cornerRadius = 10
        LabelView.clipsToBounds = true
        titleLabel.font = UIFont.systemFont(ofSize: 22)
        titleLabel.text = Constant().titleText
        titleLabel.sizeToFit()
        textLabel.font = UIFont.systemFont(ofSize: 17)
        textLabel.text = Constant().bodyText
        textLabel.sizeToFit()
        UIView.animate(withDuration: 0.3) {
            self.LabelView.layoutIfNeeded()
        }
        let newHeight = titleLabel.frame.height + textLabel.frame.height + 5
        LabelView.frame.size.height = newHeight
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
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
        picker.isEditing = true
        present(picker, animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userTakedPhoto = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            guard let convertedCIImage = CIImage(image: userTakedPhoto) else {
                fatalError("Could not convert the UIImage to CIImage")
            }
            detect(image: convertedCIImage)
            
            imageView.image = userTakedPhoto
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func bookmarksButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "goToResult", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToResult" {
            let destinationVC = segue.destination as! DefiningFlowerController
            destinationVC.flowerName = self.navigationItem.title // detected flower type
        }
    }
    func detect(image: CIImage) {
            let config = MLModelConfiguration()
                guard let model = try? VNCoreMLModel(for: FlowerClassifier(configuration: config).model) else {
                    fatalError("Loading CoreML Model Failed.")
                }
                
                let request = VNCoreMLRequest(model: model) { request, error in
                    guard let classification = request.results?.first as? VNClassificationObservation else {
                        fatalError("Model failed to process image.")
                    }
                    
                    let flowerType = classification.identifier
                    
                    self.navigationItem.title = flowerType.capitalized
                    self.bookmarksButton.isEnabled = true
                    self.bookmarksButton.tintColor = .systemBlue
                    self.titleLabel.text = "Discover \(flowerType) from Wikipedia."
                    self.textLabel.text = "Learn information about \(flowerType) from Wikipedia."
                    self.wikipediaManager.fetchModelFromWikipedia(flowerName: classification.identifier)
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

