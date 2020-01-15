//
//  AppDelegate.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/11/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        let signIn = GIDSignIn.sharedInstance()
        signIn?.clientID = FirebaseApp.app()?.options.clientID
        
        if Auth.auth().currentUser != nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let postsNavigationController = storyboard.instantiateViewController(withIdentifier: "PostsNavigationController")
            window?.rootViewController = postsNavigationController
            window?.makeKeyAndVisible()
        }
        
        requestRecordPermission()
        
        return true
    }
    
    private func requestRecordPermission() {
        let session = AVAudioSession.sharedInstance()
        session.requestRecordPermission { (granted) in
            guard granted == true else {
                print("Error: we need microphone permission") // TODO: display UI to inform
                return
            }
            
            do {
                try session.setCategory(.playAndRecord, mode: .default, options: [])
                try session.overrideOutputAudioPort(.speaker)
                try session.setActive(true, options: [])
            } catch {
                print("Error setting up audio session: \(error)")
            }
        }
    }
    
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url,
                                                 sourceApplication:options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                                                 annotation: [:])
    }
}

