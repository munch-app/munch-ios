////
//// Created by Fuxing Loh on 19/8/18.
//// Copyright (c) 2018 Munch Technologies. All rights reserved.
////
//
//import Foundation
//import UIKit
//import SnapKit
//
//import RxSwift
//import Moya
//
//import Toast_Swift
//import Localize_Swift
//import NVActivityIndicatorView
//
//class CollectionPlaceController: UIViewController {
//    fileprivate let headerView = CollectionPlaceHeaderView()
//    fileprivate let tableView = UITableView()
//    fileprivate let collectionId: String
//    fileprivate var collection: UserPlaceCollection?
//
//    fileprivate let loader = CollectionPlaceLoader()
//    fileprivate let provider = MunchProvider<UserPlaceCollectionService>()
//    fileprivate let disposeBag = DisposeBag()
//
//    init(collectionId: String) {
//        self.collectionId = collectionId
//        super.init(nibName: nil, bundle: nil)
//
//        self.registerCells()
//        self.addTargets()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        // Make navigation bar transparent, bar must be hidden
//        navigationController?.setNavigationBarHidden(true, animated: false)
//        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
//        navigationController?.navigationBar.shadowImage = UIImage()
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.view.addSubview(tableView)
//        self.view.addSubview(headerView)
//
//        headerView.snp.makeConstraints { maker in
//            maker.top.left.right.equalTo(self.view)
//        }
//
//        tableView.snp.makeConstraints { maker in
//            maker.top.equalTo(headerView.snp.bottom)
//            maker.bottom.left.right.equalTo(self.view)
//        }
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
//// MARK: Add Targets
//extension CollectionPlaceController: UIGestureRecognizerDelegate {
//    func addTargets() {
//        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
//        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
//
//        self.headerView.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)
////        self.headerView.editButton.addTarget(self, action: #selector(onEditButton(_:)), for: .touchUpInside)
//    }
//
//    //    func onActionEdit() {
////        let alertController = UIAlertController(title: "Edit Collection", message: "Enter name of collection", preferredStyle: .alert)
////        alertController.addTextField { (textField) in
////            textField.placeholder = "Enter Name"
////        }
////        alertController.addAction(UIAlertAction(title: "Update", style: .default) { (_) in
////            if let name = alertController.textFields?[0].text {
////                self.view.makeToastActivity(.center)
////
////                var collection = self.collection!
////                collection.name = name
////                self.collectionDatabase.update(collection: collection).subscribe { event in
////                    switch event {
////                    case let .success(collection):
////                        self.headerView.titleView.text = collection.name
////                        self.view.hideToastActivity()
////
////                    case let .error(error):
////                        self.alert(error: error)
////                    }
////                }.disposed(by: self.disposeBag)
////            }
////        })
////        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
////        self.present(alertController, animated: true, completion: nil)
////    }
////
////    func onActionDelete() {
////        let name: String = collection!.name
////        let alertController = UIAlertController(title: "Delete Collection", message: "Delete '\(name)' Collection", preferredStyle: .alert)
////        alertController.addAction(UIAlertAction(title: "Confirm", style: .destructive) { (_) in
////            self.view.makeToastActivity(.center)
////
////            self.collectionDatabase.delete(collection: self.collection!).subscribe { event in
////                switch event {
////                case .success:
////                    self.navigationController?.popViewController(animated: true)
////
////                case let .error(error):
////                    self.alert(error: error)
////                }
////            }.disposed(by: self.disposeBag)
////        })
////        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
////
////        self.present(alertController, animated: true, completion: nil)
////    }
//
//    @objc func onBackButton(_ sender: Any) {
//        navigationController?.popViewController(animated: true)
//    }
//
//    @objc func onEditButton(_ sender: Any) {
//        guard isUser, collection?.createdBy == UserPlaceCollection.CreatedBy.User else {
//            return
//        }
//
//        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//        alert.addAction(UIAlertAction(title: "Edit Name", style: .default, handler: { action in
//            self.onActionEdit()
//        }))
//        alert.addAction(UIAlertAction(title: "Delete Collection", style: .destructive, handler: { action in
//            self.onActionDelete()
//        }))
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//
//        self.present(alert, animated: true)
//    }
//
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return true
//    }
//}
//
//// MARK: Register Cells
//extension CollectionPlaceController: UITableViewDataSource, UITableViewDelegate {
//    func registerCells() {
//        self.tableView.delegate = self
//        self.tableView.dataSource = self
//
//        tableView.register(type: UserPlaceCollectionLoadingCell.self)
//        tableView.register(type: UserPlaceCollectionItemCell.self)
//        tableView.register(type: UserPlaceCollectionEmptyCell.self)
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return items.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        return UITableViewCell()
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//
//        // RIP
//    }
//
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
////        switch items[indexPath.row] {
////        case .loading:
////            self.loader?.loadMore()
////
////        case let .place(item, place):
////            (cell as? UserPlaceCollectionItemCell)?.render(item: item, place: place) {
////                self.actionMore(item: item)
////            }
////        default:
////            return
////        }
//    }
//
////    private func actionMore(item: UserPlaceCollection.Item) {
////        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
////        alert.addAction(UIAlertAction(title: "Remove", style: .default, handler: { action in
////            self.actionRemove(item: item)
////        }))
////        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
////
////        self.present(alert, animated: true)
////    }
////
////    private func actionRemove(item: UserPlaceCollection.Item) {
////        self.view.makeToastActivity(.center)
////
////        guard let collection = collection else {
////            return
////        }
////
////        itemDatabase.remove(collection: collection, placeId: item.placeId) { error in
////            self.view.hideToastActivity()
////
////            if let error = error {
////                self.alert(error: error)
////                return
////            }
////            self.makeToast("Removed from \(collection.name)", image: .close)
////        }
////    }
//}
//
//fileprivate class CollectionPlaceHeaderView: UIView {
//    fileprivate let backButton: UIButton = {
//        let backButton = UIButton()
//        backButton.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
//        backButton.tintColor = .black
//        backButton.imageEdgeInsets.left = 18
//        backButton.contentHorizontalAlignment = .left
//        return backButton
//    }()
//    fileprivate let titleView = UILabel(style: .navHeader)
//
////        fileprivate let editButton: UIButton = {
////            let button = UIButton()
////            button.setTitle("EDIT", for: .normal)
////            button.setTitleColor(UIColor(hex: "333333"), for: .normal)
////            button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
////            button.titleEdgeInsets.right = 24
////            button.contentHorizontalAlignment = .right
////            return button
////        }()
////
//    override init(frame: CGRect = .zero) {
//        super.init(frame: frame)
//        self.backgroundColor = .white
//        self.addSubview(titleView)
//        self.addSubview(backButton)
////        self.addSubview(editButton)
//
//        titleView.snp.makeConstraints { make in
//            make.top.equalTo(self.safeArea.top)
//            make.bottom.equalTo(self)
//
//            make.centerX.equalTo(self)
//            make.height.equalTo(44)
//        }
//
//        backButton.snp.makeConstraints { make in
//            make.top.bottom.equalTo(titleView)
//            make.left.equalTo(self)
//            make.width.equalTo(64)
//        }
//
////        editButton.snp.makeConstraints { make in
////            make.top.equalTo(self.safeArea.top)
////            make.bottom.equalTo(self)
////
////            make.right.equalTo(self)
////            make.width.equalTo(90)
////        }
//    }
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        self.hairlineShadow(height: 2.0)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
////class UserPlaceCollectionController: UIViewController, UIGestureRecognizerDelegate {
////
////    private let collectionDatabase = UserPlaceCollectionDatabase()
////    private let itemDatabase = UserPlaceCollectionItemDatabase()
////
////    private var collection: UserPlaceCollection?
////    private let isUser: Bool
////
////    private var items: [UserPlaceCollectionItem] = [.loading]
////
////        if self.isUser, let collection = collection {
////            self.headerView.titleView.text = collection.name
////            itemDatabase.observe(collection: collection).subscribe { event in
////                switch event {
////                case .next(let items):
////                    self.items = items.compactMap({
////                        if let place = $0.place {
////                            return UserPlaceCollectionItem.place($0, place)
////                        }
////                        return nil
////                    })
////                    if items.isEmpty {
////                        self.items = [.empty]
////                    }
////                    self.tableView.reloadData()
////
////                case .error(let error):
////                    self.alert(error: error)
////                case .completed:
////                    return
////                }
////            }.disposed(by: disposeBag)
////        } else {
////            loader!.start(collectionId: collectionId).subscribe { event in
////                switch event {
////                case let .success(collection):
////                    self.collection = collection
////                    self.headerView.titleView.text = collection.name
////                case let .error(error):
////                    self.alert(error: error)
////                }
////            }.disposed(by: disposeBag)
////
////            loader!.observe().subscribe { event in
////                switch event {
////                case let .next(items, more):
////                    self.items = items.compactMap({
////                        if let place = $0.place {
////                            return UserPlaceCollectionItem.place($0, place)
////                        }
////                        return nil
////                    })
////                    if more {
////                        self.items.append(.loading)
////                    }
////                    self.tableView.reloadData()
////
////                case .error(let error):
////                    self.alert(error: error)
////
////                case .completed:
////                    return
////                }
////            }.disposed(by: disposeBag)
////        }
////    }