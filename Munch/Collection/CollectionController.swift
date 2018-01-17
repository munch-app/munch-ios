//
// Created by Fuxing Loh on 16/1/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class CollectionSelectRootController: UINavigationController, UINavigationControllerDelegate {

    init(placeId: String) {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [CollectionSelectListController(placeId: placeId)]
        self.delegate = self
    }

    // Fix bug when pop gesture is enabled for the root controller
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        self.interactivePopGestureRecognizer?.isEnabled = self.viewControllers.count > 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CollectionSelectListController: UIViewController {
    let placeId: String

    fileprivate let headerView = HeaderView()
    fileprivate let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.separatorInset.left = 24
        tableView.allowsSelection = true
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.sectionHeaderHeight = 44
        tableView.estimatedRowHeight = 50

        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 12))
        return tableView
    }()

    var items: [PlaceCollection] = []

    init(placeId: String) {
        self.placeId = placeId
        super.init(nibName: nil, bundle: nil)

        self.hidesBottomBarWhenPushed = true
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

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.headerView.cancelButton.addTarget(self, action: #selector(actionCancel(_:)), for: .touchUpInside)
        self.headerView.createButton.addTarget(self, action: #selector(actionCreate(_:)), for: .touchUpInside)
        fullLoad(maxSortKey: nil)
    }

    func fullLoad(maxSortKey: String?) {
        MunchApi.collections.list(maxSortKey: maxSortKey, size: 50) { meta, collections in
            if meta.isOk() {
                self.items.append(contentsOf: collections)
                if collections.count == 50, let maxSortKey = collections.last?.collectionId {
                    // More to load
                    self.fullLoad(maxSortKey: maxSortKey)
                } else {
                    self.tableView.reloadData()
                }
            } else {
                self.present(meta.createAlert(), animated: true)
            }
        }
    }

    @objc func actionCancel(_ sender: Any) {
        self.dismiss(animated: true)
    }

    @objc func actionCreate(_ sender: Any) {
        let alert = UIAlertController(title: "Create New Collection", message: "Enter a name for this new collection", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = nil
        }
        alert.addAction(.init(title: "CANCEL", style: .cancel))
        alert.addAction(.init(title: "OK", style: .default) { action in
            let textField = alert.textFields![0]
            var collection = PlaceCollection()
            collection.name = textField.text

            MunchApi.collections.post(collection: collection) { meta, collection in
                if meta.isOk() {
                    self.items = [collection] + self.items
                } else {
                    self.present(meta.createAlert(), animated: true)
                }
            }
        })

        self.present(alert, animated: true, completion: nil)
    }

    class HeaderView: UIView {
        fileprivate let createButton: UIButton = {
            let button = UIButton()
            button.setTitle("CREATE", for: .normal)
            button.setTitleColor(UIColor.black.withAlphaComponent(0.7), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
            button.titleEdgeInsets.right = 24
            button.contentHorizontalAlignment = .right
            return button
        }()
        fileprivate let titleView: UILabel = {
            let titleView = UILabel()
            titleView.text = "Add to Collection"
            titleView.font = .systemFont(ofSize: 17, weight: .medium)
            titleView.textAlignment = .center
            return titleView
        }()

        fileprivate let cancelButton: UIButton = {
            let button = UIButton()
            button.setTitle("CANCEL", for: .normal)
            button.setTitleColor(UIColor.black.withAlphaComponent(0.7), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
            button.titleEdgeInsets.left = 24
            button.contentHorizontalAlignment = .left
            return button
        }()

        init() {
            super.init(frame: CGRect.zero)
            self.addSubview(createButton)
            self.addSubview(titleView)
            self.addSubview(cancelButton)

            self.makeViews()
        }

        private func makeViews() {
            self.backgroundColor = .white

            cancelButton.snp.makeConstraints { make in
                make.top.equalTo(self.safeArea.top)
                make.bottom.equalTo(self)
                make.width.equalTo(90)
                make.left.equalTo(self)
            }

            titleView.snp.makeConstraints { make in
                make.top.equalTo(self.safeArea.top)
                make.height.equalTo(44)
                make.bottom.equalTo(self)
                make.centerX.equalTo(self)
            }

            createButton.snp.makeConstraints { make in
                make.top.equalTo(self.safeArea.top)
                make.bottom.equalTo(self)
                make.width.equalTo(90)
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CollectionSelectListController: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        tableView.register(CollectionSelectListCell.self, forCellReuseIdentifier: "CollectionSelectListCell")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CollectionSelectListCell") as! CollectionSelectListCell
        cell.render(collection: items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = items[indexPath.row]
        if let collectionId = item.collectionId {
            MunchApi.collections.putPlace(collectionId: collectionId, placeId: placeId) { meta in
                if meta.isOk() {
                    self.dismiss(animated: true)
                } else {
                    self.present(meta.createAlert(), animated: true)
                }
            }
        }
    }

    class CollectionSelectListCell: UITableViewCell {
        private let nameLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            label.textColor = UIColor.black.withAlphaComponent(0.75)
            return label
        }()

        private let countLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            label.textColor = UIColor.black.withAlphaComponent(0.75)
            return label
        }()

        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            self.addSubview(nameLabel)
            self.addSubview(countLabel)

            nameLabel.snp.makeConstraints { make in
                make.left.right.equalTo(self).inset(24)
                make.top.equalTo(self).inset(10)
            }

            countLabel.snp.makeConstraints { (make) in
                make.left.right.equalTo(self).inset(24)
                make.top.equalTo(nameLabel.snp.bottom).inset(10)
                make.bottom.equalTo(self).inset(10)
            }
        }


        func render(collection: PlaceCollection) {
            nameLabel.text = collection.name
            countLabel.text = "\(collection.count ?? 0) Places"
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}