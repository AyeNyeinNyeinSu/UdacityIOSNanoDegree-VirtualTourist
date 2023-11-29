//
//  PhotoViewController.swift
//  VirtualTourist
//
//  Created by Aye Nyein Nyein Su on 24/05/2023.
//

import Foundation
import UIKit
import CoreData
import MapKit

class PhotoViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var loadNewPhotoButton: UIButton!
    @IBOutlet weak var noPhotoLabel: UILabel!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var selectedLocation: CLLocation!
    var pin: Pin!
    var shouldDownload = true
    var coordinateSelected: CLLocationCoordinate2D!
    var blockOperations = [BlockOperation]()
    var photos: [FlickrImageResponse] = []
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        flowLayout.minimumLineSpacing = 1.0
        flowLayout.minimumInteritemSpacing = 1.0
        
        addAnnotationToMap()
        
        setupFetchedResultsController()
        
        downloadPhotos()
        noPhotoLabel.isHidden = true
    }
    
    func addAnnotationToMap() {
    
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinateSelected
        mapView.addAnnotation(annotation)
        mapView.showAnnotations([annotation], animated: true)
    }
    
    @IBAction func loadNewPhotoPressed(_ sender: UIButton) {
        PhotosData.photosData = []
        photos = []
        
        collectionView.reloadData()
        
        self.dataController.viewContext.performAndWait{
            let pinToDeletePhotos = dataController.viewContext.object(with: self.pin.objectID) as! Pin
            pinToDeletePhotos.photos = []
            try? dataController.viewContext.save()
        }
        
        downloadPhotos()
    }
    
    func downloadPhotos() {
        activityIndicator.startAnimating()
        shouldDownload = pin.photos?.count ?? 0 <= 0
        PhotosData.photosData = []
        
        if shouldDownload {
            FlickrImageClient.getFlickrResponse(lat: coordinateSelected.latitude, long: coordinateSelected.longitude, completion: handleGetFlickrResponse(flickrImageResponseArray:error:))
        } else {
            setupFetchedResultsController()
            let photos = fetchedResultsController.fetchedObjects ?? []
            PhotosData.photosData = photos.map { $0.imageData! }
            activityIndicator.stopAnimating()
        }
    }
    
    func handleGetFlickrResponse(flickrImageResponseArray: [FlickrImageResponse]?, error: Error?) {
        if error != nil {
            showAlert(message: error!.localizedDescription, title: "Invalid Photos Temporarily")
        } else {
            if flickrImageResponseArray!.count == 0 {
                self.noPhotoLabel.isHidden = false
            }
            self.activityIndicator.stopAnimating()
            self.photos = flickrImageResponseArray!         //***
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.setDownloading(false)
            }
        }
    }
    
    func setDownloading(_ downloading: Bool) {
        if downloading {
            loadNewPhotoButton.setTitle("Downloading", for: .disabled)
        } else {
            loadNewPhotoButton.setTitle("New Collection", for: .normal)
        }
        loadNewPhotoButton.isEnabled = !downloading
    }
    
    func showAlert(message: String, title: String) {
        DispatchQueue.main.async {
            let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertVC, animated: true)
        }
    }
    
    //MARK: - func for Delete Photos
    
    func deleteAlert(itemAt indexPath: IndexPath) {
        let alertVC = UIAlertController(title: "Are you sure?", message: "Do you really want to delete this photo?", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.deletePhoto(indexPath: indexPath)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        [deleteAction, cancelAction].forEach { alertVC.addAction($0) }
        present(alertVC, animated: true)
    }
    
    func deletePhoto(indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        
        dataController.viewContext.delete(photoToDelete)
        
        blockOperations.append(BlockOperation(block: {
            PhotosData.photosData.remove(at: indexPath.item)
            if self.shouldDownload {
                self.photos.remove(at: indexPath.item)
            }
            self.collectionView.deleteItems(at: [indexPath])
        }))
    }
    
    //MARK: - MKMapView Delegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}

//MARK: - CollectionView Delegate & DataSource

extension PhotoViewController: UICollectionViewDelegate, UICollectionViewDataSource {
  
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if shouldDownload {
            return photos.count
        }
        return PhotosData.photosData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reusedIdentifier = "photoCollectionViewCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reusedIdentifier, for: indexPath) as! ImageCollectionViewCell
        cell.dataController = self.dataController
        
        if PhotosData.photosData.count > indexPath.item {
            let imageData = PhotosData.photosData[indexPath.item]
            cell.imageView.image = UIImage(data: imageData)
        } else {
            cell.downloadPhoto(flickrImageResponse: photos[indexPath.item], pin: pin)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        deleteAlert(itemAt: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 5) / 3
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 5, left: 2, bottom: 2, right: 0)
    }

}

//MARK: - NSFetchedResultsControllerDelegate

extension PhotoViewController: NSFetchedResultsControllerDelegate {
    
    func setupFetchedResultsController() {
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("error in fetching photos: \(error.localizedDescription)")
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView!.performBatchUpdates({ () -> Void in
            blockOperations.forEach {
                $0.start()
            }
        }, completion: { (finished) -> Void in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
    
    
    
    
}

