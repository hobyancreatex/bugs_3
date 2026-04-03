//
//  InsectDetailPresenter.swift
//  Bugs
//

import Foundation

protocol InsectDetailPresentationLogic: AnyObject {
    func presentDetail(response: InsectDetail.Load.Response)
}

final class InsectDetailPresenter: InsectDetailPresentationLogic {

    weak var viewController: InsectDetailDisplayLogic?

    func presentDetail(response: InsectDetail.Load.Response) {
        viewController?.displayDetail(
            viewModel: InsectDetail.Load.ViewModel(
                heroImageAssetName: response.heroImageAssetName,
                galleryImageAssetNames: response.galleryImageAssetNames
            )
        )
    }
}
