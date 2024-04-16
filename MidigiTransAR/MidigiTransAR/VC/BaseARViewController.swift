//
//  BaseARViewController.swift
//  MidigiTransAR
//
//  Created by Shashidhar Jagatap on 03/03/24.
//

import UIKit
import ARKit

class BaseARViewController: UIViewController {
    // Container view to hold ARSCNViewController's view
    @IBOutlet weak var containerView: UIView!
    @IBOutlet var scanFloorView: UIView!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var newScanButton: UIButton!
    @IBOutlet var galleryButton: UIButton!
    
    var collectionListVC: ARCollectionList?
    var isImageSelected = false
    var isCollectionViewVisible = false
    
    // Instance of ARSCNViewController
    var arSceneViewController: ARSCNViewController?
    var viewModel = ARSCNViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
    }
    
    // Add a new UIViewController
    func addChildViewController(newViewController: ARCollectionList) {
        // Check if the new view controller already has a parent view controller
        guard newViewController.parent == nil else {
            return 
        }
        
        self.collectionListVC = newViewController
        self.collectionListVC?.viewModel = self.viewModel
        self.collectionListVC?.delegate = self
        self.navigationController?.pushViewController(self.collectionListVC!, animated: true)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    // Method to add ARSCNViewController to the container view
    func addARSceneViewController() {
        if let vc = self.storyboard?.instantiateViewController(identifier: "ARSCNViewController") as? ARSCNViewController {
            self.arSceneViewController = vc
            self.arSceneViewController?.viewModel = self.viewModel
            addChild(arSceneViewController!)
            containerView.addSubview(arSceneViewController!.view)
            arSceneViewController!.view.frame = containerView.bounds
            arSceneViewController!.didMove(toParent: self)
        }
    }
    
    @IBAction func openGalleryAction(_ sender: Any) {
        if let vc = self.storyboard?.instantiateViewController(identifier: "ARCollectionList") as? ARCollectionList {
            self.addChildViewController(newViewController: vc)
        }
    }
    
    @IBAction func newScanAction(_ sender: Any) {
        self.addARSceneViewController()
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.scanFloorView.isHidden = false
        self.arSceneViewController?.removeFromParent()
        self.arSceneViewController = nil
    }
    
    @IBAction func scanfloorAction(_ sender: Any) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            // Camera access already granted
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                self.scanFloorView.isHidden = true
                self.newScanButton.isHidden = false
                self.galleryButton.isHidden = false
                self.addARSceneViewController()
            })
            break
        case .notDetermined:
            // Request camera access
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    // Camera access granted
                    DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                        self.scanFloorView.isHidden = true
                        self.newScanButton.isHidden = false
                        self.galleryButton.isHidden = false
                        self.addARSceneViewController()
                    })
                } else {
                    // Camera access denied
                    DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                        self.scanFloorView.isHidden = false
                        self.newScanButton.isHidden = true
                        self.galleryButton.isHidden = true
                        self.showCameraPermissionAlert()
                    })
                }
            }
        case .denied, .restricted:
            // Camera access denied or restricted
            DispatchQueue.main.async{
                self.showCameraPermissionAlert()
            }
            break
        @unknown default:
            break
        }
    }
    
    private func showCameraPermissionAlert() {
        let alert = UIAlertController(
            title: "Camera Access Denied",
            message: "Please enable camera access in Settings to use this feature.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        present(alert, animated: true, completion: nil)
    }

}

extension BaseARViewController:ARCollectionListDelegate{
    func setSelectedImage(image: UIImage) {
        isImageSelected = true
        isCollectionViewVisible = false
        self.dismiss(animated: true)
        // Update the material of the plane node with the selected image
        arSceneViewController?.setSelectedImage(image: image)
    }
}
