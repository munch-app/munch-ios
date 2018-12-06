//
// Created by Fuxing Loh on 17/8/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import Localize_Swift
import Toast_Swift

import RxSwift
import SnapKit
import NVActivityIndicatorView

class CollectionAddPlaceController: UIViewController {
    private let headerView = HeaderView()
    private let tableView = UITableView()

    private let disposeBag = DisposeBag()
    private let collectionDatabase = UserPlaceCollectionDatabase()
    private let itemDatabase = UserPlaceCollectionItemDatabase()

    private var items: [AddToCollectionItem] = [.create, .loading]

    private let place: Place
    private let onDismiss: ((AddToCollectionAction) -> Void)

    init(place: Place, onDismiss: @escaping((AddToCollectionAction) -> Void)) {
        self.place = place
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        self.registerCell()

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.headerView.cancelButton.addTarget(self, action: #selector(onCancelButton(_:)), for: .touchUpInside)

        collectionDatabase.observe().subscribe { event in
            switch event {
            case .next(let items):
                let items = items.map({
                    return AddToCollectionItem.collection($0, self.collectionDatabase.has(collection: $0, place: self.place))
                })
                self.items = [AddToCollectionItem.create] + items
                self.tableView.reloadData()

            case .error(let error):
                self.alert(error: error)
            case .completed:
                return
            }
        }.disposed(by: disposeBag)
    }

    private func initViews() {
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)

        tableView.separatorStyle = .none
        tableView.separatorInset.left = 24
        tableView.allowsSelection = true
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.sectionHeaderHeight = 44
        tableView.estimatedRowHeight = 50

        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 12))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 12))
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.left.right.equalTo(self.view)
        }

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
        }
    }

    @objc func onCancelButton(_ sender: Any) {
        self.onDismiss(AddToCollectionAction.cancel)
        self.dismiss(animated: true)
    }

    private class HeaderView: UIView {
        let titleView = UILabel()
        fileprivate let cancelButton: UIButton = {
            let button = UIButton()
            button.setTitle("CANCEL", for: .normal)
            button.setTitleColor(UIColor(hex: "333333"), for: .normal)
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
            self.addSubview(titleView)
            self.addSubview(cancelButton)

            titleView.text = "Add To Collection".localized()
            titleView.font = .systemFont(ofSize: 17, weight: .regular)
            titleView.textAlignment = .center
            titleView.snp.makeConstraints { make in
                make.centerX.equalTo(self)
                make.top.equalTo(self.safeArea.top)
                make.bottom.equalTo(self)
                make.height.equalTo(44)
            }

            cancelButton.snp.makeConstraints { make in
                make.width.equalTo(90)
                make.top.bottom.equalTo(titleView)
                make.right.equalTo(self)
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

fileprivate enum AddToCollectionItem {
    case create
    case loading
    case collection(UserPlaceCollection, Bool)
}

enum AddToCollectionAction {
    case add(UserPlaceCollection)
    case remove(UserPlaceCollection)
    case cancel
}

extension CollectionAddPlaceController: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        func register(cellClass: UITableViewCell.Type) {
            tableView.register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
        }

        register(cellClass: AddToCollectionCreateCell.self)
        register(cellClass: AddToCollectionItemCell.self)
        register(cellClass: AddToCollectionLoadingCell.self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        func dequeue(cellClass: UITableViewCell.Type) -> UITableViewCell {
            let identifier = String(describing: cellClass)
            return tableView.dequeueReusableCell(withIdentifier: identifier)!
        }

        switch items[indexPath.row] {
        case .create:
            return dequeue(cellClass: AddToCollectionCreateCell.self)
        case .loading:
            return dequeue(cellClass: AddToCollectionLoadingCell.self)
        case let .collection(collection, added):
            let cell = dequeue(cellClass: AddToCollectionItemCell.self) as! AddToCollectionItemCell
            cell.render(collection: collection, added: added)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch items[indexPath.row] {
        case .create:
            self.actionCreate()

        case let .collection(collection, added) where added:
            self.actionRemove(collection: collection)

        case let .collection(collection, added) where !added:
            self.actionAdd(collection: collection)

        default:
            return
        }
    }

    private func actionCreate() {
        let alertController = UIAlertController(title: "Create Collection", message: "Enter name of collection", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "Enter Name"
        }
        alertController.addAction(UIAlertAction(title: "Create", style: .default) { (_) in
            if let name = alertController.textFields?[0].text {
                let collection = UserPlaceCollection(
                        collectionId: nil,
                        userId: nil,
                        sort: nil,
                        name: name,
                        description: nil,
                        image: nil,
                        access: .Public,
                        createdBy: .User,
                        createdMillis: nil,
                        updatedMillis: nil,
                        count: nil
                )
                self.collectionDatabase.create(collection: collection)
            }
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        self.present(alertController, animated: true, completion: nil)
    }

    private func actionAdd(collection: UserPlaceCollection) {
        self.view.makeToastActivity(.center)
        itemDatabase.add(collection: collection, place: place) { error in
            self.view.hideAllToasts()

            if let error = error {
                self.alert(error: error)
                return
            }

            self.collectionDatabase.get(collectionId: collection.collectionId!) { event in
                self.onDismiss(AddToCollectionAction.add(collection))
                self.dismiss(animated: true)
            }
        }
    }

    private func actionRemove(collection: UserPlaceCollection) {
        self.view.makeToastActivity(.center)
        itemDatabase.remove(collection: collection, placeId: place.placeId) { error in
            self.view.hideToastActivity()

            if let error = error {
                self.alert(error: error)
                return
            }

            self.headerView.cancelButton.setTitle("DONE", for: .normal)
            self.makeToast("Removed from \(collection.name)", image: .close)
            self.collectionDatabase.sendLocal()
        }
    }
}

fileprivate class AddToCollectionLoadingCell: UITableViewCell {
    private var indicator: NVActivityIndicatorView!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

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
}

fileprivate class AddToCollectionCreateCell: UITableViewCell {
    private let leftImageView: SizeShimmerImageView = {
        let imageView = SizeShimmerImageView(points: 60, height: 60)
        imageView.tintColor = UIColor.black
        return imageView
    }()

    private let titleView: UILabel = {
        let titleView = UILabel()
        titleView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleView.textColor = .black
        return titleView
    }()

    private let subtitleView: UILabel = {
        let titleView = UILabel()
        titleView.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        titleView.textColor = .black
        return titleView
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(leftImageView)

        let rightView = UIView()
        self.addSubview(rightView)
        rightView.addSubview(titleView)
        rightView.addSubview(subtitleView)

        leftImageView.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(12)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }

        rightView.snp.makeConstraints { make in
            make.left.equalTo(leftImageView.snp.right).inset(-18)
            make.right.equalTo(self).inset(24)
            make.centerY.equalTo(leftImageView)
        }

        titleView.snp.makeConstraints { make in
            make.left.right.equalTo(rightView)
            make.top.equalTo(rightView)
        }

        subtitleView.snp.makeConstraints { make in
            make.left.right.equalTo(rightView)
            make.top.equalTo(titleView.snp.bottom).inset(-2)
            make.bottom.equalTo(rightView)
        }

        leftImageView.render(named: "Collection-CreateNew")
        titleView.text = "Create a new collection".localized()
        subtitleView.text = "Save and share places in Munch".localized()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class AddToCollectionItemCell: UITableViewCell {
    private let leftImageView: SizeShimmerImageView = {
        let imageView = SizeShimmerImageView(points: 60, height: 60)
        return imageView
    }()

    private let titleView: UILabel = {
        let titleView = UILabel()
        titleView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleView.textColor = .black
        return titleView
    }()

    private let subtitleView: UILabel = {
        let titleView = UILabel()
        titleView.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        titleView.textColor = .black
        return titleView
    }()
    private let checkedView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Collection-Checked")
        imageView.tintColor = .black
        return imageView
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(leftImageView)

        let rightView = UIView()
        self.addSubview(rightView)
        rightView.addSubview(titleView)
        rightView.addSubview(subtitleView)
        rightView.addSubview(checkedView)

        leftImageView.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(12)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }

        rightView.snp.makeConstraints { make in
            make.left.equalTo(leftImageView.snp.right).inset(-18)
            make.right.equalTo(checkedView).inset(-18)
            make.centerY.equalTo(leftImageView)
        }

        titleView.snp.makeConstraints { make in
            make.left.right.equalTo(rightView)
            make.top.equalTo(rightView)
        }

        subtitleView.snp.makeConstraints { make in
            make.left.right.equalTo(rightView)
            make.top.equalTo(titleView.snp.bottom).inset(-2)
            make.bottom.equalTo(rightView)
        }

        checkedView.snp.makeConstraints { make in
            make.right.equalTo(self).inset(24)
            make.width.height.equalTo(24)
            make.centerY.equalTo(leftImageView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(collection: UserPlaceCollection, added: Bool) {
        self.checkedView.isHidden = !added
        self.leftImageView.render(image: collection.image)
        self.titleView.text = collection.name
        self.subtitleView.text = "\(collection.count ?? 0) places"
    }
}