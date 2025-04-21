//
//  CoachApp.swift
//  Coach
//
//  Created by Allen Liang on 10/4/24.
//

import SwiftUI
import SwiftData

@main
struct CoachApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        
        WindowGroup {
            LibraryView()

            
//            GolfTrackerResearch()
//                .onAppear() {
//                    if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
//                        print("Documents Directory: \(documentsPath)")
//                    }
//                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window:UIWindow?) -> UIInterfaceOrientationMask {
            return AppDelegate.orientationLock
    }
    
    static func flipOrientation() {
        if orientationLock == .portrait {
            setOrientation(.landscapeRight)
        } else {
            setOrientation(.portrait)
        }
    }
    
    static func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            print("No active window scene found")
            return
        }
        
        orientationLock = orientation
        
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
        UIViewController.attemptRotationToDeviceOrientation()
    }
}


struct OrientationController: UIViewControllerRepresentable {
    class Coordinator: NSObject {
        var parent: OrientationController

        init(_ parent: OrientationController) {
            self.parent = parent
        }
    }

    func makeUIViewController(context: Context) -> OrientationViewController {
        return OrientationViewController()
    }

    func updateUIViewController(_ uiViewController: OrientationViewController, context: Context) {
        // Use this to trigger updates to the supported orientations dynamically
        uiViewController.setNeedsUpdateOfSupportedInterfaceOrientations()
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
}

class OrientationViewController: UIViewController {
    // Override supported orientations
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return isLandscapeLocked ? .landscape : .all
    }

    // Flag to toggle orientation
    var isLandscapeLocked = false {
        didSet {
            setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}


import UIKit

class OrientationManager {
    
}
