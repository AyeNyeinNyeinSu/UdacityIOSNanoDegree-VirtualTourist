//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Aye Nyein Nyein Su on 22/05/2023.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    //var window: UIWindow?

    let dataController = DataController(modelName: "CoreDataModel")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        saveViewContext()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        saveViewContext()
    }

    func saveViewContext() {
        try? dataController.viewContext.save()
    }

}

