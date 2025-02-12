//
// Created by Fuxing Loh on 19/6/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import RxSwift

class ProfileSavedPlaceController: UIViewController {
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50

        tableView.tableFooterView = UIView(frame: .zero)
        tableView.contentInset.bottom = 64
        tableView.separatorStyle = .none
        return tableView
    }()

    private var items = [ProfileSavedPlaceType]()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCells()

        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalTo(self.view)
        }

        PlaceSavedDatabase.shared.reload()
        PlaceSavedDatabase.shared.observe().subscribe { event in
            switch event {
            case .next(let items):
                self.items = [items.isEmpty ? .headerEmpty : .header]
                items.forEach { place in
                    self.items.append(.savedPlace(place))
                }
                self.tableView.reloadData()

            case .error(let error):
                self.alert(error: error)

            case .completed:
                return
            }
        }.disposed(by: disposeBag)
        // Need to validate that it doesn't crash
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

enum ProfileSavedPlaceType {
    case header
    case headerEmpty
    case savedPlace(UserSavedPlace)
}

// MARK: TableView Cells
extension ProfileSavedPlaceController: UITableViewDataSource, UITableViewDelegate {
    func registerCells() {
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.tableView.register(type: ProfileSavedPlaceCell.self)
        self.tableView.register(type: ProfileSavedPlaceEmptyCell.self)
        self.tableView.register(type: ProfileSavedPlaceHeaderCell.self)
        self.tableView.register(type: ProfileSavedPlaceEmptyHeaderCell.self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row] {
        case .header:
            return tableView.dequeue(type: ProfileSavedPlaceHeaderCell.self)

        case .headerEmpty:
            let cell = tableView.dequeue(type: ProfileSavedPlaceEmptyHeaderCell.self)
            cell.controller = self
            return cell

        case .savedPlace(let savedPlace):
            guard let place = savedPlace.place else {
                let cell = tableView.dequeue(type: ProfileSavedPlaceEmptyCell.self)
                cell.label.text = "\(savedPlace.name) is removed."
                return cell
            }

            let cell = tableView.dequeue(type: ProfileSavedPlaceCell.self)
            cell.placeCard.place = place
            cell.placeCard.heartBtn.isSelected = true
            cell.placeCard.controller = self
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch items[indexPath.row] {
        case .savedPlace(let savedPlace):
            guard let place = savedPlace.place else {
                return
            }
            let controller = RIPController(placeId: place.placeId)
            self.navigationController!.pushViewController(controller, animated: true)

        default:
            return
        }


    }
}

class ProfileSavedPlaceHeaderCell: UITableViewCell {
    let label = UILabel(style: .h2)
            .with(text: "Saved Places")

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(label)

        label.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(32).priority(.high)
            maker.bottom.equalTo(self).inset(8).priority(.high)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ProfileSavedPlaceEmptyHeaderCell: UITableViewCell {
    let subLabel = UILabel(style: .h5)
            .with(text: "Places you add to your Tastebud will be saved here.")
            .with(numberOfLines: 0)
    let discoverBtn = MunchButton(style: .secondary)
            .with(text: "Discover")
    let container = UIView()
    var controller: UIViewController!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(container)
        container.addSubview(subLabel)
        container.addSubview(discoverBtn)

        container.backgroundColor = .whisper100
        container.layer.cornerRadius = 3

        container.snp.makeConstraints { maker in
            maker.edges.equalTo(self).inset(24)
        }

        subLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(container).inset(24)
            maker.top.equalTo(container).inset(24).priority(.high)
        }

        discoverBtn.snp.makeConstraints { maker in
            maker.right.equalTo(container).inset(24)
            maker.bottom.equalTo(container).inset(24).priority(.high)
            maker.top.equalTo(subLabel.snp.bottom).inset(-16).priority(.high)
        }

        discoverBtn.addTarget(self, action: #selector(onDiscover), for: .touchUpInside)
    }

    @objc func onDiscover() {
        self.controller.tabBarController?.selectedIndex = MunchTabBarItem.Feed.index
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ProfileSavedPlaceCell: UITableViewCell {
    let placeCard = PlaceCard()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(placeCard)
        placeCard.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.bottom.equalTo(self).inset(16).priority(.high)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ProfileSavedPlaceEmptyCell: UITableViewCell {
    let label = UILabel(style: .h3)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.bottom.equalTo(self).inset(16).priority(.high)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}