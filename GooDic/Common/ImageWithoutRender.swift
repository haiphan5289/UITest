//
//  ImageWithoutRender.swift
//  GooDic
//
//  Created by ttvu on 6/10/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

/// return an original image, ignores the rendering mode.
class ImageWithoutRender: UIImage {
    override func withRenderingMode(_ renderingMode: UIImage.RenderingMode) -> UIImage {
        return self
    }
}
