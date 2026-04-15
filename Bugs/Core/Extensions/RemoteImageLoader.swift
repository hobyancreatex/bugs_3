//
//  RemoteImageLoader.swift
//  Bugs
//

import Kingfisher
import UIKit

enum RemoteImageLoader {
    /// Только сеть/кэш: до успешной загрузки — индикатор и пустой `imageView`, без ассетов-заглушек.
    /// - Parameters:
    ///   - useBuiltinIndicator: встроенный индикатор Kingfisher в углу `imageView` (для ячейки «Моя коллекция» обычно `false`, см. свой оверлей).
    ///   - onSettled: вызывается после успеха или ошибки (и сразу при `url == nil`).
    static func load(
        into imageView: UIImageView,
        url: URL?,
        animatedTransition: Bool = true,
        applyGrayscale: Bool = false,
        useBuiltinIndicator: Bool = true,
        onSettled: (() -> Void)? = nil
    ) {
        imageView.kf.cancelDownloadTask()
        imageView.kf.indicatorType = useBuiltinIndicator ? .activity : .none

        guard let url else {
            imageView.image = nil
            onSettled?()
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
            onSettled?()
        }
    }

    static func cancelLoad(for imageView: UIImageView) {
        imageView.kf.cancelDownloadTask()
    }
}
