//
//  HomeViewController.swift
//  TrafficAlerter
//
//  Created by Jason Hoffman on 3/10/18.
//  Copyright © 2018 Jason Hoffman. All rights reserved.
//

// Using Apple's MapKit API as well as Firebase for storage
// and GoogleSignIn for third-party Auth
import UIKit
import MapKit
import Firebase
import CoreLocation
import GoogleSignIn

class HomeViewController: UIViewController {
    
    // Outlets to various parts of the UI
    @IBOutlet weak var originTextField: UITextField!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var searchSaveButton: UIButton!
    @IBOutlet weak var centerMapButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    // Instance of CLLocationManager to get user location
    var locationManager:CLLocationManager?
    var regionRadius: CLLocationDistance = 1000
    var selectedItemPlacemark: MKPlacemark? = nil // Unfortunately my placemarks aren't working
    
    var isOrigin: Bool?
    var origin: MKMapItem?
    var destination: MKMapItem?
    var tableView = UITableView()
    var matchingItems: [MKMapItem] = [MKMapItem]()
    var route: MKRoute!
    var activeField: String?
    var routeName: String?
    var userRoutes: [String:Any]?
    
    // A bunch of stuff to set up before view loads
    override func viewDidLoad() {
        super.viewDidLoad()
        saveAndCancelToggle()  // Hides the Save and Cancel buttons at startup to display search button instead
        locationManager = CLLocationManager() // Instantiate location manager
        locationManager?.delegate = self // Setting as delegate so we can use in this view controller
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest  // Lots of battery but no big deal here
        checkLocationAuthStatus()
        checkUserLoggedIn()
        // More delegaates
        mapView.delegate = self
        originTextField.delegate = self
        destinationTextField.delegate = self
        centerMapOnUserLocation()  // Start on user's location

        // If someone is already logged in we can load their saved routes
        if Auth.auth().currentUser != nil || GIDSignIn.sharedInstance().currentUser != nil {
            DBService.instance.loadUserRoutes(completion: { (routes) in
                self.userRoutes = routes
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // If someone is already logged in we can load their saved routes
        if Auth.auth().currentUser != nil || GIDSignIn.sharedInstance().currentUser != nil {
            DBService.instance.loadUserRoutes(completion: { (routes) in
                self.userRoutes = routes
            })
        }
        checkUserLoggedIn()
    }
    
    // If user hasn't authorized location use, app will ask for it
    func checkLocationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager?.startUpdatingLocation()
        } else {
            locationManager?.requestAlwaysAuthorization()
        }
    }
    
    // See if the user is logged in to control text on Sign In button
    func checkUserLoggedIn() {
        if Auth.auth().currentUser != nil || GIDSignIn.sharedInstance().currentUser != nil {
            signInButton.setTitle("Log Out", for: .normal)
        } else {
            signInButton.setTitle("Sign In", for: .normal)
        }
    }
    
    // Center the map
    func centerMapOnUserLocation() {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    // For zooming map to show route when searched
    func centerMapOnLocation(location: MKCoordinateRegion) {
        mapView.setRegion(location, animated: true)
    }
    
    // Allows user to view their saved routes
    @IBAction func myRoutesButtonPressed(_ sender: Any) {
        if (Auth.auth().currentUser == nil) {
            signInAlert() // If not logged in, have to sign in to view/save routes
        } else {
            // If logged in, display view controller with list of saved routes
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let myRoutesVC = storyboard.instantiateViewController(withIdentifier: "MyRoutesController") as! MyRoutesTableViewController

            // Pass userRoutes to next VC for use
            myRoutesVC.userRoutes = userRoutes
            myRoutesVC.tableView.reloadData()
            present(myRoutesVC, animated: true, completion: nil)
        }
    }
    
    // Action that occurs when sign in button is pressed.
    // If the user isn't logged in, the login view controller
    // will be displayed. Otherwise the button serves as a log out button
    @IBAction func signInButtonPressed(_ sender: Any) {
        if Auth.auth().currentUser == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let loginVC = storyboard.instantiateViewController(withIdentifier:"LoginViewController") as? LoginViewController
            present(loginVC!, animated: true, completion: nil)
        } else {
            do {
                GIDSignIn.sharedInstance().signOut()
                try Auth.auth().signOut()
                checkUserLoggedIn()
            } catch (let error) {
                print(error)
            }
        }
    }
    
    // Action that runs when the seach button is pressed.
    // My annotations aren't working so that part is currently
    // commented out
    @IBAction func searchButtonPressed(_ sender: Any) {
        // clear annotations first
        for annotation in mapView.annotations {
            if annotation.isKind(of: MKPointAnnotation.self) {
                mapView.removeAnnotation(annotation)
            }
        }
        
        searchForDirections()
        searchSaveButton.isHidden = true
        saveAndCancelToggle()
    }
    
    // Saves routes if user is logged in. If not an alert prompting
    // the user to log in is displayed
    @IBAction func saveButtonPressed(_ sender: Any) {
        if Auth.auth().currentUser != nil {
            guard let oc = origin?.placemark.coordinate, let dc = destination?.placemark.coordinate else {
                print("no origin or destination")
                return
            }
            saveButtonAlert()  // Alert that prompts user to name their route
            saveAndCancelToggle() // Hides save and cancel buttons again
            searchSaveButton.isHidden = false
        } else {
            signInAlert() // Alerts user to sign in
        }
    }
    
    // Removes all info from map to start over
    @IBAction func cancelButtonPressed(_ sender: Any) {
        saveAndCancelToggle()
        mapView.removeOverlays(mapView.overlays)
        searchSaveButton.isHidden = false
        originTextField.text = ""
        destinationTextField.text = ""
    }
    
    
    @IBAction func centerMapButtonPressed(_ sender: Any) {
        centerMapOnUserLocation()
    }
    
    // Toggles save and cancel buttons with search button
    func saveAndCancelToggle() {
        saveButton.isHidden = !saveButton.isHidden
        cancelButton.isHidden = !cancelButton.isHidden
    }
    
    // Pop up alert telling user to sign in if they want to save/view routes
    func signInAlert() {
        let alert = UIAlertController.init(title: "Sign In", message: "Sign in to save/view your routes", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: false, completion: nil)
    }
    
    // Prompt to name route. Name is saved in data that goes with user's route.
    // Origin, destination, name and addres are all saved here.
    func saveButtonAlert() {
        let nameAlert = UIAlertController(title: "Name Your Route", message: "Choose a name for your route", preferredStyle: UIAlertControllerStyle.alert)
        let textAction = UIAlertAction(title: "Save", style: .default) { (textAction) in
            let nameField = nameAlert.textFields![0] as UITextField
            if let oa = self.originTextField.text, let da = self.destinationTextField.text {
                if (nameField.text != "") {
                    self.routeName = nameField.text
                    // Origin, destination, name and address are all saved here
                    DBService.instance.saveUserRoute(withOrigin: self.origin!.placemark.coordinate, andDestination: self.destination!.placemark.coordinate, named: self.routeName!, andAddress: [oa, da])
                    // If someone is already logged in we can load their saved routes
                    if Auth.auth().currentUser != nil || GIDSignIn.sharedInstance().currentUser != nil {
                        DBService.instance.loadUserRoutes(completion: { (routes) in
                            self.userRoutes = routes
                        })
                    }
                // If no name is provided user is alerted to provide name
                } else {
                    let errorAlert = UIAlertController(title: "Name Required", message: "Please name your route", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action) in
                        self.present(nameAlert, animated: true, completion: nil)
                    }))
                }
            }

        }
        nameAlert.addTextField { (textField) in
            textField.placeholder = "Route name"
            textField.textAlignment = .center
        }
        nameAlert.addAction(textAction)
        present(nameAlert, animated: true, completion: nil)
    }
}

// CLLocationManager required methods
extension HomeViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthStatus()
        if status == .authorizedAlways {
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        }
    }
    
}

// MARK: MKMapViewDelegate

// MKMapView required methods
extension HomeViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        // ??
    }
    
    // This isn't working now, but was supposed to show a green annotation on the origin
    // and a red annotation on the destination
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView()
        print("annotation")
        if let _ = isOrigin {
//            annotationView.tintColor = (io ? UIColor.green : UIColor.red) // Ternary operator to select red or green
            annotationView.pinTintColor = UIColor.green
            return annotationView
        }
        
        annotationView.pinTintColor = UIColor.red
        return annotationView
    }
    
    // Sets up line to display route on map
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let lineRender = MKPolylineRenderer(overlay: self.route.polyline)
        lineRender.strokeColor = UIColor(red: 20/255, green: 160/255, blue: 240/255, alpha: 0.75)
        lineRender.lineWidth = 3
        
        return lineRender
    }
    
    
    // Searches the map using MapKit local search and adds them to a pop up
    // Tableview in a Google-esque but very buggy and choppy fashion
    func mapSearch() {
        // Empty previous search
        matchingItems.removeAll()
        let request = MKLocalSearchRequest()
        
        // Set up search request based on which field is being used
        if (destinationTextField.isFirstResponder) {
            request.naturalLanguageQuery = destinationTextField.text
            request.region = mapView.region
        } else if (originTextField.isFirstResponder) {
            request.naturalLanguageQuery = originTextField.text
            request.region = mapView.region
        }
        
        // Instantiate search using request
        let search = MKLocalSearch(request: request)
        
        // Start search
        search.start { (response, error) in
            if error != nil {
                print(error.debugDescription)
            } else if response!.mapItems.count == 0 {
                print("No results")
            } else {
                
                for mapItem in response!.mapItems {
                    self.matchingItems.append(mapItem as MKMapItem)
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    // placemarks aren't showing
    func dropPinFor(placemark: MKPlacemark) {

        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        mapView.addAnnotation(annotation)
    }
    

    // Once an origin and destination are in place the user
    // can search for directions based that information
    func searchForDirections() {
        guard let o = origin else {
            print("no origin")
            return
            
        }
        guard let d = destination else {
            print("no destination")
            return
        }
        
        // Set up request, origin and destination
        let request = MKDirectionsRequest()
        request.source = o
        request.destination = d
        request.transportType = MKDirectionsTransportType.automobile // Auto only
        
        // Create and calculate directions
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            guard let response = response else {
                print(error.debugDescription)
                return
            }
            
            self.route = response.routes[0] // Just using first possible rather than giving user a choice
            self.mapView.add(self.route.polyline)
            // This works because placemarks conform to MKAnnotation protocol
            self.mapView.showAnnotations([o.placemark, d.placemark], animated: true)
        }
        
    }
}

// MARK: UITextFieldDelegate
extension HomeViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "locationCell")
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tag = 18
        tableView.rowHeight = 60
        
        activeField = (textField.tag == 98 ? "origin" : "destination" )
        
        view.addSubview(tableView)
        animateTableView(shouldShow: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        mapSearch()
        view.endEditing(true)
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Probably not needed
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        matchingItems = []
        tableView.reloadData()
        centerMapOnUserLocation()
        return true
    }
    
    // simplify this?
    func animateTableView(shouldShow: Bool) {
        if shouldShow {
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: 20, y: 170, width: self.view.frame.width - 40, height: self.view.frame.height - 170)
            })
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: 20, y: self.view.frame.height, width: self.view.frame.width - 40, height: self.view.frame.height - 170)
            }, completion: { (finished) in
                for subview in self.view.subviews {
                    if subview.tag == 18 {
                        subview.removeFromSuperview()
                    }
                }
            })
        }
    }
}

// MARK: UITableViewDelegate
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "locationCell")
        let mapItem = matchingItems[indexPath.row]
        cell.textLabel?.text = mapItem.name
        cell.detailTextLabel?.text = mapItem.placemark.title
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var text: String!
        if let t1 = tableView.cellForRow(at: indexPath)?.textLabel?.text, let t2 = tableView.cellForRow(at: indexPath)?.detailTextLabel?.text {
            text = t1 + ", " + t2
        }
        
        if (activeField == "origin") {
            originTextField.text = text
            origin = matchingItems[indexPath.row]
        } else if (activeField == "destination") {
            destinationTextField.text = text
            destination = matchingItems[indexPath.row]
        }
        
        mapView.setCenter(matchingItems[indexPath.row].placemark.coordinate, animated: true)

        if let o = origin?.placemark {
            isOrigin = true
            dropPinFor(placemark: o)
        } else if let d = destination?.placemark {
            isOrigin = false
            dropPinFor(placemark: d)
        }
        
        animateTableView(shouldShow: false)
        print("selected")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if destinationTextField.text == "" {
            animateTableView(shouldShow: false)
        } else if originTextField.text == "" {
            animateTableView(shouldShow: false)
        }
    }
}

