//
//  ViewController.swift
//  MidigiTransAR
//
//  Created by Shashidhar Jagatap on 21/02/24.
//


import SceneKit
import UIKit
import ARKit

class ARSCNViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var imageNode: SCNNode?
    var selectedImage = UIImage(named: "tile1")
    var detectedPlanes = Set<ARAnchor>()
    
    var viewModel:ARSCNViewModel?
    var pinchGestureRecognizer: UIPinchGestureRecognizer!
    var currentScale: CGFloat = 1.0
    
    var width: CGFloat = 10.0
    var height: CGFloat = 10.0
    var dimensionchanged: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configeSceneSession()
        selectedImage = self.viewModel?.paginationData.first
        // Add pan gesture recognizer to the scene view
//        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//        sceneView.addGestureRecognizer(panGesture)
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let imageNode = imageNode else { return }
        
        // Get the translation in the scene view
        let translation = gesture.translation(in: sceneView)
        
        // Update the position of the image node based on the translation
        var newPosition = imageNode.position
        newPosition.x += Float(translation.x / 1000) // Scale translation to match scene dimensions
        newPosition.y -= Float(translation.y / 1000) // Invert y-axis as UIKit's coordinate system is flipped
        imageNode.position = newPosition
        
        // Reset the translation to prevent cumulative translation
        gesture.setTranslation(CGPoint.zero, in: sceneView)
    }
    
    func setSelectedImage(image: UIImage) {
        selectedImage = image
        // Update the material of the plane node with the selected image
        if let planeNode = imageNode {
            let material = SCNMaterial()
            material.diffuse.contents = selectedImage
            planeNode.geometry?.firstMaterial = material
        }
    }
    
    func setSelectedImage(width: CGFloat, height: CGFloat) {
        // Update the material of the plane node with the selected image
        if let planeNode = imageNode {
            // Update the size of the plane geometry
            if let planeGeometry = planeNode.geometry as? SCNPlane {
                planeGeometry.width = width
                planeGeometry.height = height
            }
        }
    }
    
    private func configeSceneSession(){
        DispatchQueue.main.async {
            // Set the view's delegate
            self.sceneView.delegate = self
            
            // Show statistics such as fps and timing information
            //sceneView.showsStatistics = true
            self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
            
            // Create a new scene
            let scene = SCNScene()
            
            // Set the scene to the view
            self.sceneView.scene = scene
            
            // Enable plane detection
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            self.sceneView.session.run(configuration)
        }
    }
    
    @IBAction func scaleAction(_ sender: Any) {
        self.showDimensionAlert()
    }
}

extension ARSCNViewController{
    
    func showDimensionAlert() {
        let alert = UIAlertController(title: "Enter Dimensions", message: "Please enter the width and height in feet for the object.", preferredStyle: .alert)
        
        // Add textfields for width and height
        alert.addTextField { textField in
            textField.placeholder = "Width (feet)"
            textField.keyboardType = .decimalPad // Allowing only numeric input
        }
        alert.addTextField { textField in
            textField.placeholder = "Height (feet)"
            textField.keyboardType = .decimalPad // Allowing only numeric input
        }
        
        // Add action buttons
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            // Handle OK button action here
            if let widthText = alert.textFields?[0].text, let heightText = alert.textFields?[1].text {
                if let width = Double(widthText), let height = Double(heightText) {
                    // Width and height entered by the user
                    print("Width: \(width) feet, Height: \(height) feet")
                    
                    // You can perform further actions with width and height here
                    self.setSelectedImage(width: width, height: height)
                } else {
                    // Handle invalid input
                    print("Invalid input. Please enter valid numeric values.")
                }
            }
        }))
        
        // Present the alert
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: ARSCNViewDelegate
extension ARSCNViewController{
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            // Check if the anchor is of type ARPlaneAnchor
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            self.sceneView.debugOptions = []
            
            // Check if this plane has already been detected
            if self.detectedPlanes.count > 0  {
                if let planeNode = self.imageNode {
                    let material = SCNMaterial()
                    material.diffuse.contents = self.selectedImage
                    planeNode.geometry?.firstMaterial = material
                }
                return // Plane already detected and processed
            }
            
            // Add the plane anchor to the set of detected planes
            self.detectedPlanes.insert(planeAnchor)
            
            // Create a plane geometry with fixed size (10x10 feet)
            let planeGeometry = SCNPlane(width: self.width, height: self.height)//SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            
            // Create a material with the selected image
            let material = SCNMaterial()
            material.diffuse.contents = self.selectedImage
            
            // Apply the material to the plane geometry
            planeGeometry.materials = [material]
            
            // Create a node with the plane geometry
            let planeNode = SCNNode(geometry: planeGeometry)
            
            // Position the plane node based on the anchor
            let planeNodePositionY = Float(planeAnchor.extent.y) / 2 // Adjust this value as needed
            
            planeNode.position = SCNVector3(planeAnchor.center.x, planeNodePositionY, planeAnchor.center.z)
            
            // Rotate the plane to match the orientation of the detected plane
            planeNode.eulerAngles.x = -.pi / 2
            
            // Add the plane node to the scene
            node.addChildNode(planeNode)
            
            // Set imageNode for future reference
            self.imageNode = planeNode
        }
    }
    
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
//        
//        // Check if the updated plane is already detected
//        if detectedPlanes.count > 0 {
//            if let planeNode = imageNode {
//                let material = SCNMaterial()
//                material.diffuse.contents = selectedImage
//                planeNode.geometry?.firstMaterial = material
//            }
//            return // Plane already detected and processed
//        }
//        
//        // Add the plane anchor to the set of detected planes
//        detectedPlanes.insert(planeAnchor)
//        
//        // Create a plane geometry with fixed size (10x10 feet)
//        let planeGeometry = SCNPlane(width: 10.0, height: 10.0)
//        
//        // Create a material with the selected image
//        let material = SCNMaterial()
//        material.diffuse.contents = selectedImage
//        
//        // Apply the material to the plane geometry
//        planeGeometry.materials = [material]
//        
//        // Create a node with the plane geometry
//        let planeNode = SCNNode(geometry: planeGeometry)
//        
//        // Position the plane node based on the anchor
//        let planeNodePositionY = Float(planeAnchor.extent.y) / 2 // Adjust this value as needed
//
//        planeNode.position = SCNVector3(planeAnchor.center.x, planeNodePositionY, planeAnchor.center.z)
//        
//        // Rotate the plane to match the orientation of the detected plane
//        planeNode.eulerAngles.x = -.pi / 2
//        
//        // Add the plane node to the scene
//        node.addChildNode(planeNode)
//        
//        // Set imageNode for future reference
//        imageNode = planeNode
//    }
}

