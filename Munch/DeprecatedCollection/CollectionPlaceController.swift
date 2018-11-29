//
// Created by Fuxing Loh on 20/1/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import FirebaseAnalytics

import Toast_Swift
import NVActivityIndicatorView

class CollectionPlaceController: UIViewController, UIGestureRecognizerDelegate {
    private let toastStyle: ToastStyle = {
        var style = ToastStyle()
        style.backgroundColor = UIColor.whisper100
        style.cornerRadius = 5
        style.imageSize = CGSize(width: 20, height: 20)
        style.fadeDuration = 6.0
        style.messageColor = UIColor.black.withAlphaComponent(0.85)
        style.messageFont = UIFont.systemFont(ofSize: 15, weight: .regular)
        style.messageNumberOfLines = 2
        style.messageAlignment = .left

        return style
    }()

    var userId: String?
    var publicContent: Bool
    let collectionId: String

    var placeCollection: PlaceCollection?

    private let headerView = HeaderView()
    fileprivate let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "You haven't added any places."
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    fileprivate let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 18

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = UIColor.white
        collectionView.register(CollectionPlaceCollectionCell.self, forCellWithReuseIdentifier: "CollectionPlaceCollectionCell")
        collectionView.register(CollectionPlaceLoadingCell.self, forCellWithReuseIdentifier: "CollectionPlaceLoadingCell")
        return collectionView
    }()
    var addedPlaces: [[PlaceCollection.AddedPlace]] = []

    init(collectionId: String) {
        self.userId = nil
        self.collectionId = collectionId
        self.publicContent = true
        super.init(nibName: nil, bundle: nil)
    }

    init(collectionId: String, placeCollection: PlaceCollection) {
        self.collectionId = collectionId
        self.placeCollection = placeCollection
        self.userId = placeCollection.userId
        self.publicContent = self.userId != UserProfile.instance?.userId
        super.init(nibName: nil, bundle: nil)
    }

    init(userId: String, collectionId: String) {
        self.userId = userId
        self.collectionId = collectionId
        self.publicContent = self.userId != UserProfile.instance?.userId
        super.init(nibName: nil, bundle: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        Analytics.logEvent(AnalyticsEventViewItemList, parameters: [
            AnalyticsParameterItemCategory: "collection_place" as NSObject,
            AnalyticsParameterItemID: "collection-" + self.collectionId as NSObject
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        self.headerView.backButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
        self.headerView.editButton.addTarget(self, action: #selector(actionEdit(_:)), for: .touchUpInside)


        if publicContent {
            // Load Public
            self.headerView.editButton.isHidden = true

            MunchApi.collections.get(userId: userId, collectionId: self.collectionId) { meta, collection in
                if meta.isOk() {
                    self.placeCollection = collection
                    self.headerView.titleView.text = collection?.name
                    self.collectionView.reloadData()
                } else {
                    self.present(meta.createAlert(), animated: true)
                }
            }
        } else if let placeCollection = self.placeCollection {
            // Load Personal
            self.headerView.titleView.text = placeCollection.name
        } else {
            // Load Personal with Collection Id
            self.userId = nil
            MunchApi.collections.get(collectionId: self.collectionId) { meta, collection in
                if meta.isOk() {
                    self.placeCollection = collection
                    self.headerView.titleView.text = collection?.name
                    self.collectionView.reloadData()
                } else {
                    self.present(meta.createAlert(), animated: true)
                }
            }
        }
    }

    private func initViews() {
        self.view.addSubview(collectionView)
        self.view.addSubview(headerView)
        self.view.addSubview(emptyLabel)

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }

        collectionView.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
            make.top.equalTo(headerView.snp.bottom)
        }

        emptyLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.equalTo(self.view)
        }
    }

    @objc func actionCancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    @objc func actionEdit(_ sender: Any) {
        if publicContent {
            return
        }

        let alert = UIAlertController(title: "Edit Collection", message: "Enter a new name for this collection", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = nil
        }
        alert.addAction(.init(title: "CANCEL", style: .destructive))
        alert.addAction(.init(title: "OK", style: .default) { action in
            let textField = alert.textFields![0]
            let collectionName = textField.text

            MunchApi.collections.get(collectionId: self.collectionId) { meta, collection in
                if meta.isOk(), let collection = collection {
                    var editCollection = collection
                    editCollection.name = collectionName
                    MunchApi.collections.put(collectionId: self.collectionId, collection: editCollection) { meta, collection in
                        if meta.isOk(), let collection = collection {
                            self.placeCollection = collection
                            self.headerView.titleView.text = collection.name
                        } else {
                            self.present(meta.createAlert(), animated: true)
                        }
                    }
                } else {
                    self.present(meta.createAlert(), animated: true)
                }
            }
        })

        self.present(alert, animated: true, completion: nil)
    }

    func deletePlace(placeId: String, placeName: String) {
        MunchApi.collections.deletePlace(collectionId: self.collectionId, placeId: placeId) { metaJSON in
            if metaJSON.isOk() {
                if let collection = self.placeCollection, let name = collection.name {
                    self.view.makeToast("Removed \(placeName) from '\(name)' collection.", image: UIImage(named: "RIP-Toast-Close"), style: self.toastStyle)
                }
                self.addedPlaces = []
                self.collectionView.reloadData()
            } else {
                self.present(metaJSON.createAlert(), animated: true)
            }
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    fileprivate class HeaderView: UIView {
        fileprivate let backButton: UIButton = {
            let button = UIButton()
            button.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
            button.tintColor = .black
            button.imageEdgeInsets.left = 18
            button.contentHorizontalAlignment = .left
            return button
        }()
        fileprivate let titleView: UILabel = {
            let titleView = UILabel()
            titleView.font = .systemFont(ofSize: 17, weight: .medium)
            titleView.textAlignment = .center
            return titleView
        }()
        fileprivate let editButton: UIButton = {
            let button = UIButton()
            button.setTitle("EDIT", for: .normal)
            button.setTitleColor(UIColor.black.withAlphaComponent(0.7), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
            button.titleEdgeInsets.right = 24
            button.contentHorizontalAlignment = .right
            return button
        }()

        override init(frame: CGRect = CGRect.zero) {
            super.init(frame: frame)
            self.initViews()
        }

        private func initViews() {
            self.backgroundColor = .white
            self.addSubview(backButton)
            self.addSubview(titleView)
            self.addSubview(editButton)

            backButton.snp.makeConstraints { make in
                make.top.equalTo(self.safeArea.top)
                make.bottom.equalTo(self)
                make.left.equalTo(self)

                make.width.equalTo(64)
                make.height.equalTo(44)
            }

            titleView.snp.makeConstraints { make in
                make.top.equalTo(self.safeArea.top)
                make.height.equalTo(44)
                make.bottom.equalTo(self)
                make.left.equalTo(backButton.snp.right)
                make.right.equalTo(self).inset(64)
            }

            editButton.snp.makeConstraints { make in
                make.top.equalTo(self.safeArea.top)
                make.bottom.equalTo(self)
                make.right.equalTo(self)

                make.width.equalTo(64)
                make.height.equalTo(44)
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            self.shadow(vertical: 2)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CollectionPlaceController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    var items: [PlaceCollection.AddedPlace] {
        return addedPlaces.joined().map({ $0 })
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return self.items.count
        case 1: return 1 // Loader & Space Filler Cell
        default: return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if (section == 0) {
            return UIEdgeInsets(top: 18, left: 24, bottom: 18, right: 24)
        }
        return .zero
    }

    private var squareWidth: CGFloat {
        return (UIScreen.main.bounds.width - 24 * 3) / 2
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 1 {
            return CGSize(width: UIScreen.main.bounds.width - 24 * 2, height: 40)
        }

        return CGSize(width: self.squareWidth, height: self.squareWidth)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 1 {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionPlaceLoadingCell", for: indexPath)
        }

        let item = self.items[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionPlaceCollectionCell", for: indexPath) as! CollectionPlaceCollectionCell
        cell.render(addedPlace: item, controller: self)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            return
        }

        let item = self.items[indexPath.row]
        if let placeId = item.place.id {
            let controller = PlaceViewController(placeId: placeId)
            self.navigationController!.pushViewController(controller, animated: true)
        }
    }
}

// Lazy Append Loading
extension CollectionPlaceController {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        switch indexPath {
        case [1, 0]:
            self.appendLoad()
        default: break
        }
    }

    private var more: Bool {
        return addedPlaces.isEmpty || !(addedPlaces.last?.isEmpty ?? false)
    }

    private func appendLoad() {
        if self.placeCollection != nil && self.more {
            let loadingCell = self.collectionView.cellForItem(at: .init(row: 0, section: 1)) as? CollectionPlaceLoadingCell
            loadingCell?.startAnimating()

            let maxSortKey = self.addedPlaces.last?.last?.sortKey ?? nil
            MunchApi.collections.listPlace(userId: userId, collectionId: self.collectionId, maxSortKey: maxSortKey, size: 10) { meta, addedPlaces in
                DispatchQueue.main.async {
                    if meta.isOk() {
                        self.addedPlaces.append(addedPlaces)
                        if (self.more) {
                            self.collectionView.reloadData()
                        } else {
                            if (self.items.isEmpty) {
                                self.emptyLabel.isHidden = false

                            }
                            let loadingCell = self.collectionView.cellForItem(at: .init(row: 0, section: 1)) as? CollectionPlaceLoadingCell
                            loadingCell?.stopAnimating()
                            self.collectionView.reloadData()
                        }
                    } else {
                        self.present(meta.createAlert(), animated: true)
                    }
                }
            }
        } else {
            let loadingCell = self.collectionView.cellForItem(at: .init(row: 0, section: 1)) as? CollectionPlaceLoadingCell
            loadingCell?.stopAnimating()
        }
    }
}

fileprivate class CollectionPlaceCollectionCell: UICollectionViewCell {
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        return layer
    }()
    private let imageGradientView: UIView = {
        let imageGradientView = UIView()
        imageGradientView.layer.cornerRadius = 2
        imageGradientView.backgroundColor = .clear
        return imageGradientView
    }()
    private let imageView: ShimmerImageView = {
        let view = ShimmerImageView()
        view.layer.cornerRadius = 2
        view.backgroundColor = UIColor(hex: "F0F0F0")
        return view
    }()
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
        return label
    }()
    private let editLabel: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Account-Three-Dot"), for: .normal)
        button.tintColor = .white
        return button
    }()

    var controller: CollectionPlaceController!
    var addedPlace: PlaceCollection.AddedPlace!

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(imageView)
        self.addSubview(imageGradientView)
        self.addSubview(nameLabel)
        self.addSubview(editLabel)

        imageGradientView.layer.insertSublayer(gradientLayer, at: 0)
        imageGradientView.snp.makeConstraints { make in
            make.bottom.equalTo(self)
            make.left.right.equalTo(self)
            make.height.equalTo(40)
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        nameLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(11)
            make.bottom.equalTo(self).inset(8)
        }

        editLabel.snp.makeConstraints { make in
            make.right.equalTo(self).inset(-1)
            make.top.equalTo(self).inset(5)
        }

        editLabel.addTarget(self, action: #selector(onEditButton(_:)), for: .touchUpInside)
    }

    func render(addedPlace: PlaceCollection.AddedPlace, controller: CollectionPlaceController) {
        self.addedPlace = addedPlace
        self.controller = controller

        imageView.render(sourcedImage: addedPlace.place.images?.get(0))
        nameLabel.text = addedPlace.place.name

        editLabel.isHidden = controller.publicContent
    }

    @objc func onEditButton(_ sender: Any) {
        if let placeId = addedPlace?.place.id, let placeName = addedPlace?.place.name {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { action in
                self.controller.deletePlace(placeId: placeId, placeName: placeName)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.controller.present(alert, animated: true)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.33).cgColor]
        self.gradientLayer.cornerRadius = 2
        self.gradientLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: 40)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class CollectionPlaceLoadingCell: UICollectionViewCell {
    private var indicator: NVActivityIndicatorView!

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.width, height: 40))
        self.indicator = NVActivityIndicatorView(frame: frame, type: .ballBeat, color: .primary700, padding: 0)
        indicator.startAnimating()
        self.addSubview(indicator)

        indicator.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.height.equalTo(40)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimating() {
        self.indicator.startAnimating()
    }

    func stopAnimating() {
        self.indicator.stopAnimating()
    }
}