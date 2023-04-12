//
//  CacheManager.swift
//  BoxOffice
//
//  Created by Muri, Rowan on 2023/04/11.
//

import UIKit

final class CacheManager {
    static let shared = CacheManager()
    private let storage = NSCache<NSString, UIImage>()
    
    private init() {
        storage.countLimit = 10
    }
    
    func store(image: UIImage, urlString: String) {
        let key = NSString(string: urlString)
        self.storage.setObject(image, forKey: key)
    }
    
    func cachedImage(urlString: String) -> UIImage? {
        let cachedKey = NSString(string: urlString)
        if let cachedImage = storage.object(forKey: cachedKey) {
            return cachedImage
        }
        return nil
    }
}
