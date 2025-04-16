//
//  WikipediaController.swift
//  WhatFlower
//
//  Created by Kubra Bozdogan on 4/8/25.
//

import UIKit
import Alamofire
import SwiftyJSON
protocol <#name#> {
    <#requirements#>
}
struct WikipediaManager {
    
    let wikipediaURL = "https://en.wikipedia.org/"
    
    func fetchInfo(for flowerName: String) {
        let formattedName = flowerName.replacingOccurrences(of: " ", with: "_")
        let urlString = "\(wikipediaURL)w/rest.php/v1/search/page?q=\(formattedName)&limit=1"
        performRequest(with: urlString)
    }
    
    func performRequest(with urlString: String){
        if let url = URL(string: urlString) {
            AF.request(url).responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let json = try JSON(data: data)
                        let page = json["pages"][0]
                        let title = page["title"].stringValue
                        let description = page["description"].stringValue
                        let excerpt = page["excerpt"].stringValue
                        let imageURL = page["thumbnail"]["url"].stringValue
                        
                        let wikiModel = WikipediaModel(title: title, description: description, excerpt: excerpt, imageURL: imageURL)
                        fetchModel()
                        DispatchQueue.main.async {
                            self.wikiTitleLabel.text = wikiModel.title ?? "No title"
                            self.wikiDescLabel.text = wikiModel.description ?? "No description"
                            self.wikiExcerptLabel.text = wikiModel.excerpt ?? "No excerpt available"
                            if let imageURL = wikiModel.imageURL {
                                self.wikiImage.loadFrom(url: imageURL)
                            }else {
                                print("No image URL found!")
                            }
                        }
                        
                    } catch {
                        self.didFailWithError(error: error)
                        print("JSON parsing error: \(error)")
                    }
                case .failure(let error):
                    self.didFailWithError(error: error)
                    print("AF request failed: \(error)")
                }
            }
        }
    }
    
    func didFailWithError(error: Error) {
        print("😢 Wikipedia bilgisi çekilemedi: \(error)")
    }
        //
        //    func SwiftyJSON(_ wikimediaData: Data) -> WeatherModel? {
        //        let decoder = JSONDecoder()
        //        //decodes an instance of the indicated type. throws: if somethings goes wrong, it can throw out an error.
        //        //the "do" block has the thing with the "try" and that marks the method which can throw an error.
        //
        //        do {
        //            //decode actually has an output, it's going to create WeatherData.self object. If we capture that in a constant(let). We'll call it decoded data and we'll set it to the output of this method call.
        //            let decodedData = try decoder.decode(WeatherData.self, from: weatherData)
        //
        //            let id = decodedData.weather[0].id
        //            let temp = decodedData.main.temp
        //            let name = decodedData.name
        //
        //            let weather = WeatherModel(conditionId: id, cityName: name, temperature: temp)
        //            return weather
        //
        //        } catch {
        //            delegate?.didFailWithError(error: error)
        //            return nil
        //        }
        //    }
        //
        

    
}

extension UIImageView {
    func loadFrom(url: String) {
        guard let imageURL = URL(string: url) else {return}
        
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: imageURL),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
}
