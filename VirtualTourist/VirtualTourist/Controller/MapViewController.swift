//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Aye Nyein Nyein Su on 22/05/2023.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletePinLabel: UILabel!
    
    var annotations = MKPointAnnotation()
    var editMode: Bool = false
    var pin: Pin!
    var location: CLLocation!
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        mapView.delegate = self
        
        self.navigationItem.rightBarButtonItem = editButtonItem
        deletePinLabel.isHidden = true
       
        setUpFetchedResultsController()
        
        loadFetchedData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setUpFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
       
        fetchedResultsController = nil
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        deletePinLabel.isHidden = !editing
        editMode = editing
    }
    
    func loadFetchedData() {

        guard let fetchedObjects = fetchedResultsController.fetchedObjects else {return}
        //debugPrint(fetchedObjects.count)
        for pin in fetchedObjects {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            mapView.addAnnotation(annotation)
        }
    }
    
    func deletePin(anno: MKAnnotation) {
        
        guard let fetchedObjects = fetchedResultsController.fetchedObjects else {return}
        let coord = anno.coordinate
        for pin in fetchedObjects {
            if pin.latitude == coord.latitude && pin.longitude == coord.longitude {
                dataController.viewContext.delete(pin)
                try! dataController.viewContext.save()
            }
        }
    }
    
    @IBAction func onMapLongGesturePressed(_ sender: UILongPressGestureRecognizer) {
       
        if sender.state != .began {
            return
        }
        
        let cgPoint = sender.location(in: mapView)
        let coord = mapView.convert(cgPoint, toCoordinateFrom: mapView)
        let anno = MKPointAnnotation()
        anno.coordinate = coord
        mapView.addAnnotation(anno)
        
        annotations.coordinate = coord
       
        let newPin = Pin(context: dataController.viewContext)
        newPin.latitude = annotations.coordinate.latitude
        newPin.longitude = annotations.coordinate.longitude
       
        try! dataController.viewContext.save()
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if editMode == false {
            guard let coordinate = view.annotation?.coordinate else { return }
            let lat = coordinate.latitude
            let long = coordinate.longitude
            pin = fetchedResultsController.fetchedObjects?.filter {
                $0.latitude == lat && $0.longitude == long
            }.first

            self.location = CLLocation(latitude: lat, longitude: long)
            
            performSegue(withIdentifier: "goToPhotos", sender: view.annotation?.coordinate)
        } else {
            deletePin(anno: view.annotation!)
            mapView.removeAnnotation(view.annotation!)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToPhotos" {
            let destinationVC = segue.destination as! PhotoViewController
            let coor = sender as! CLLocationCoordinate2D
            let selectedLocation = location
            destinationVC.dataController = dataController
            destinationVC.selectedLocation = selectedLocation
            destinationVC.coordinateSelected = coor
            destinationVC.pin = pin
        }
    }
}

//MARK: - NSFetchedResultsControllerDelegate

extension MapViewController: NSFetchedResultsControllerDelegate {
    
    fileprivate func setUpFetchedResultsController() {
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
       
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch fails, \(error.localizedDescription)")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            let pin = fetchedResultsController.object(at: newIndexPath!)
            addPin(coordinate: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude))
        default: break
        }
    }

    func addPin(coordinate: CLLocationCoordinate2D) {
        let anno = MKPointAnnotation()
        anno.coordinate = coordinate
        mapView.addAnnotation(anno)
    }
}
