//
//  WikipediaManager.swift
//  WhatFlower
//
//  Created by Kubra Bozdogan on 4/8/25.
//

import UIKit
import Alamofire
import SwiftyJSON

protocol WikipediaManagerDelegate {
    func didUpdateWikipediaData(title: String, extract: String, imageURL: String)
    func didFailWithError(error: Error)
}
struct WikipediaManager {
    var delegate: WikipediaManagerDelegate?
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    func fetchModelFromWikipedia(flowerName: String) {
        let parameters: [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "1",
            "explaintext" : "1",
            "titles" : flowerName,
            "indexpageids" : "1",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        //Alamofire.request(url: URLConvertible, method: HTTPMethod, parameters: Parameters?, encoding: ParameterEncoding, headers: HTTPHeaders?)
        AF.request(wikipediaURL , method: .get , parameters: parameters).response { (response) in
            switch response.result {
            case .success(let data):
                print("Got the wikipedia Info.")
                //                print(response.result)
                //                print(data ?? "Hmm... no data?")
                guard let safeData = data else {
                    print("Data was nil.")
                    return
                }
                
                let flowerJSON : JSON = JSON(safeData)
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                
                let title = flowerJSON["query"]["pages"][pageid]["title"].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.delegate?.didUpdateWikipediaData(title: title , extract: flowerDescription, imageURL: flowerImageURL)
//                print("Description: \(flowerDescription)")
            case .failure(let error):
                print("Oh no! Error happened: \(error)")
            }
        }
    }
}
