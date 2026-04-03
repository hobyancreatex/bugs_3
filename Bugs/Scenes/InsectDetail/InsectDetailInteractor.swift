//
//  InsectDetailInteractor.swift
//  Bugs
//

import Foundation

protocol InsectDetailBusinessLogic: AnyObject {
    func loadDetail(request: InsectDetail.Load.Request)
}

final class InsectDetailInteractor: InsectDetailBusinessLogic {

    var presenter: InsectDetailPresentationLogic?

    private let heroImageAssetName: String

    init(heroImageAssetName: String) {
        self.heroImageAssetName = heroImageAssetName
    }

    func loadDetail(request: InsectDetail.Load.Request) {
        let gallery = (0..<5).map { _ in heroImageAssetName }
        presenter?.presentDetail(
            response: InsectDetail.Load.Response(heroImageAssetName: heroImageAssetName, galleryImageAssetNames: gallery)
        )
    }
}
