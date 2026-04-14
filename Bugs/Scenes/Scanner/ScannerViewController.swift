//
//  ScannerViewController.swift
//  Bugs
//

import AVFoundation
import UIKit

/// Экран сканера: превью камеры, затемнение с вырезом, нижние кнопки. Вью не связываются друг с другом — только с корневым view / safe area.
final class ScannerViewController: UIViewController {

    /// Зона под нижний ряд: отступ 20 + высота 62 + зазор до выреза.
    private let bottomReservedForLayout: CGFloat = 20 + 62 + 24

    private let previewBox: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .black
        v.isUserInteractionEnabled = false
        return v
    }()

    private let previewLayer = AVCaptureVideoPreviewLayer()

    private let dimOverlay = ScannerMaskedDimOverlayView()
    private let dashBorder = ScannerCutoutDashBorderView()

    private let infoButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let galleryButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let shutterButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let flashButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private nonisolated(unsafe) let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "bugs.scanner.capture")
    private var photoOutput: AVCapturePhotoOutput?
    /// Вспышка только в момент съёмки (не фонарик).
    private var isFlashOnForCapture = false
    private weak var galleryLoaderHost: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        overrideUserInterfaceStyle = .dark

        dimOverlay.bottomReservedHeight = bottomReservedForLayout
        dashBorder.bottomReservedHeight = bottomReservedForLayout
        dimOverlay.onTapDimmedArea = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(previewBox)
        view.addSubview(dimOverlay)
        view.addSubview(dashBorder)
        view.addSubview(infoButton)
        view.addSubview(closeButton)
        view.addSubview(galleryButton)
        view.addSubview(shutterButton)
        view.addSubview(flashButton)

        NSLayoutConstraint.activate([
            previewBox.topAnchor.constraint(equalTo: view.topAnchor),
            previewBox.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewBox.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewBox.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            dimOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dashBorder.topAnchor.constraint(equalTo: view.topAnchor),
            dashBorder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dashBorder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dashBorder.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            infoButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            infoButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            infoButton.widthAnchor.constraint(equalToConstant: 24),
            infoButton.heightAnchor.constraint(equalToConstant: 24),

            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            shutterButton.widthAnchor.constraint(equalToConstant: 62),
            shutterButton.heightAnchor.constraint(equalToConstant: 62),

            galleryButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            galleryButton.trailingAnchor.constraint(equalTo: shutterButton.leadingAnchor, constant: -40),
            galleryButton.widthAnchor.constraint(equalToConstant: 56),
            galleryButton.heightAnchor.constraint(equalToConstant: 56),

            flashButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            flashButton.leadingAnchor.constraint(equalTo: shutterButton.trailingAnchor, constant: 40),
            flashButton.widthAnchor.constraint(equalToConstant: 56),
            flashButton.heightAnchor.constraint(equalToConstant: 56),
        ])

        previewLayer.videoGravity = .resizeAspectFill
        previewBox.layer.addSublayer(previewLayer)

        configureButtonImages()
        closeButton.accessibilityLabel = L10n.string("scanner.close.accessibility")
        infoButton.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        galleryButton.addTarget(self, action: #selector(galleryTapped), for: .touchUpInside)
        shutterButton.addTarget(self, action: #selector(shutterTapped), for: .touchUpInside)
        flashButton.addTarget(self, action: #selector(flashTapped), for: .touchUpInside)

        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = previewBox.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applySubscriptionStatusForAppearance()
        navigationController?.setNavigationBarHidden(true, animated: animated)
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disableInteractivePopGestureIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        restoreInteractivePopGestureIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideGalleryLoader()
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    private func configureSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.sessionQueue.async { self?.configureSession() }
                }
            }
            return
        default:
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .photo

        for input in Array(session.inputs) {
            session.removeInput(input)
        }
        for output in Array(session.outputs) {
            session.removeOutput(output)
        }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        let output = AVCapturePhotoOutput()
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return
        }
        session.addOutput(output)
        photoOutput = output
        session.commitConfiguration()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.previewLayer.session = self.session
        }
    }

    private func configureButtonImages() {
        closeButton.setImage(Self.scaledAssetImage(named: "scanner_close", side: 32, template: false), for: .normal)
        infoButton.setImage(Self.scaledAssetImage(named: "scanner_info", side: 24, template: false), for: .normal)
        galleryButton.setImage(Self.scaledAssetImage(named: "scanner_gallery", side: 56, template: false), for: .normal)
        shutterButton.setImage(Self.scaledAssetImage(named: "scanner_shutter", side: 62, template: false), for: .normal)
        updateFlashButtonImage()
    }

    private static func scaledAssetImage(named: String, side: CGFloat, template: Bool) -> UIImage? {
        guard let img = UIImage(named: named) else { return nil }
        return renderImage(img, size: CGSize(width: side, height: side), template: template)
    }

    private static func renderImage(_ image: UIImage, size: CGSize, template: Bool) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UITraitCollection.current.displayScale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }.withRenderingMode(template ? .alwaysTemplate : .alwaysOriginal)
    }

    private func updateFlashButtonImage() {
        let name = isFlashOnForCapture ? "scanner_flash_on" : "scanner_flash_off"
        flashButton.setImage(Self.scaledAssetImage(named: name, side: 56, template: false), for: .normal)
    }

    @objc
    private func infoTapped() {
        let tips = ScannerTipsViewController()
        tips.modalPresentationStyle = .pageSheet
        if let sheet = tips.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(tips, animated: true)
    }

    @objc
    private func closeTapped() {
        dismiss(animated: true)
    }

    @objc
    private func galleryTapped() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        showGalleryLoader()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            picker.modalPresentationStyle = .fullScreen
            self.present(picker, animated: true) { [weak self] in
                self?.hideGalleryLoader()
            }
        }
    }

    private func showGalleryLoader() {
        guard galleryLoaderHost == nil else { return }
        let host = UIView()
        host.translatesAutoresizingMaskIntoConstraints = false
        host.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        host.isUserInteractionEnabled = true

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = .white
        spinner.startAnimating()
        host.addSubview(spinner)

        view.addSubview(host)
        NSLayoutConstraint.activate([
            host.topAnchor.constraint(equalTo: view.topAnchor),
            host.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: host.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: host.centerYAnchor),
        ])
        view.bringSubviewToFront(host)
        view.bringSubviewToFront(closeButton)
        view.bringSubviewToFront(infoButton)
        galleryLoaderHost = host
    }

    private func hideGalleryLoader() {
        galleryLoaderHost?.removeFromSuperview()
        galleryLoaderHost = nil
    }

    @objc
    private func shutterTapped() {
        guard let out = photoOutput else { return }
        let wantFlash = isFlashOnForCapture
        sessionQueue.async { [weak self] in
            guard let self else { return }
            let settings = AVCapturePhotoSettings()
            if wantFlash, out.supportedFlashModes.contains(.on) {
                settings.flashMode = .on
            } else {
                settings.flashMode = .off
            }
            out.capturePhoto(with: settings, delegate: self)
        }
    }

    @objc
    private func flashTapped() {
        isFlashOnForCapture.toggle()
        updateFlashButtonImage()
    }
}

extension ScannerViewController: AVCapturePhotoCaptureDelegate {

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data)
        else {
            return
        }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let progress = RecognitionProgressViewController(backgroundImage: image)
            self.navigationController?.pushViewController(progress, animated: true)
        }
    }
}

extension ScannerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let picked = info[.originalImage] as? UIImage
        picker.dismiss(animated: true) { [weak self] in
            guard let self, let picked else { return }
            let progress = RecognitionProgressViewController(backgroundImage: picked)
            self.navigationController?.pushViewController(progress, animated: true)
        }
    }
}
