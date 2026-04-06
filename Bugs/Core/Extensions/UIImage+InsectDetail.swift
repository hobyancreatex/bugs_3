//
//  UIImage+InsectDetail.swift
//  Bugs
//

import UIKit

extension UIImage {

    /// Иконка удаления из коллекции: ассет `insect_detail_collection_delete`, иначе SF Symbol.
    static func insectDetailDeleteFromCollection() -> UIImage {
        if let img = UIImage(named: "insect_detail_collection_delete") {
            return img.withRenderingMode(.alwaysTemplate)
        }
        let fallback = UIImage(systemName: "trash.fill") ?? UIImage()
        return fallback.withRenderingMode(.alwaysTemplate)
    }
}
