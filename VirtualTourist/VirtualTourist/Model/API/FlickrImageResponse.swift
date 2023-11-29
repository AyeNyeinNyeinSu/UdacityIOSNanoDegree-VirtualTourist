//
//  FlickrImageResponse.swift
//  VirtualTourist
//
//  Created by Aye Nyein Nyein Su on 24/05/2023.
//

import Foundation

struct FlickrImageResponse: Codable {
    
    let server : String?
    let id : String?
    let secret : String?
    
    enum CodingKeys: String, CodingKey {
        case server
        case id
        case secret
    }
}

struct FlickrData: Codable {
    
    let photo : [FlickrImageResponse]
    let page: Int
    let pages: Int
    let perPage: Int
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        
        case photo
        case page
        case pages
        case perPage = "perpage"
        case total
    }
}

struct FlickrResponse: Codable {
    
    let photos: FlickrData
    let status: String
    
    enum CodingKeys: String, CodingKey {
        
        case photos
        case status = "stat"
    }
}
