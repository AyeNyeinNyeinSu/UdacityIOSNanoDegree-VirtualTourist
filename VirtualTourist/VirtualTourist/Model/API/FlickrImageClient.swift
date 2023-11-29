//
//  FlickrImageClient.swift
//  VirtualTourist
//
//  Created by Aye Nyein Nyein Su on 24/05/2023.
//

import Foundation
import UIKit

class FlickrImageClient: NSObject {
    
    enum Endpoints {
        
        static let base = "https://api.flickr.com/services/rest/?"
        static let apiKeyParam = "&api_key=25cc612eae16d434c7bdbfe06f66ea70"
        static let downloadImageBase = "https://live.staticflickr.com/"
        
        case flickrLists(latitude: Double, longitude: Double, page: Int)
        case downloadPhoto(server: String, id: String, secret: String)
        
        var stringValue: String {
            switch self {
            case .flickrLists(let lat, let long, let page):
                return "\(Endpoints.base)method=flickr.photos.search\(Endpoints.apiKeyParam)&lat=\(lat)&lon=\(long)&per_page=30&page=\(page)&format=json&nojsoncallback=1"
            case .downloadPhoto(let server, let id, let secret):
                return "\(Endpoints.downloadImageBase)\(server)/\(id)_\(secret)_q.jpg"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }  
    }
    
    class func getFlickrResponse(lat: Double?, long: Double?, completion: @escaping ([FlickrImageResponse]?, Error?) -> Void) {
        
        let page = getRandomPageNumber()
        
        HTTPMethods.taskForGETRequest(url: Endpoints.flickrLists(latitude: lat!, longitude: long!, page: page).url, responseType: FlickrResponse.self) { response, error in
            if let response = response {
                completion(response.photos.photo, nil)
            } else {
                completion([], error)
                print("Fail to get flickrResponse. \(error)")
            }
        }
    }
    
    class func downloadFlickrPhoto(flickrImageResponse: FlickrImageResponse, completionHandler: @escaping (Data?, Error?) -> Void) {
        
        let task = URLSession.shared.dataTask(with: Endpoints.downloadPhoto(server: flickrImageResponse.server!, id: flickrImageResponse.id!, secret: flickrImageResponse.secret!).url) { (data, response, error) in
            
            DispatchQueue.main.async {
                completionHandler(data, nil)
            }
        }
        task.resume()
    }
    
    class func getRandomPageNumber() -> Int {
      
        var flickrData: FlickrData?
        let totalPages = flickrData?.pages ?? 10
        let per_page = flickrData?.perPage ?? 1
        let pageNum = min(totalPages,4000/per_page)
        let randomPage = Int.random(in: 1...pageNum)
        return randomPage
    }
    
}
