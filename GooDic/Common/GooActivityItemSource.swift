//
//  GooActivityItemSource.swift
//  GooDic
//
//  Created by ttvu on 6/22/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import LinkPresentation

/// an Activity Type Source - used to display a thumbnail
class GooActivityTypeSource: NSObject, UIActivityItemSource {
    
    /// text to share
    var content: String!
    
    /// a thumbnail
    var placeholderImage: UIImage!
    
    
    /// create an activity type source
    /// - Parameters:
    ///   - content: text to share
    ///   - placeholderImage: thumbnail
    convenience init(content: String, placeholderImage: UIImage) {
        self.init()
        self.content = content
        self.placeholderImage = placeholderImage
    }
    
    /// display placeholder content. It doesn't have to contain any real data but should be configured as closely as possible to the actual data object you intend to provide.
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return content ?? ""
    }
    
    /// Actual value you want to share.
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return self.content
    }
    
    /// Thumbnail - Apple states that `For activities that support a preview image, returns a thumbnail preview image for the item.` but since you are pushing an image for your item, should be good to go.
    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        return self.placeholderImage
    }
    
    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metaData = LPLinkMetadata()
        
        let image = Asset.iTunesArtwork.image
        let imageProvider = NSItemProvider(object: image)
        metaData.title = content
        metaData.imageProvider = imageProvider
        metaData.iconProvider = imageProvider
        return metaData
    }
}
