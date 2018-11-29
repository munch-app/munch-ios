////
//// Created by Fuxing Loh on 19/6/18.
//// Copyright (c) 2018 Munch Technologies. All rights reserved.
////
//
//import Foundation
//import UIKit
//import SnapKit
//import RxSwift
//
//import Toast_Swift
//import Localize_Swift
//import NVActivityIndicatorView
//
//import FirebaseAnalytics
//
//enum ProfileTabDataType {
//    case collection(UserPlaceCollection)
//    case loading
//}
//
//extension ProfileController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
//    class func initCollection() -> UICollectionView {
//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .vertical
//        layout.minimumLineSpacing = 0
//        layout.minimumInteritemSpacing = 0
//
//        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        collectionView.showsVerticalScrollIndicator = false
//        collectionView.showsHorizontalScrollIndicator = false
//        collectionView.alwaysBounceVertical = true
//        collectionView.backgroundColor = UIColor.white
//        return collectionView
//    }
//
//    func initTabs() {
//        func register(cellClass: UICollectionViewCell.Type) {
//            self.collectionView.register(cellClass, forCellWithReuseIdentifier: String(describing: cellClass))
//        }
//
//        register(cellClass: ProfileTabInsetCell.self)
//        register(cellClass: ProfileTabCollectionCreateCell.self)
//        register(cellClass: ProfileTabLoadingCell.self)
//        register(cellClass: ProfileTabCollectionItemCell.self)
//
//        self.collectionView.delegate = self
//        self.collectionView.dataSource = self
//
//        self.collectionView.contentInset.top = self.headerView.contentHeight // Top Override
//        self.collectionView.contentInsetAdjustmentBehavior = .always
//
//        // Refresh Control
//        let refreshControl = UIRefreshControl()
//        refreshControl.addTarget(self, action: #selector(collectionView(handleRefresh:)), for: .valueChanged)
//        refreshControl.tintColor = UIColor.black.withAlphaComponent(0.7)
//        self.collectionView.addSubview(refreshControl)
//    }
//
//    func initObserver() {
//        collectionDatabase.observe().subscribe { event in
//            switch event {
//            case .next(let items):
//                self.items = items.map({ ProfileTabDataType.collection($0) })
//                self.collectionView.reloadData()
//
//            case .error(let error):
//                self.alert(error: error)
//            case .completed:
//                return
//            }
//        }.disposed(by: disposeBag)
//    }
//
//    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return 3
//    }
//
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        switch section {
//        case 0:
//            return 2
//        case 1:
//            return self.items.count
//        case 2:
//            return 1
//        default:
//            return 0
//        }
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        switch (indexPath.section, indexPath.row) {
//        case (0, 1):
//            fallthrough
//        case (1, _):
//            return CGSize(width: UIScreen.main.bounds.width, height: 60 + 24)
//
//        default:
//            return CGSize(width: UIScreen.main.bounds.width, height: 12)
//        }
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        switch (indexPath.section, indexPath.row) {
//        case (0, 1):
//            self.actionCreate()
//
//        case (1, let row):
//            switch self.items[row] {
//            case .collection(let collection):
//                let controller = UserPlaceCollectionController(collection: collection)
//                self.navigationController?.pushViewController(controller, animated: true)
//            default:
//                return
//            }
//        default:
//            return
//        }
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        func dequeue(cellClass: UICollectionViewCell.Type) -> UICollectionViewCell {
//            let identifier = String(describing: cellClass)
//            return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
//        }
//
//        switch (indexPath.section, indexPath.row) {
//        case (0, 1):
//            return dequeue(cellClass: ProfileTabCollectionCreateCell.self)
//
//        case (0, _):
//            fallthrough
//        case (2, _):
//            return dequeue(cellClass: ProfileTabInsetCell.self)
//
//        case (1, let row):
//            switch self.items[row] {
//            case .loading:
//                return dequeue(cellClass: ProfileTabLoadingCell.self)
//
//            case .collection(let collection):
//                let cell = dequeue(cellClass: ProfileTabCollectionItemCell.self) as! ProfileTabCollectionItemCell
//                cell.render(collection: collection)
//                return cell
//            }
//
//        default:
//            return UICollectionViewCell()
//        }
//    }
//
//    private func actionCreate() {
//        let alertController = UIAlertController(title: "Create Collection", message: "Enter name of collection", preferredStyle: .alert)
//        alertController.addTextField { (textField) in
//            textField.placeholder = "Enter Name"
//        }
//        alertController.addAction(UIAlertAction(title: "Create", style: .default) { (_) in
//            if let name = alertController.textFields?[0].text {
//                let collection = UserPlaceCollection(
//                        collectionId: nil,
//                        userId: nil,
//                        sort: nil,
//                        name: name,
//                        description: nil,
//                        image: nil,
//                        access: .Public,
//                        createdBy: .User,
//                        createdMillis: nil,
//                        updatedMillis: nil,
//                        count: nil
//                )
//                self.collectionDatabase.create(collection: collection)
//            }
//        })
//        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//
//        //finally presenting the dialog box
//        self.present(alertController, animated: true, completion: nil)
//    }
//
//    @objc func collectionView(handleRefresh refreshControl: UIRefreshControl) {
//        self.collectionDatabase.sendLocal()
//        collectionView.reloadData()
//        refreshControl.endRefreshing()
//    }
//}
//
//// MARK: Scroll View
//extension ProfileController {
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        self.headerView.contentDidScroll(scrollView: scrollView)
//    }
//
//    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        if (!decelerate) {
//            scrollViewDidFinish(scrollView)
//        }
//    }
//
//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        scrollViewDidFinish(scrollView)
//    }
//
//    func scrollViewDidFinish(_ scrollView: UIScrollView) {
//        // Check nearest locate and move to it
//        if let y = self.headerView.contentShouldMove(scrollView: scrollView) {
//            let point = CGPoint(x: 0, y: y)
//            scrollView.setContentOffset(point, animated: true)
//        }
//    }
//}
//
//fileprivate class ProfileTabInsetCell: UICollectionViewCell {
//    override init(frame: CGRect = .zero) {
//        super.init(frame: frame)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
//fileprivate class ProfileTabLoadingCell: UICollectionViewCell {
//    private var indicator: NVActivityIndicatorView!
//
//    override init(frame: CGRect = .zero) {
//        super.init(frame: frame)
//
//        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.width, height: 40))
//        self.indicator = NVActivityIndicatorView(frame: frame, type: .ballBeat, color: .primary700, padding: 0)
//        indicator.startAnimating()
//        self.addSubview(indicator)
//
//        indicator.snp.makeConstraints { make in
//            make.left.right.equalTo(self)
//            make.height.equalTo(40)
//            make.centerY.equalTo(self)
//        }
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
//fileprivate class ProfileTabCollectionCreateCell: UICollectionViewCell {
//    private let leftImageView: SizeShimmerImageView = {
//        let imageView = SizeShimmerImageView(points: 60, height: 60)
//        imageView.tintColor = UIColor.black
//        return imageView
//    }()
//
//    private let titleView: UILabel = {
//        let titleView = UILabel()
//        titleView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
//        titleView.textColor = .black
//        return titleView
//    }()
//
//    private let subtitleView: UILabel = {
//        let titleView = UILabel()
//        titleView.font = UIFont.systemFont(ofSize: 13, weight: .regular)
//        titleView.textColor = .black
//        return titleView
//    }()
//
//    override init(frame: CGRect = .zero) {
//        super.init(frame: frame)
//        self.addSubview(leftImageView)
//
//        let rightView = UIView()
//        self.addSubview(rightView)
//        rightView.addSubview(titleView)
//        rightView.addSubview(subtitleView)
//
//        leftImageView.snp.makeConstraints { make in
//            make.left.equalTo(self).inset(24)
//            make.top.bottom.equalTo(self).inset(12)
//            make.width.equalTo(60)
//            make.height.equalTo(60)
//        }
//
//        rightView.snp.makeConstraints { make in
//            make.left.equalTo(leftImageView.snp.right).inset(-18)
//            make.right.equalTo(self).inset(24)
//            make.centerY.equalTo(leftImageView)
//        }
//
//        titleView.snp.makeConstraints { make in
//            make.left.right.equalTo(rightView)
//            make.top.equalTo(rightView)
//        }
//
//        subtitleView.snp.makeConstraints { make in
//            make.left.right.equalTo(rightView)
//            make.top.equalTo(titleView.snp.bottom).inset(-2)
//            make.bottom.equalTo(rightView)
//        }
//
//        leftImageView.render(named: "Collection-CreateNew")
//        titleView.text = "Create a new collection".localized()
//        subtitleView.text = "Save and share places in Munch".localized()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
//fileprivate class ProfileTabCollectionItemCell: UICollectionViewCell {
//    private let leftImageView: SizeShimmerImageView = {
//        let imageView = SizeShimmerImageView(points: 60, height: 60)
//        return imageView
//    }()
//
//    private let titleView: UILabel = {
//        let titleView = UILabel()
//        titleView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
//        titleView.textColor = .black
//        return titleView
//    }()
//
//    private let subtitleView: UILabel = {
//        let titleView = UILabel()
//        titleView.font = UIFont.systemFont(ofSize: 13, weight: .regular)
//        titleView.textColor = .black
//        return titleView
//    }()
//    private let checkedView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.image = UIImage(named: "Collection-Next")
//        imageView.tintColor = .black
//        return imageView
//    }()
//
//    override init(frame: CGRect = .zero) {
//        super.init(frame: frame)
//        self.addSubview(leftImageView)
//
//        let rightView = UIView()
//        self.addSubview(rightView)
//        rightView.addSubview(titleView)
//        rightView.addSubview(subtitleView)
//        rightView.addSubview(checkedView)
//
//        leftImageView.snp.makeConstraints { make in
//            make.left.equalTo(self).inset(24)
//            make.top.bottom.equalTo(self).inset(12)
//            make.width.equalTo(60)
//            make.height.equalTo(60)
//        }
//
//        rightView.snp.makeConstraints { make in
//            make.left.equalTo(leftImageView.snp.right).inset(-18)
//            make.right.equalTo(checkedView).inset(-18)
//            make.centerY.equalTo(leftImageView)
//        }
//
//        titleView.snp.makeConstraints { make in
//            make.left.right.equalTo(rightView)
//            make.top.equalTo(rightView)
//        }
//
//        subtitleView.snp.makeConstraints { make in
//            make.left.right.equalTo(rightView)
//            make.top.equalTo(titleView.snp.bottom).inset(-2)
//            make.bottom.equalTo(rightView)
//        }
//
//        checkedView.snp.makeConstraints { make in
//            make.right.equalTo(self).inset(24)
//            make.width.height.equalTo(18)
//            make.centerY.equalTo(leftImageView)
//        }
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func render(collection: UserPlaceCollection) {
//        self.leftImageView.render(image: collection.image)
//        self.titleView.text = collection.name
//        self.subtitleView.text = "\(collection.count ?? 0) places"
//    }
//}