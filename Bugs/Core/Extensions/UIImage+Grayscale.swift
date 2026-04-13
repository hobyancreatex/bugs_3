//
//  UIImage+Grayscale.swift
//  Bugs
//

import UIKit
import CoreImage

extension UIImage {

    /// Ч/б через `CIColorControls` (насыщенность 0).
    func applyingAchievementGrayscale() -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        guard let filter = CIFilter(name: "CIColorControls") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(0.0, forKey: kCIInputSaturationKey)
        guard let output = filter.outputImage else { return nil }
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cg = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cg, scale: scale, orientation: imageOrientation)
    }
}
