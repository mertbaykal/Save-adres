//
//  ViewController.swift
//  MapApp
//
//  Created by Mert Baykal on 21/09/2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class mapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var nameTextfield: UITextField!
    @IBOutlet weak var noteTextfield: UITextField!
    @IBOutlet weak var mapView: MKMapView!

    var locationManager = CLLocationManager()
    var selectedLongitude = Double()
    var selectedLatitude = Double()

    var selectedName = " "
    var selectedID: UUID?

    var annotationTitle = " "
    var annotationSubtitle = " "
    var annotationLatitude = Double()
    var annotationLongitude = Double()

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self

        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(selectLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)

        if selectedName != " " {
            if let uuid = selectedID {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext

                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuid as CVarArg)
                fetchRequest.returnsObjectsAsFaults = false

                do {
                    let results = try context.fetch(fetchRequest)

                    if results.count > 0 {
                        if let result = results.first as? NSManagedObject {
                            if let name = result.value(forKey: "name") as? String,
                               let note = result.value(forKey: "note") as? String,
                               let latitude = result.value(forKey: "latitude") as? Double,
                               let longitude = result.value(forKey: "longitude") as? Double {

                                annotationTitle = name
                                annotationSubtitle = note
                                annotationLatitude = latitude
                                annotationLongitude = longitude

                                let annotation = MKPointAnnotation()
                                annotation.title = annotationTitle
                                annotation.subtitle = annotationSubtitle
                                let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                annotation.coordinate = coordinate

                                mapView.addAnnotation(annotation)
                                nameTextfield.text = annotationTitle
                                noteTextfield.text = annotationSubtitle
                                
                                locationManager.stopUpdatingLocation()
                                
                                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                let region = MKCoordinateRegion(center: coordinate, span: span)
                                mapView.setRegion(region, animated: true)
                            }
                        }
                    }
                } catch {
                    print("hata")
                }
            }
        } else {
            // Yeni veri ekleme işlemleri burada yapılacak.
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let resueId = "benimAnnatation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: resueId)
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: resueId)
            pinView?.canShowCallout = true // pin baska seylerde gostere bilirmi
            pinView?.tintColor = .blue // pin rengi
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button //anatasyonu buttonun icinde gosterme
        }else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedName != " "{
            
            let requstLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requstLocation) { (placemarkArray, hata) in
                
                if let placemarks = placemarkArray {
                    if placemarks.count > 0 {
                        
                        let yeniPlacemark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: yeniPlacemark) // harita ogesi
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey :  MKLaunchOptionsDirectionsModeDriving]// navigasyonu acmak
                        
                        item.openInMaps(launchOptions: launchOptions) // navigasyonu acmak
                    }
                } 
            }
        }
    }
    

    @objc func selectLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let touchedCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

            selectedLatitude = touchedCoordinate.latitude
            selectedLongitude = touchedCoordinate.longitude

            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinate
            annotation.title = nameTextfield.text
            annotation.subtitle = noteTextfield.text
            mapView.addAnnotation(annotation)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if selectedName == " "{
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }

    @IBAction func saveButton(_ sender: Any) {
        let newUUID = UUID()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext

        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Place", into: context)

        newPlace.setValue(nameTextfield.text, forKey: "name")
        newPlace.setValue(noteTextfield.text, forKey: "note")
        newPlace.setValue(selectedLatitude, forKey: "latitude")
        newPlace.setValue(selectedLongitude, forKey: "longitude")
        newPlace.setValue(newUUID, forKey: "id")

        do {
            try context.save()
            print("kaydedildi")
        } catch {
            print("hata")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("yeniYerOlusturuldu"), object: nil)
        navigationController?.popViewController(animated: true)
        
    }
}
