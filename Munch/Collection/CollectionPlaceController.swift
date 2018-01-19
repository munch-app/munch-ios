//
// Created by Fuxing Loh on 20/1/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import NVActivityIndicatorView

class CollectionPlaceController: UIViewController, UIGestureRecognizerDelegate {
    let collectionId: String
    var placeCollection: PlaceCollection?

    private let headerView = HeaderView()
    fileprivate let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "You haven added any places."
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    private let collectionView: UICollectionView = {
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

    init(collectionId: String, placeCollection: PlaceCollection) {
        self.collectionId = collectionId
        self.placeCollection = placeCollection
        super.init(nibName: nil, bundle: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        self.headerView.backButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
        self.headerView.titleView.text = placeCollection?.name
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

        override init(frame: CGRect = CGRect.zero) {
            super.init(frame: frame)
            self.initViews()
        }

        private func initViews() {
            self.backgroundColor = .white
            self.addSubview(backButton)
            self.addSubview(titleView)

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
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            self.hairlineShadow(height: 1.0)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
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
        cell.render(addedPlace: item)
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

    // TODO: Ability to Remove Item
    // TODO: Ability to edit Collection Name
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
        if self.more {
            let loadingCell = self.collectionView.cellForItem(at: .init(row: 0, section: 1)) as? CollectionPlaceLoadingCell
            loadingCell?.startAnimating()

            let maxSortKey = self.addedPlaces.last?.last?.sortKey ?? nil
            MunchApi.collections.listPlace(collectionId: self.collectionId, maxSortKey: maxSortKey, size: 10) { meta, addedPlaces in
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
            layer.frame = CGRect(x: 0, y: 0, width: 50, height: 30)
            layer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.55).cgColor]
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

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)
            self.addSubview(imageView)
            self.addSubview(imageGradientView)
            self.addSubview(nameLabel)

            imageGradientView.layer.insertSublayer(gradientLayer, at: 0)
            imageGradientView.snp.makeConstraints { make in
                make.bottom.equalTo(self)
                make.left.right.equalTo(self)
                make.height.equalTo(30)
            }

            imageView.snp.makeConstraints { make in
                make.edges.equalTo(self)
            }

            nameLabel.snp.makeConstraints { make in
                make.left.right.equalTo(self).inset(11)
                make.bottom.equalTo(self).inset(8)
            }
        }

        func render(addedPlace: PlaceCollection.AddedPlace) {
            imageView.render(sourcedImage: addedPlace.place.images?.get(0))
            nameLabel.text = addedPlace.place.name
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            self.gradientLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: 30)
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