//
//  RemoteImageLoader.swift
//  Bugs
//

import Kingfisher
import UIKit

enum RemoteImageLoader {
    /// Пока грузится URL — `UIActivityIndicator` на `imageView` (Kingfisher).
    static func load(into imageView: UIImageView, placeholderAssetName: String, url: URL?) {
        imageView.kf.cancelDownloadTask()
        imageView.kf.indicatorType = .activity

        guard let url else {
            imageView.image = UIImage(named: placeholderAssetName)
            return
        }

        imageView.kf.setImage(
            with: url,
            placeholder: nil,
            options: [
                .transition(.fade(0.2)),
                .cacheOriginalImage,
            ]
        )
    }

    static func cancelLoad(for imageView: UIImageView) {
        imageView.kf.cancelDownloadTask()
    }
}
