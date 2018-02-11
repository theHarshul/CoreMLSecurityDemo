//
//  ViewController.swift
//  CoreMLSecurityDemo
//
//  Created by Harshul Mulchandani on 12/25/17.
//  Copyright © 2017 Harshul Mulchandani. All rights reserved.
//

import Photos
import UIKit
import Vision

class ViewController: UIViewController {
    let mobileNetModel = MobileNet()
    let ageNetModel = AgeNet()
    let genderModel = GenderNet()
    let locationModel = RN1015k500()
    var photos = [[UIImage]]()
    var photoData = [[String]]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        requestAuthorization { [weak self] (success) in
            guard let `self` = self else { return }
            
            if success { self.getPhotos() }
        }
    }
    
    func getPhotos() {
        print("getting photos...")
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeHiddenAssets = true
        var allAlbums: [PHFetchResult<PHCollection>] = []
        
        let albumType: [PHAssetCollectionSubtype] = [
            //.albumRegular,
            //        .albumSyncedEvent,
            //        .albumSyncedFaces,
            //        .albumSyncedAlbum,
            //        .albumImported,
            //        .albumMyPhotoStream,
            //        .albumCloudShared,
            //        .smartAlbumGeneric,
            //        .smartAlbumPanoramas,
            //        .smartAlbumVideos,
            //        .smartAlbumFavorites,
            //        .smartAlbumTimelapses,
            .smartAlbumAllHidden,
            //        .smartAlbumRecentlyAdded,
            //        .smartAlbumBursts,
            //        .smartAlbumSlomoVideos,
            //        .smartAlbumUserLibrary,
            //        .smartAlbumSelfPortraits,
            //        .smartAlbumScreenshots,
            //        .smartAlbumDepthEffect,
            //        .smartAlbumLivePhotos
        ]
        
        for type in albumType {
            let smartAlbumsCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: type, options: fetchOptions)
            allAlbums.append(smartAlbumsCollection as! PHFetchResult<PHCollection>)
        }
        
        for result in allAlbums {
            
            result.enumerateObjects({ [weak self] (collection, index, _) in
                
                var imagesInThisAlbum = [UIImage]()
                var dataInThisAlbum = [String]()
                
                if let collection = collection as? PHAssetCollection {
                    let opts = PHFetchOptions()
                    opts.includeHiddenAssets = true
                    
                    print(collection.startDate ?? "nil", collection.endDate ?? "nil", collection.approximateLocation ?? "nil")
                    print(collection.localizedLocationNames)
                    
                    let fetchResult = PHAsset.fetchAssets(in: collection, options: opts)
                    fetchResult.enumerateObjects({[weak self] (asset, _, _) in
                        guard let `self` = self else { return }
                        print(asset.debugDescription)
                        let image = asset.getUIImage()
                        imagesInThisAlbum.append(image)
                        dataInThisAlbum.append(self.predict(image))
                    })
                }
                self?.photos.append(imagesInThisAlbum)
                self?.photoData.append(dataInThisAlbum)
            })
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool)->()) {
        guard PHPhotoLibrary.authorizationStatus() != .authorized else {
            completion(true)
            return
        }
        
        PHPhotoLibrary.requestAuthorization{ (status) in
            
            switch status {
            case .authorized:
                completion(true)
            default:
                completion(false)
            }
        }
        
    }

    func predict(_ image: UIImage) -> String {
        print("predicting...")
        guard let cgImage = image.cgImage else { return ""}
        let totalResult = predictObjects(cgImage) + "\n\n" + predictAge(cgImage) + "\n\n" + predictGender(cgImage) //+ predictLocation(cgImage)
        return totalResult
    }
    
    func predictObjects(_ image: CGImage) -> String {
        var result: String = ""
        guard let visionModel = try? VNCoreMLModel(for: mobileNetModel.model) else { return result}
        let objectRecognitionRequest = VNCoreMLRequest(model: visionModel) { request, error in
            if let observations = request.results as? [VNClassificationObservation] {
                
                let top3 = observations.prefix(through: 2)
                    .map { ($0.identifier, Double($0.confidence)) }
                print("Objects: \(top3)")
                result = "Objects: \(top3)"
            }
            
        }
        try? VNImageRequestHandler(cgImage: image).perform([objectRecognitionRequest])
        return result
    }
    
    func predictAge(_ image: CGImage) -> String {
        var result: String = ""
        guard let ageModel = try? VNCoreMLModel(for: ageNetModel.model) else { return result}
        let ageRequest = VNCoreMLRequest(model: ageModel) { request, error in
            if let observations = request.results as? [VNClassificationObservation] {
                
                let top5 = observations.prefix(through: 4)
                    .map { ($0.identifier, Double($0.confidence)) }
                print("Age: \(top5)")
                result = "Age: \(top5)"
            }
            
        }
        try? VNImageRequestHandler(cgImage: image).perform([ageRequest])
        return result
    }
    
    func predictGender(_ image: CGImage) -> String {
        var result: String = ""
        guard let genderModel = try? VNCoreMLModel(for: genderModel.model) else { return result }
        let genderRequest = VNCoreMLRequest(model: genderModel) { request, error in
            if let observations = request.results as? [VNClassificationObservation] {
                
                // The observations appear to be sorted by confidence already, so we
                // take the top 5 and map them to an array of (String, Double) tuples.
                let top5 = observations.map { ($0.identifier, Double($0.confidence)) }
                print("Gender: \(top5)")
                result = "Gender: \(top5)"
            }
            
        }
        try? VNImageRequestHandler(cgImage: image).perform([genderRequest])
        return result
    }
    
    func predictLocation(_ image: CGImage) -> String {
        var result: String = ""
        guard let locationModel = try? VNCoreMLModel(for: locationModel.model) else { return result}
        let locationRequest = VNCoreMLRequest(model: locationModel) { request, error in
            if let observations = request.results as? [VNClassificationObservation] {
                
                let top5 = observations.prefix(through: 5)
                    .map { ($0.identifier, Double($0.confidence)) }
                print("Location: \(top5)")
                result = "Location: \(top5)"
            }
            
        }
        try? VNImageRequestHandler(cgImage: image).perform([locationRequest])
        return result
    }

}

extension ViewController:UICollectionViewDelegate, UICollectionViewDataSource{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
         let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as? PhotoCell
        let image = photos[indexPath.section][indexPath.item]
        let data = photoData[indexPath.section][indexPath.item]
        
        cell?.imageView.image = image
        cell?.label.text = data
        
        return cell!
    }
    
}


