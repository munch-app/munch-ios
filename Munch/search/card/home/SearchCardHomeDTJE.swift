//
// Created by Fuxing Loh on 2018-12-17.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import UserNotifications

class SearchCardHomeDTJE: SearchCardView {
    let titleLabel = UILabel(style: .h2)
            .with(numberOfLines: 1)
            .with(text: "Don't think, just eat")

    let subLabel = UILabel(style: .h6)
            .with(numberOfLines: 1)
            .with(text: "5 suggestions, twice daily.")

    let infoView: UIControl = {
        let control = UIControl()
        control.tintColor = .black

        let imageView = UIImageView()
        imageView.image = UIImage(named: "Search-Card-Home-DTJE-Info")
        imageView.contentMode = .scaleAspectFit
        control.addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.edges.equalTo(control)
        }
        return control
    }()

    private let listView = SearchDTJEListView()

    fileprivate let subscribeButton = SearchDTJESubscribeButton()

    override func didLoad(card: SearchCard) {
        SearchCardHomeDTJE.validate()
        SearchCardHomeDTJE.update()

        infoView.addTarget(self, action: #selector(onInfo), for: .touchUpInside)
        subscribeButton.controller = self.controller

        self.backgroundColor = .saltpan100

        self.addSubview(titleLabel)
        self.addSubview(subLabel)
        self.addSubview(infoView)
        self.addSubview(subscribeButton)

        self.addSubview(listView)

        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(self).inset(topBottom)
            maker.height.equalTo(28)
        }

        subLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(titleLabel.snp.bottom).inset(-4)
            maker.height.equalTo(18)
        }

        infoView.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel)
            maker.bottom.equalTo(subLabel)
            maker.right.equalTo(self).inset(leftRight)
            maker.width.equalTo(28)
        }

        listView.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(leftRight)
            maker.top.equalTo(subLabel.snp.bottom).inset(-16)
        }

        subscribeButton.snp.makeConstraints { maker in
            maker.right.equalTo(self).inset(leftRight)
            maker.bottom.equalTo(self).inset(topBottom)
        }
    }

    override func willDisplay(card: SearchCard) {
        listView.render(card: card)
        subscribeButton.isHidden = Notification.isSubscribed
    }

    override class func height(card: SearchCard) -> CGFloat {
        let max: CGFloat = topBottom
                + 28
                + 4
                + 18
                + 16
                + SearchDTJEListView.height
                + 16
                + 40
                + topBottom

        if Notification.isSubscribed {
            // Subscribe Button + Margin Top
            return max - 56
        }
        return max
    }

    @objc func onInfo() {
        let modal = SearchDTJEInfoController()
        let delegate = HalfModalTransitioningDelegate(viewController: self.controller, presentingViewController: modal)
        modal.modalPresentationStyle = .custom
        modal.transitioningDelegate = delegate
        self.controller.present(modal, animated: true)
    }

    override class var cardId: String {
        return "HomeDTJE_2018-12-17"
    }
}

extension SearchCardHomeDTJE {
    enum Notification: String {
        case lunch = "SearchCardHomeDTJE.Notification.Lunch"
        case dinner = "SearchCardHomeDTJE.Notification.Dinner"

        var body: String {
            switch self {
            case .lunch:
                return "Your suggestions for lunch are ready."
            case .dinner:
                return "Your suggestions for dinner are ready."
            }
        }

        var dateComponents: DateComponents {
            var dateComponents = DateComponents()
            dateComponents.calendar = Calendar.current
            switch self {
            case .lunch:
                dateComponents.hour = 11
                dateComponents.minute = 30

            case .dinner:
                dateComponents.hour = 18
            }
            return dateComponents
        }

        var isSubscribed: Bool {
            return UserDefaults.standard.bool(forKey: self.rawValue)
        }

        static var isSubscribed: Bool {
            return SearchCardHomeDTJE.Notification.dinner.isSubscribed || SearchCardHomeDTJE.Notification.lunch.isSubscribed
        }

        static let version = "1"
    }

    class func update() {
        if UserDefaults.standard.string(forKey: "SearchCardHomeDTJE.Notification.Version") == Notification.version {
            return
        }

        // Changes in Notification setting
        if Notification.lunch.isSubscribed {

        }
        if Notification.dinner.isSubscribed {

        }

        UserDefaults.standard.set(Notification.version, forKey: "SearchCardHomeDTJE.Notification.Version")
    }

    private class func validate() {
        guard Notification.isSubscribed else {
            return
        }

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .denied: fallthrough
            case .notDetermined:
                unsubscribe(notification: .dinner)
                unsubscribe(notification: .lunch)

            default:
                return
            }
        }
    }

    class func subscribe(notification: Notification) {
        let content = UNMutableNotificationContent()
        content.title = "Don't think, just eat"
        content.body = notification.body

        // Create the trigger as a repeating event.
        let trigger = UNCalendarNotificationTrigger(dateMatching: notification.dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: notification.rawValue, content: content, trigger: trigger)

        // Schedule the request with the system.
        UserDefaults.standard.set(true, forKey: notification.rawValue)
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request)
    }


    class func unsubscribe(notification: Notification) {
        let notificationCenter = UNUserNotificationCenter.current()
        UserDefaults.standard.removeObject(forKey: notification.rawValue)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notification.rawValue])
    }
}

fileprivate class SearchDTJEListView: UIView {
    static let height: CGFloat = SearchDTJEItem.height * 5

    let items = [SearchDTJEItem(), SearchDTJEItem(), SearchDTJEItem(), SearchDTJEItem(), SearchDTJEItem()]
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        return stackView
    }()
    let overlay = UILabel(style: .regular)
            .with(numberOfLines: 0)
            .with(alignment: .center)

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(stackView)
        self.addSubview(overlay)

        for (index, item) in items.enumerated() {
            stackView.addArrangedSubview(item)
            item.noLabel.text = "\(index + 1)."
        }

        stackView.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
        }

        overlay.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(stackView)
            maker.left.right.equalTo(stackView).inset(40)
        }
    }

    func render(card: SearchCard) {
        var minute: Int {
            let date = Date()
            let hour = Calendar.current.component(.hour, from: date)
            let minute = Calendar.current.component(.minute, from: date)

            return (hour * 60) + minute
        }

        func render(hour name: String) {
            overlay.isHidden = true
            guard let list = card.decode(name: name, [String].self) as? [String] else {
                return
            }
            for (index, item) in list.enumerated() {
                self.items[index].textLabel.text = item
            }
        }

        func render(wait time: String) {
            overlay.isHidden = false
            overlay.text = "Suggestions will be out at \(time).\n\nSubscribe to receive a notification when the suggestions are out!"
        }

        if minute < 690 {
            render(wait: "11:30am")
        } else if minute >= 690 && minute < 960 {
            render(hour: "lunch")
        } else if minute < 1080 {
            render(wait: "6pm")
        } else {
            render(hour: "dinner")
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class SearchDTJEItem: UIView {
    static let height: CGFloat = 28

    let noLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    let textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(noLabel)
        self.addSubview(textLabel)

        noLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self).priority(.high)
            maker.left.equalTo(self)
            maker.width.equalTo(24)
        }

        textLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self).priority(.high)
            maker.right.equalTo(self)
            maker.left.equalTo(noLabel.snp.right).inset(-8)
        }

        self.snp.makeConstraints { maker in
            maker.height.equalTo(SearchDTJEItem.height)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class SearchDTJESubscribeButton: UIView {
    let subscribeButton = MunchButton(style: .secondary)
            .with(text: "Subscribe")
    var controller: UIViewController! {
        didSet {
            if SearchCardHomeDTJE.Notification.isSubscribed {
                subscribeButton.with(style: .secondaryOutline)
                subscribeButton.text = "Subscribed"
            } else {
                subscribeButton.with(style: .secondary)
                subscribeButton.text = "Subscribe"
            }

        }
    }

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(subscribeButton)

        subscribeButton.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
        }
        subscribeButton.addTarget(self, action: #selector(onSubscribe), for: .touchUpInside)
    }

    @objc func onSubscribe() {
        if self.subscribeButton.text == "Subscribed" {
            let alert = UIAlertController(title: nil, message: "Unsubscribe from 'don't think, just eat'?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { action in
                SearchCardHomeDTJE.unsubscribe(notification: .lunch)
                SearchCardHomeDTJE.unsubscribe(notification: .dinner)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            controller.present(alert, animated: true)
            return
        }

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.requestAuthorization { b, error in
            if let error = error {
                self.controller.alert(error: error)
            }

            guard b else {
                return
            }

            SearchCardHomeDTJE.subscribe(notification: .lunch)
            SearchCardHomeDTJE.subscribe(notification: .dinner)

            DispatchQueue.main.async {
                self.controller.alert(title: "Subscribed!", message: "You will receive a notification when the suggestions are out.")

                self.subscribeButton.with(text: "Subscribed")
                self.subscribeButton.with(style: .secondaryOutline)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class SearchDTJEInfoController: HalfModalController {
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceHorizontal = false
        return scrollView
    }()
    private let headerLabel = UILabel(style: .h2)
            .with(numberOfLines: 0)
    private let textLabel = UILabel(style: .regular)
            .with(numberOfLines: 0)
    fileprivate let subscribeButton = SearchDTJESubscribeButton()

    override init() {
        let l1 = "This feature provides you with 5 suggestions twice daily for lunch and dinner."
        let l2 = "Subscribe and receive notifications at 11:30 am and 6 pm on what to eat so you don’t have to think."

        headerLabel.text = "More Information"
        textLabel.with(text: l1 + "\n\n" + l2, lineSpacing: 1.5)
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.addSubview(headerLabel)
        scrollView.addSubview(textLabel)

        self.view.addSubview(scrollView)
        self.view.addSubview(subscribeButton)

        subscribeButton.controller = self

        scrollView.snp.makeConstraints { maker in
            maker.top.equalTo(self.view.safeArea.top)
            maker.bottom.equalTo(subscribeButton.snp.top)
            maker.left.right.equalTo(self.view)
        }

        headerLabel.snp.makeConstraints { maker in
            maker.top.equalTo(scrollView).inset(24)
            maker.left.right.equalTo(self.view).inset(24)
        }

        textLabel.snp.makeConstraints { maker in
            maker.top.equalTo(headerLabel.snp.bottom).inset(-16)
            maker.bottom.equalTo(scrollView).inset(24)
            maker.left.right.equalTo(self.view).inset(24)
        }

        subscribeButton.snp.makeConstraints { maker in
            maker.right.equalTo(self.view).inset(24)
            maker.bottom.equalTo(self.view.safeArea.bottom).inset(24)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}