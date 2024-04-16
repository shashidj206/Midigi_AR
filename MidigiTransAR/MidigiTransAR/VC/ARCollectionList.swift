//
//  ARCollectionList.swift
//  MidigiTransAR
//
//  Created by Shashidhar Jagatap on 25/02/24.
//

import UIKit

protocol ARCollectionListDelegate {
    func setSelectedImage(image:UIImage)
}

class ARCollectionList: UIViewController{
    
    @IBOutlet weak var detailCollectionView: UICollectionView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    var viewModel:ARSCNViewModel?
    var delegate:ARCollectionListDelegate?
    var deletePressed:Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        setupCollectionView()
    }
    
    @objc func pageControlValueChanged(_ sender: UIPageControl) {
        let newIndexPath = IndexPath(item: sender.currentPage, section: 0)
        detailCollectionView.scrollToItem(at: newIndexPath, at: .centeredHorizontally, animated: true)
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }

        // Get the index path of the long pressed cell
        if self.deletePressed == false {
            self.deletePressed = true
            self.detailCollectionView.reloadData()
        }else{
            self.deletePressed = false
            self.detailCollectionView.reloadData()
        }
    }
    
    private func setupCollectionView() {
        // Register the header view class
        detailCollectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "YourHeaderReuseIdentifier")

        detailCollectionView.backgroundColor = .white
        detailCollectionView.delegate = self
        detailCollectionView.dataSource = self
        detailCollectionView.collectionViewLayout = createCollectionViewLayout()
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        detailCollectionView.addGestureRecognizer(longPressGesture)
    }
    
    private func showAlertOnSelectionForIndex(index:Int, needToInsert:Bool){
        let alert = UIAlertController(title: "Replace Item", message: "Are you sure you want to replace this item?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Replace", style: .destructive, handler: { _ in
            if needToInsert {
                if let image = self.viewModel?.listData[index]{
                    self.delegate?.setSelectedImage(image: image)
                    self.viewModel?.insertPaginationImage(image)
                    self.navigationController?.popViewController(animated: true)
                }
            }else{
                if let image = self.viewModel?.paginationData[index]{
                    self.delegate?.setSelectedImage(image: image)
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
    private func showAlertOnDelectionForIndex(indexPath:IndexPath){
        let alert = UIAlertController(title: "Delete Item", message: "Are you sure you want to delete this item?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ _ in
            self.deletePressed = false
            self.detailCollectionView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.deletePressed = false
            if indexPath.section == 0 {
                self.viewModel?.paginationData.remove(at: indexPath.row)
            }else{
                self.viewModel?.deleteImage(at: indexPath.row)
            }
            self.detailCollectionView.reloadData()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func openPhotos(_ sender: Any) {
        self.openGallery()
    }
}

extension ARCollectionList: TileCollectionViewCellDelegate {
    func tileCellDidTapDelete(_ cell: TileCollectionViewCell) {
        guard let indexPath = detailCollectionView.indexPath(for: cell) else { return }
        self.showAlertOnDelectionForIndex(indexPath: indexPath)
    }
}


extension ARCollectionList: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return viewModel?.paginationData.count ?? 0
        default:
            return viewModel?.listData.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TileCollectionViewCell", for: indexPath) as! TileCollectionViewCell
        if let vm = viewModel{
            cell.tileImage.contentMode = .scaleToFill
            cell.deleteButtonImage.isHidden = !self.deletePressed

            if indexPath.section == 0 {
                cell.tileImage.image = vm.paginationData[indexPath.row]
            }else{
                cell.tileImage.image = vm.listData[indexPath.row]
                cell.delegate = self
            }
            cell.layer.cornerRadius = 8
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.deletePressed {
            self.showAlertOnDelectionForIndex(indexPath: indexPath)
        }else{
            self.showAlertOnSelectionForIndex(index: indexPath.row,
                                              needToInsert:(indexPath.section == 0) ? false : true)
        }
    }
}

extension ARCollectionList: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            fatalError("Invalid supplementary view type")
        }
        
        // Create a header view
        let headerView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "YourHeaderReuseIdentifier", // Provide the appropriate identifier
            for: indexPath
        )
        
        // Remove any existing subviews from the header view
        headerView.subviews.forEach { $0.removeFromSuperview() }
        
        // Create a UILabel and add it to the header view
        let label = UILabel(frame: CGRect(x: 16, y: 0, width: headerView.bounds.width - 32, height: headerView.bounds.height))
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.textColor = UIColor.black // Customize label appearance as needed
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold) // Adjust font size and weight
        label.textAlignment = .left
        headerView.addSubview(label)
        
        // Set the title for the header view based on the section index
        if indexPath.section == 0 {
            label.text = "Recently Used"
        } else {
            label.text = "All Collection"
        }
        
        return headerView
    }

    private func createCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { (section, _) -> NSCollectionLayoutSection? in
            if section == 0 {
                // item
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .fractionalHeight(1)
                    )
                )
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)

                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .estimated(450),
                        heightDimension: .absolute(360)
                    ),
                    subitem: item,
                    count: 1
                )
                
                group.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0)
                
                // section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 10, trailing: 5)
                section.orthogonalScrollingBehavior = .continuous
                
                // Add section header
                let headerItemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(44) // Adjust the height as needed
                )
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerItemSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [headerItem]
                // return
                return section
                
            } else if section == 1 {
                // item
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1/2),
                        heightDimension: .fractionalHeight(1)
                    )
                )
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 5, trailing: 5)
                
                // group
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .absolute(200)
                    ),
                    subitem: item,
                    count: 3
                )
                group.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0)
                
                // section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
                
                // Add section header
                let headerItemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(44) // Adjust the height as needed
                )
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerItemSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [headerItem]
                
                // return
                return section
            }
            return nil
        }
    }
}

extension ARCollectionList: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Function to open the photo gallery
    func openGallery() {
        // Create and configure the loading indicator
        loadingIndicator.isHidden = false
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        
        // Present the image picker controller
        DispatchQueue.main.async {
            self.present(imagePicker, animated: false) {
                // Dismiss loading indicator once image picker is presented
                self.loadingIndicator.stopAnimating()
                self.loadingIndicator.isHidden = true
            }
        }
    }
    
    // UIImagePickerControllerDelegate method to handle when an image is picked
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.viewModel?.insertImage(pickedImage)
            self.detailCollectionView.reloadData()
        }
        
        picker.dismiss(animated: true, completion: nil) // Dismiss the picker
    }
    
    // UIImagePickerControllerDelegate method to handle when the user cancels picking an image
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil) // Dismiss the picker
    }
}

