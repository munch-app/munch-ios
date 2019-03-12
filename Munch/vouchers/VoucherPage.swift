//
// Created by Fuxing Loh on 2019-03-12.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import Moya
import RxSwift
import NVActivityIndicatorView

import Toast_Swift
import PinCodeView

class VoucherPageController: MHViewController {
    let voucherId: String
    var voucher: Voucher? = nil

    let header = MHHeaderView()
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50

        tableView.tableFooterView = UIView(frame: .zero)

        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 64
        tableView.separatorStyle = .none
        return tableView
    }()
    let indicator: NVActivityIndicatorView = {
        let indicator = NVActivityIndicatorView(frame: .zero, type: .ballTrianglePath, color: .secondary500, padding: 0)
        return indicator
    }()

    private let provider = MunchProvider<VoucherService>()
    private let disposeBag = DisposeBag()

    private var items: [VoucherPageItem] = []

    init(voucherId: String) {
        self.voucherId = voucherId
        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(tableView)
        self.view.addSubview(header)

        self.view.addSubview(indicator) { maker in
            maker.size.equalTo(48)
            maker.center.equalTo(self.view)
        }

        header.with(title: "Voucher")
        header.addTarget(left: self, action: #selector(onBackButton))
        header.snp.makeConstraints { maker in
            maker.left.right.top.equalTo(self.view)
        }

        tableView.snp.makeConstraints { maker in
            maker.top.equalTo(header.snp.bottom)
            maker.bottom.left.right.equalTo(self.view)
        }
        self.registerCells()

        indicator.startAnimating()
        provider.rx.request(.get(voucherId))
                .map { response -> Voucher in
                    return try response.map(data: Voucher.self)
                }
                .subscribe { event in
                    switch event {
                    case .error(let error):
                        self.alert(error: error)
                    case .success(let voucher):
                        self.indicator.stopAnimating()
                        self.voucher = voucher
                        self.items = VoucherPageItem.getItems(voucher: voucher)
                        self.tableView.reloadData()
                    }
                }.disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MunchAnalytic.setScreen("/vouchers")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension VoucherPageController: UITableViewDataSource, UITableViewDelegate {
    func registerCells() {
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.tableView.register(type: VoucherBannerCell.self)
        self.tableView.register(type: VoucherClaimedCell.self)
        self.tableView.register(type: VoucherHeaderCell.self)
        self.tableView.register(type: VoucherDescriptionCell.self)
        self.tableView.register(type: VoucherTermCell.self)
        self.tableView.register(type: VoucherBarCell.self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row] {
        case let .banner(image):
            return self.tableView.dequeue(type: VoucherBannerCell.self)
                    .render(with: image)

        case let .expired(text):
            return self.tableView.dequeue(type: VoucherClaimedCell.self)
                    .render(with: text)

        case let .header(text):
            return self.tableView.dequeue(type: VoucherHeaderCell.self)
                    .render(with: text)

        case let .description(text):
            return self.tableView.dequeue(type: VoucherDescriptionCell.self)
                    .render(with: text)


        case let .term(index, text):
            return self.tableView.dequeue(type: VoucherTermCell.self)
                    .render(with: text, index: index)

        case let .claim(remaining, claimed):
            return self.tableView.dequeue(type: VoucherBarCell.self)
                    .render(with: remaining, claimed: claimed) { control in
                        self.onShowPasscode()
                    }
        }
    }

    func onShowPasscode() {
        MunchAnalytic.logEvent("voucher_show_passcode", parameters: [
            "voucherId": voucherId as NSObject,
        ]);

        let controller = VoucherPasscodeController { passcode in
            self.onPasscode(passcode: passcode)
        }
        self.present(controller, animated: true)
    }

    func onPasscode(passcode: String) {
        MunchAnalytic.logEvent("voucher_claim_attempt", parameters: [
            "voucherId": voucherId as NSObject,
        ]);

        self.view.makeToastActivity(.center)

        provider.rx.request(.claim(voucherId, passcode))
                .map { response -> Voucher in
                    return try response.map(data: Voucher.self)
                }
                .subscribe { event in
                    self.view.hideToastActivity()

                    switch event {
                    case .error(let error):
                        self.alert(error: error)

                    case .success(let voucher):
                        MunchAnalytic.logEvent("voucher_claim_success", parameters: [
                            "voucherId": self.voucherId as NSObject,
                        ]);

                        self.alert(title: "Claimed", message: "You have claimed the voucher.")

                        self.indicator.stopAnimating()
                        self.voucher = voucher
                        self.items = VoucherPageItem.getItems(voucher: voucher)
                        self.tableView.reloadData()
                    }
                }.disposed(by: disposeBag)
    }
}

class VoucherPasscodeController: UIViewController, PinCodeViewDelegate {
    private let titleLabel = UILabel(style: .h3)
            .with(numberOfLines: 0)
            .with(alignment: .center)
            .with(text: "Enter authentication code:")

    private let subtitleLabel = UILabel(style: .h6)
            .with(numberOfLines: 0)
            .with(alignment: .center)
            .with(text: "(For staff only)")

    private let header = MHHeaderView()
            .with(title: "Voucher Code")
            .with(right: UIImage(named: "Navigation_Cancel"))

    let onPasscode: ((String) -> ())
    let pinView = PinCodeView(numberOfDigits: 4, textType: .numbers, groupingSize: 4, itemSpacing: 12)

    init(onPasscode: @escaping (String) -> ()) {
        self.onPasscode = onPasscode
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        pinView.delegate = self
        pinView.digitViewInit = PinCodeDigitSquareView.init

        header.addTarget(right: self, action: #selector(onCancel))
        self.view.addSubview(header) { maker in
            maker.top.left.right.equalTo(self.view)
        }

        self.view.addSubview(titleLabel) { maker in
            maker.top.equalTo(header.snp.bottom).inset(-32)
            maker.left.right.equalTo(self.view)
        }

        self.view.addSubview(subtitleLabel) { maker in
            maker.top.equalTo(titleLabel.snp.bottom)
            maker.left.right.equalTo(self.view)
        }

        self.view.addSubview(pinView) { maker in
            maker.top.equalTo(subtitleLabel.snp.bottom).inset(-24)
            maker.left.greaterThanOrEqualTo(self.view)
            maker.right.lessThanOrEqualTo(self.view)
            maker.centerX.equalTo(self.view)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pinView.becomeFirstResponder()
        MunchAnalytic.setScreen("/vouchers/passcode")
    }

    func pinCodeView(_ view: PinCodeView, didInsertText text: String) {

    }

    func pinCodeView(_ view: PinCodeView, didSubmitPinCode code: String, isValidCallback callback: @escaping (Bool) -> Void) {
        callback(true)
        onPasscode(code)
        self.dismiss(animated: true)
    }

    @objc func onCancel() {
        self.dismiss(animated: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class PinCodeDigitSquareView: UILabel, PinCodeDigitView {
    public var state: PinCodeDigitViewState! = .empty {
        didSet {
            if state != oldValue {
                configure(withState: state)
            }
        }
    }

    public var digit: String? {
        didSet {
            guard digit != oldValue else {
                return
            }
            self.state = digit != nil ? .hasDigit : .empty
            self.text = digit
        }
    }

    convenience required public init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))

        self.font = FontStyle.h1.font
        self.textColor = FontStyle.h1.color
        self.textAlignment = .center

        self.layer.borderWidth = 2
        self.layer.cornerRadius = 4
        self.configure(withState: .empty)

        self.snp.makeConstraints { maker in
            maker.size.equalTo(40)
        }
        self.layoutIfNeeded()
    }

    public func configure(withState state: PinCodeDigitViewState) {
        switch state {
        case .empty:
            layer.borderColor = UIColor.ba75.cgColor

        case .hasDigit:
            layer.borderColor = UIColor.ba75.cgColor

        case .failedVerification:
            layer.borderColor = UIColor.error.cgColor
        }
    }
}

enum VoucherPageItem {
    case banner(Image)
    case expired(String)
    case claim(Int, Bool)
    case description(String)
    case header(String)
    case term(Int, String)

    static func getItems(voucher: Voucher) -> [VoucherPageItem] {
        var items: [VoucherPageItem] = [
            .banner(voucher.image),
        ];

        if (voucher.remaining <= 0) {
            items.append(.expired("Sorry! All vouchers have been claimed for today. Come down tomorrow starting 10am to get your 1-for-1 voucher!"))
        }

        items.append(.claim(voucher.remaining, voucher.claimed))
        items.append(.description(voucher.description))
        items.append(.header("Terms and conditions of voucher:"))

        for (n, text) in voucher.terms.enumerated() {
            items.append(.term(n + 1, text))
        }

        return items;
    }
}

class VoucherBannerCell: UITableViewCell {
    let width = UIScreen.main.bounds.size.width
    private let imageV: SizeShimmerImageView = {
        let width = UIScreen.main.bounds.width
        let imageView = SizeShimmerImageView(points: width, height: 0)
        return imageView
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(imageV)
    }

    func render(with image: Image) -> UITableViewCell {
        self.imageV.render(image: image)
        self.imageV.snp.remakeConstraints { maker in
            maker.left.right.top.equalTo(self)
            maker.bottom.equalTo(self).inset(12)

            if let size = image.sizes.max {
                maker.height.equalTo(imageV.snp.width).multipliedBy(size.heightMultiplier).priority(.high)
            }
        }

        self.layoutIfNeeded()
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class VoucherClaimedCell: UITableViewCell {
    private let label = UILabel(style: .regular)
            .with(numberOfLines: 0)
            .with(color: .error)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(label) { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.bottom.equalTo(self).inset(12)
        }
    }

    func render(with text: String) -> UITableViewCell {
        label.with(text: text)
        self.layoutIfNeeded()
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class VoucherHeaderCell: UITableViewCell {
    private let label = UILabel(style: .h5)
            .with(numberOfLines: 0)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(label) { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(24)
            maker.bottom.equalTo(self).inset(12)
        }
    }

    func render(with text: String) -> UITableViewCell {
        label.with(text: text)
        self.layoutIfNeeded()
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class VoucherDescriptionCell: UITableViewCell {
    private let label = UILabel(style: .regular)
            .with(numberOfLines: 0)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(label) { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.bottom.equalTo(self).inset(12)
        }
    }

    func render(with text: String) -> UITableViewCell {
        label.with(text: text)
        self.layoutIfNeeded()
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class VoucherTermCell: UITableViewCell {
    private let noLabel = UILabel(style: .h5)
            .with(numberOfLines: 0)

    private let termLabel = UILabel(style: .regular)
            .with(numberOfLines: 0)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(noLabel) { maker in
            maker.top.equalTo(self).inset(12)
            maker.left.equalTo(self).inset(24)
            maker.width.equalTo(32)
        }

        self.addSubview(termLabel) { maker in
            maker.left.equalTo(noLabel.snp.right)
            maker.right.equalTo(self).inset(24)
            maker.top.equalTo(self)
            maker.bottom.equalTo(self).inset(8)
        }
    }

    func render(with text: String, index: Int) -> UITableViewCell {
        termLabel.with(text: text)
        noLabel.with(text: "\(index).")
        self.layoutIfNeeded()
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class VoucherBarCell: UITableViewCell {
    private let label = UILabel(style: .h5)
            .with(numberOfLines: 0)
    private let claimBtn = MunchButton(style: .border)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(claimBtn) { maker in
            maker.top.greaterThanOrEqualTo(self).inset(12)
            maker.bottom.lessThanOrEqualTo(self).inset(12)
            maker.right.equalTo(self).inset(24)
        }

        self.addSubview(label) { maker in
            maker.left.equalTo(self).inset(24)
            maker.right.equalTo(claimBtn.snp.left).inset(-24)
            maker.top.greaterThanOrEqualTo(self).inset(12)
            maker.bottom.lessThanOrEqualTo(self).inset(12)
        }
    }

    func render(with remaining: Int, claimed: Bool, closure: @escaping UIControlTargetClosure) -> UITableViewCell {
        label.with(text: "Vouchers left for today:  \(remaining)")
        if claimed {
            claimBtn.with(text: "Claimed")
            claimBtn.with(style: .disabled)
        } else {
            claimBtn.with(text: "For Staff")
            claimBtn.with(style: .secondary)
        }

        self.claimBtn.onTouchUpInside(closure)
        self.layoutIfNeeded()
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}