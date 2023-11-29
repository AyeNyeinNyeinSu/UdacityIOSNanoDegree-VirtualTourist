//
//  SceneDelegate.swift
//  VirtualTourist
//
//  Created by Aye Nyein Nyein Su on 22/05/2023.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.dataController.load()
        
        let navigationController = window?.rootViewController as! UINavigationController
        let mapViewController = navigationController.topViewController as! MapViewController
        mapViewController.dataController = appDelegate.dataController
    }

    


}

