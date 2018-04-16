//
//  DBService.swift
//  TrafficAlerter
//
//  Created by Jason Hoffman on 3/14/18.
//  Copyright © 2018 Jason Hoffman. All rights reserved.
//

import Foundation
import Firebase
import MapKit

// Instantiate database
let database = Database.database().reference()

class DBService {
    // Database singleton for use while app is running
    static let instance = DBService()
    
    private var _ref_base = database  // Private reference for database
    private var _ref_users = database.child("users") // Private reference for users in database
    
    // Return private references with public getters
    var ref_base: DatabaseReference {
        return _ref_base
    }
    
    var ref_users: DatabaseReference {
        return _ref_users
    }
    
    // Function to create a Firebase user. Gets uid from Auth and adds new child node to 'users'
    // based on uid
    func createFirebaseDBUser(uid: String, userData: Dictionary<String, Any>) {
        ref_users.child(uid).updateChildValues(userData)
    }
    
    // Function to load a users routes when they log in. Function uses completion handler to
    // pass routes Dictionary as function exits before 'observeSingleEvent'
    func loadUserRoutes(completion: @escaping (_ routes: Dictionary<String,Any>) -> Void ) {
        var routes = [String:Any]() // Empty array to hold routes
        // Get snapshot of data from Firebase
        self.ref_users.observeSingleEvent(of: DataEventType.value) { (snapshot) in
            if let userSnapShot = snapshot.children.allObjects as? [DataSnapshot] { // Unwrap optional
                // Find user in list of users (this would be inefficient in production
                for user in userSnapShot {
                    // Get matching key
                    if (user.key == Auth.auth().currentUser?.uid) {
                        let user = user.value as? [String:Any]
                        if let r = user!["myRoutes"] as? [String:Any] { // Only get myRoutes node from user
                            routes = r
                            completion(routes) // Pass routes to completion handler for use
                        }
                    }
                }
            }
        }
    }
    
    func saveUserRoute(withOrigin origin: CLLocationCoordinate2D, andDestination destination: CLLocationCoordinate2D, named name: String, andAddress address: [String]) {
        self.ref_users.observeSingleEvent(of: DataEventType.value) { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for user in userSnapshot {
                    if (user.key == Auth.auth().currentUser?.uid) {
                        let route = [
                            "name": name,
                            "location": [
                                "origin": [origin.latitude, origin.longitude],
                                "destination": [destination.latitude, destination.longitude]
                            ],
                            "address": address
                        ] as [String : Any]
                        let id = self.createId()
                        let childUpdates = ["/\(user.key)/myRoutes/\(id!)": route]
                        self.ref_users.updateChildValues(childUpdates)
                    }
                }
            }
        }
    }
    
    func createId() -> String? {
        var nums: [String] = []
        for _ in 0...5 {
            nums.append(String(arc4random_uniform(10)))
        }
        return nums.joined()
    }

}
