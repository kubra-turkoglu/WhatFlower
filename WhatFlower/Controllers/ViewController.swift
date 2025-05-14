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
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate, WikipediaManagerDelegate {
    func didUpdateWikipediaData(title: String, extract: String, imageURL: String) {
    }
    
    func didFailWithError(error: any Error) {
        print("error happened in ViewController delegate: \(error)")
    }

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var bookmarksButton: UIBarButtonItem!
    
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
            guard let convertedCIImage = CIImage(image: userTakedPhoto) else {
                fatalError("Could not convert the UIImage to CIImage")
            }
            detect(image: convertedCIImage)
            
            imageView.image = userTakedPhoto
        }
        //Once the user finished picking the image, we need to dismiss this imagePicker
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
        // 📦 Mevcut .mlpackage dosyalarını listele — debug için süper!
        let paths = Bundle.main.paths(forResourcesOfType: "mlpackage", inDirectory: nil)
        print("Bulunan .mlpackage dosyaları: \(paths)")
        
        // 🔍 Model dosyasını bulmaya çalış
        guard let modelURL = Bundle.main.url(forResource: "FlowerClassifier", withExtension: "mlmodel") else {
            fatalError("Model dosyası bulunamadı! 🤷‍♀️")
        }
        
        // 🛠️ Modeli derle
        guard let compiledModelURL = try? MLModel.compileModel(at: modelURL) else {
            fatalError("Model derlenemedi 😤")
        }
        
        // 📥 Derlenmiş modeli yükle
        guard let coreMLModel = try? MLModel(contentsOf: compiledModelURL) else {
            fatalError("Model yüklenemedi 🙃")
        }
        
        // 👁️‍🗨️ Vision modeline çevir
        guard let visionModel = try? VNCoreMLModel(for: coreMLModel) else {
            fatalError("VNCoreMLModel oluşturulamadı 😬")
        }

        // 🔍 Görüntü sınıflandırma isteği
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Model resmi işleyemedi! 🤖💥")
            }

            let flowerType = classification.identifier.capitalized
            print("Tahmin edilen çiçek: \(flowerType) 🌸")

            // 🧠 Wikipedia'dan bilgi çekme
            self.navigationItem.title = flowerType
            self.bookmarksButton.isEnabled = true
            self.bookmarksButton.tintColor = .systemBlue

            var wikiManager = WikipediaManager()
            wikiManager.delegate = self
            wikiManager.fetchModelFromWikipedia(flowerName: flowerType)
        }

        // 🖼️ Görüntü işleyiciyi çalıştır
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print("Görüntü işleme hatası: \(error.localizedDescription)")
        }
    }

//    func detect(image: CIImage) {
//        let paths = Bundle.main.paths(forResourcesOfType: "mlpackage", inDirectory: nil)
//        print("Bulunan .mlpackage dosyaları: \(paths)")
//        
//        guard let modelURL = Bundle.main.url(forResource: "FlowerClassifier", withExtension: "mlpackage") else {
//                fatalError("Model file didn't found!")
//            }
//        guard let compiledModelURL = try? MLModel.compileModel(at: modelURL) else {
//                fatalError("Model derlenemedi 😤")
//            }
//        guard let coreMLModel = try? MLModel(contentsOf: compiledModelURL) else {
//                fatalError("Model yüklenemedi 🙃")
//            }
//        guard let visionModel = try? VNCoreMLModel(for: coreMLModel) else {
//                fatalError("VNCoreMLModel oluşturulamadı 😬")
//            }
//        
////        guard let model = try? VNCoreMLModel(for: FlowerClassifier(configuration: MLModelConfiguration()).model) else {
////            fatalError("Loading CoreML Model Failed.")
////        }
//
//        let request = VNCoreMLRequest(model: visionModel) { request, error in
//            guard let classification = request.results?.first as? VNClassificationObservation else {
//                fatalError("Model failed to process image.")
//            }
//            let flowerType = classification.identifier.capitalized
//            self.wikipediaManager.fetchModelFromWikipedia(flowerName: classification.identifier)
//
//
//            self.navigationItem.title = flowerType
//            self.bookmarksButton.isEnabled = true
//            self.bookmarksButton.tintColor = .systemBlue
//
//            var wikiManager = WikipediaManager()
//            wikiManager.delegate = self
//            wikiManager.fetchModelFromWikipedia(flowerName: flowerType)
//        }
//        
//        let handler = VNImageRequestHandler(ciImage: image)
//        
//        do {
//            try handler.perform([request])
//        } catch {
//            print("Görüntü işleme hatası: \(error)")
//        }
//    }

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

