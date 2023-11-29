//
//  ImageCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Aye Nyein Nyein Su on 24/05/2023.
//

import Foundation
import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = String(describing: ImageCollectionViewCell.self)
    var dataController: DataController!
    
    @IBOutlet weak var imageView: UIImageView!
    
    func downloadPhoto(flickrImageResponse: FlickrImageResponse, pin: Pin) {
        FlickrImageClient.downloadFlickrPhoto(flickrImageResponse: flickrImageResponse) { (data, error) in
            guard let data = data else { return }
            
            self.savePhoto(pin: pin, photoData: data)
            self.imageView.image = UIImage(data: data)
            PhotosData.photosData.append(data)
        }
     }
    
    func savePhoto(pin: Pin, photoData: Data) {
        let viewContext = dataController.viewContext
        let pinToUpdate = viewContext.object(with: pin.objectID) as! Pin
        
        viewContext.perform {
            let photo = Photo(context: viewContext)
            photo.pin = pinToUpdate
            photo.imageData = photoData
            photo.creationDate = Date()
            try? viewContext.save()
        }
    }
    
}
