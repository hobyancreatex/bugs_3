//
//  RemoteImageLoader.swift
//  Bugs
//

import Kingfisher
import UIKit

enum RemoteImageLoader {
    /// Только сеть/кэш: до успешной загрузки — индикатор и пустой `imageView`, без ассетов-заглушек.
    static func load(
        into imageView: UIImageView,
        url: URL?,
        animatedTransition: Bool = true,
        applyGrayscale: Bool = false
    ) {
        imageView.kf.cancelDownloadTask()
        imageView.kf.indicatorType = .activity

        guard let url else {
            imageView.image = nil
            return
        }

        var options: KingfisherOptionsInfo = [.cacheOriginalImage]
        if animatedTransition, !applyGrayscale {
            options.append(.transition(.fade(0.2)))
        }
        imageView.kf.setImage(
            with: url,
            placeholder: nil,
            options: options
        ) { result in
            switch result {
            case .success(let value):
                if applyGrayscale, let gray = value.image.applyingAchievementGrayscale() {
                    imageView.image = gray
                }
            case .failure:
                imageView.image = nil
            }
        }
    }

    static func cancelLoad(for imageView: UIImageView) {
        imageView.kf.cancelDownloadTask()
    }
}
