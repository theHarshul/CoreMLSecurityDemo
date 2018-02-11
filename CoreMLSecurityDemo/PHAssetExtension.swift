//
//  PHAssetExtension.swift
//  CoreMLSecurityDemo
//
//  Created by Harshul Mulchandani on 12/25/17.
//  Copyright © 2017 Harshul Mulchandani. All rights reserved.
//

import Foundation
import Photos

extension PHAsset {
    func getUIImage() -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: self, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            thumbnail = result!
        })
        return thumbnail
    }
}
