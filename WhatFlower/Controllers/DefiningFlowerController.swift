//
//  DefiningFlowerController.swift
//  WhatFlower
//
//  Created by Kubra Bozdogan on 4/11/25.
//

import UIKit
import PhotosUI
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class DefiningFlowerController: UIViewController {
    
    
    @IBOutlet weak var wikipediaImageView: UIImageView!
    @IBOutlet weak var wikiTitleLabel: UILabel!
    @IBOutlet weak var extractTextLabel: UILabel!
    
    var wikipediaManager = WikipediaManager()
    var flowerName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wikipediaManager.delegate = self
        
        if let flower = flowerName {
            wikipediaManager.fetchModelFromWikipedia(flowerName: flower)
        }
        print("🌸 DefiningFlowerController açıldı mı acaba? Hı?")
        wikiTitleLabel.text = "HELLO TEST!"
    }
}
//MARK: - WikipediaManagerDelegate

extension DefiningFlowerController: WikipediaManagerDelegate {
    func didUpdateWikipediaData(title: String, extract: String, imageURL: String) {
        DispatchQueue.main.async {
            self.wikiTitleLabel.text = title
            self.extractTextLabel.text = extract
            self.wikipediaImageView.sd_setImage(with: URL(string: imageURL))
        }
    }
    func didFailWithError(error: any Error) {
        print("error: \(error)")
    }
}

