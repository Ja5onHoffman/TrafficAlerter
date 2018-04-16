//
//  LoginViewController.swift
//  TrafficAlerter
//
//  Created by Jason Hoffman on 3/10/18.
//  Copyright © 2018 Jason Hoffman. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class LoginViewController: UIViewController, UITextFieldDelegate, GIDSignInUIDelegate {

    // Outlets to UI elements
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var googleSignIn: GIDSignInButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        view.bindToKeyBoard()
        // Set up delegates
        emailField.delegate = self
        passwordField.delegate = self
        
        // Google sign in UIDelegate so the button works
        GIDSignIn.sharedInstance().uiDelegate = self
        
        // Gesture recognizer for handleScreenTap
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap))
        self.view.addGestureRecognizer(tap)
    }
    
    // Just dismiss if user cancels
    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // If user taps outside of text fields editing ends
    @objc func handleScreenTap(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    // Action to begin GoogleSignIn process
    @IBAction func googleSignInButtonWasPressed(_ sender: Any) {
        GIDSignIn.sharedInstance().signIn()
        // Has it's own view so don't need this one
        dismiss(animated: true, completion: nil)
    }
    
    // For regular login.
    @IBAction func loginButtonWasPressed(_ sender: Any) {
        // Both fields must be filled in for login to work
        if emailField.text != nil && passwordField.text != nil {
            self.view.endEditing(true)
            // Get text from email and password
            if let email = emailField.text, let password = passwordField.text {
                // Firebase Auth sign in
                Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                    if error == nil {
                        if let user = user {
                            // If no error then create user
                            let userData = ["provider": user.providerID] as [String: Any]
                            DBService.instance.createFirebaseDBUser(uid: user.uid, userData: userData)
                        }
                        print("User authenticated with Firebase")
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        // Else check a few different error codes. Just printing
                        // but in production would provide alert (so much code!)
                        if let errorCode = AuthErrorCode(rawValue: error!._code) {
                            switch errorCode {
                            case AuthErrorCode.emailAlreadyInUse:
                                print("That email is already in use")
                            case AuthErrorCode.wrongPassword:
                                print("Wrong password")
                            default:
                                print("An unexpected error occurred. Please try again")
                            }
                        }
                        
                        // If no error and user doesn't exist then we create a new user
                        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                            if error != nil {
                                if let errorCode = AuthErrorCode(rawValue: error!._code) {
                                    switch errorCode {
                                    case AuthErrorCode.emailAlreadyInUse:
                                        print("That email is already in use")
                                    case AuthErrorCode.invalidEmail:
                                        print("That is an invalid email.")
                                    default:
                                        print("An unexpected error occurred")
                                    }
                                }
                            } else {
                                if let user = user {
                                    // User created here
                                    let userData = ["provider": user.providerID] as [String: Any]
                                    DBService.instance.createFirebaseDBUser(uid: user.uid, userData: userData)
                                }
                                
                                print("Successfully created a new user")
                                self.dismiss(animated: true, completion: nil)
                            }
                        })
                    }
                })
            }
        }
    }
}
