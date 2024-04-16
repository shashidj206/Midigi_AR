//
//  ARSCNViewModel.swift
//  MidigiTransAR
//
//  Created by Shashidhar Jagatap on 25/02/24.
//

import Foundation
import UIKit

class ARSCNViewModel {
    var paginationData: [UIImage] = []
    var listData: [UIImage] = []
    let documentsDirectoryURL: URL
    
    init() {
        // Get the URL for the app's documents directory
        documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        loadImages()
    }
    
    // Load images, either from documents directory or default images if no images found
    private func loadImages() {
        if !loadImagesFromDocumentsDirectory() {
            loadDefaultImages()
        }
    }
    
    // Save images to documents directory
    private func saveImages() {
        saveImagesToDocumentsDirectory()
    }
    
    // MARK: - CRUD Operations
    
    // Insert a new image
    func insertImage(_ image: UIImage) {
        listData.insert(image, at: 0)
        //paginationData.append(image)
        saveImages()
    }
    
    func insertPaginationImage(_ image: UIImage) {
        paginationData.insert(image, at: 0)
        saveImages()
    }
    
    // Delete an image at a specific index
    func deleteImage(at index: Int) {
        guard index >= 0 && index < listData.count else {
            return
        }
        listData.remove(at: index)
        saveImages()
    }
    
    // Delete an image at a specific index
    func deletePaginationImage(at index: Int) {
        guard index >= 0 && index < paginationData.count else {
            return
        }
        paginationData.remove(at: index)
        saveImages()
    }
    
    // MARK: - Private Methods
    
    // Load images from documents directory
    @discardableResult
    private func loadImagesFromDocumentsDirectory() -> Bool {
        let imagesDirectoryURL = documentsDirectoryURL.appendingPathComponent("Images")
        
        guard FileManager.default.fileExists(atPath: imagesDirectoryURL.path) else {
            return false
        }
        
        do {
            // Get the list of files in the images directory and sort them
            var fileURLs = try FileManager.default.contentsOfDirectory(at: imagesDirectoryURL, includingPropertiesForKeys: nil)
            fileURLs.sort { $0.lastPathComponent < $1.lastPathComponent }
            
            listData.removeAll()

            for fileURL in fileURLs {
                guard let imageData = FileManager.default.contents(atPath: fileURL.path),
                      let image = UIImage(data: imageData) else {
                    continue
                }
                
                if fileURL.path.contains("pagination") {
                    paginationData.append(image)
                }else{
                    listData.append(image)
                }
            }
            
            if paginationData.isEmpty && !listData.isEmpty {
                paginationData.append(listData[0])
            }
            
            return true
        } catch {
            print("Error loading images from documents directory: \(error.localizedDescription)")
            return false
        }
    }
    
    // Load default images
    private func loadDefaultImages() {
        let defaultImages = ["tile1", "tile2", "tile1","tile1", "tile2", "tile1","tile1", "tile2", "tile1","tile1", "tile2", "tile1"]
        for imageName in defaultImages {
            if let image = UIImage(named: imageName) {
                listData.append(image)
                if paginationData.isEmpty && !listData.isEmpty {
                    paginationData.append(listData[0])
                }
            }
        }
        saveImages()
    }
    
    // Save images to documents directory
    private func saveImagesToDocumentsDirectory() {
        let imagesDirectoryURL = documentsDirectoryURL.appendingPathComponent("Images")
        
        if !FileManager.default.fileExists(atPath: imagesDirectoryURL.path) {
            do {
                try FileManager.default.createDirectory(at: imagesDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error.localizedDescription)")
                return
            }
        }
        
        // Perform file writing operations asynchronously on a background thread
        DispatchQueue.global(qos: .background).async {
            for (index, image) in self.listData.enumerated() {
                let imageName = "image\(index).png"
                let imageURL = imagesDirectoryURL.appendingPathComponent(imageName)
                
                if let imageData = image.pngData() {
                    do {
                        try imageData.write(to: imageURL)
                    } catch {
                        print("Error writing image to file: \(error.localizedDescription)")
                    }
                }
            }
            
            for (index, image) in self.paginationData.enumerated() {
                let imageName = "pagination\(index).png"
                let imageURL = imagesDirectoryURL.appendingPathComponent(imageName)
                
                if let imageData = image.pngData() {
                    do {
                        try imageData.write(to: imageURL)
                    } catch {
                        print("Error writing image to file: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

