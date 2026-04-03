//
//  InsectDetailModels.swift
//  Bugs
//

import Foundation

enum InsectDetail {

    enum Load {
        struct Request {}
        struct Response {
            let heroImageAssetName: String
            let galleryImageAssetNames: [String]
        }
        struct ViewModel {
            let heroImageAssetName: String
            let galleryImageAssetNames: [String]
        }
    }
}
