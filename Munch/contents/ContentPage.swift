//
// Created by Fuxing Loh on 2019-03-08.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import Moya
import RxSwift
import SnapKit

class ContentPageController: MHViewController {
    init(contentId: String, content: CreatorContent? = nil) {
        self.contentId = contentId
        self.content = content
        super.init(nibName: nil, bundle: nil)

        self.hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 64

        tableView.tableFooterView = UIView(frame: .zero)
        tableView.contentInset.bottom = 24
        tableView.separatorStyle = .none
        return tableView
    }()
    let headerView = MHHeaderView()

    private let contentService = MunchProvider<CreatorContentService>()
    private let itemService = MunchProvider<CreatorContentItemService>()

    private let disposeBag = DisposeBag()

    let contentId: String
    var content: CreatorContent?
    var items: [[String: Any]] = []
    var places: [String: Place?] = [:]
    var loading = true

    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCells()
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)

        tableView.snp.makeConstraints { maker in
            maker.top.equalTo(headerView.snp.bottom)
            maker.left.right.bottom.equalTo(self.view)
        }
        headerView.snp.makeConstraints { maker in
            maker.left.top.right.equalTo(self.view)
        }

        self.headerView.addTarget(back: self, action: #selector(onBackButton))
        self.headerView.addTarget(more: self, action: #selector(onMore))
        self.loadAll()
    }
}

// MARK: TableView Cells
extension ContentPageController: UITableViewDataSource, UITableViewDelegate {
    func loadAll() {
        guard content != nil else {
            contentService.rx.request(.get(contentId))
                    .map { response -> CreatorContent in
                        return try response.map(data: CreatorContent.self)
                    }.subscribe { event in
                        switch event {
                        case let .error(error):
                            self.alert(error: error)

                        case let .success(content):
                            self.headerView.with(title: content.title)
                            self.content = content
                            self.appendItems(nextItemId: nil)
                        }
                    }
                    .disposed(by: disposeBag)
            return
        }

        headerView.with(title: content?.title)
        appendItems(nextItemId: nil)
    }

    func appendItems(nextItemId: String?) {
        itemService.rx.request(.list(contentId, nextItemId))
                .map { res throws -> ([[String: Any]], [String: Place?], String?) in
                    let items = try res.mapJSON(atKeyPath: "data") as! [[String: Any]]
                    let places = try res.map([String: Place?].self, atKeyPath: "places")
                    let itemId = try res.mapNext(atKeyPath: "itemId") as? String
                    return (items, places, itemId)
                }
                .subscribe { event in
                    switch event {
                    case let .error(error):
                        self.alert(error: error)

                    case let .success(items, places, itemId):
                        places.forEach { placeId, place in
                            self.places[placeId] = place
                        }

                        self.items.append(contentsOf: items)

                        if let itemId = itemId {
                            self.appendItems(nextItemId: itemId)
                        } else {
                            self.loading = false
                            self.tableView.reloadData()
                        }

                    }
                }.disposed(by: disposeBag)
    }

    func registerCells() {
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.tableView.register(type: ContentLoading.self)
        self.tableView.register(type: ContentLine.self)
        self.tableView.register(type: ContentPlace.self)
        self.tableView.register(type: ContentImage.self)
        self.tableView.register(type: ContentTextBody.self)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return items.count
        case 1:
            return 1
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else {
            if loading {
                return tableView.dequeue(type: ContentLoading.self)
            } else {
                return UITableViewCell()
            }
        }

        let item = items[indexPath.row]
        switch item["type"] as! String {
        case "title": fallthrough
        case "h1": fallthrough
        case "h2": fallthrough
        case "text":
            return tableView.dequeue(type: ContentTextBody.self).render(with: item)

        case "image":
            return tableView.dequeue(type: ContentImage.self).render(with: item)

        case "line":
            return tableView.dequeue(type: ContentLine.self)

        case "place":
            let placeId = (item["body"] as! [String: Any])["placeId"] as! String
            let place = self.places[placeId]!
            return tableView.dequeue(type: ContentPlace.self)
                    .render(with: item, place: place)

        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else {
            return
        }

        let item = items[indexPath.row]
        switch item["type"] as! String {
        case "place":
            let placeId = (item["body"] as! [String: Any])["placeId"] as! String
            let controller = RIPController(placeId: placeId)
            self.navigationController!.pushViewController(controller, animated: true)

        default:
            return
        }
    }
}

extension ContentPageController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        MunchAnalytic.setScreen("/contents")
        MunchAnalytic.logEvent("content_view")
        UserDefaults.count(key: UserDefaultsKey.countViewContent)
    }
}

extension ContentPageController {
    @objc func onMore() {
        MunchAnalytic.logEvent("content_click_more")
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Share", style: .default) { action in
            self.onShare()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }

    @objc func onShare() {
        guard let content = self.content else {
            return
        }

        if let url = URL(string: "https://www.munch.app/contents/\(content.cid)/\(content.slug)") {
            let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            controller.excludedActivityTypes = [.airDrop, .addToReadingList, UIActivity.ActivityType.openInIBooks]

            MunchAnalytic.logEvent("content_click_share")
            self.present(controller, animated: true)
        }
    }
}