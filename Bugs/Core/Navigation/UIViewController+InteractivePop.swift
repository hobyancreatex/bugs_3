//
//  UIViewController+InteractivePop.swift
//  Bugs
//

import UIKit

extension UIViewController {
    /// Возвращает системный swipe-back после кастомной кнопки Back.
    func restoreInteractivePopGestureIfNeeded() {
        guard let nav = navigationController else { return }
        nav.interactivePopGestureRecognizer?.delegate = nil
        nav.interactivePopGestureRecognizer?.isEnabled = nav.viewControllers.count > 1
    }

    /// Отключает системный swipe-back (например, на экранах с кнопкой «закрыть»).
    func disableInteractivePopGestureIfNeeded() {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
}
