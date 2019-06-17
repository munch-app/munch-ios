//
// Created by Fuxing Loh on 2019-03-08.
// Copyright (c) 2019 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import SwiftRichString

class ContentTextBody: UITableViewCell {
    private let textBody = UILabel()
            .with(numberOfLines: 0)

    override required init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.addSubview(textBody)
    }

    func render(with item: [String: Any]) -> ContentTextBody {
        let type = item["type"] as! String
        let attributedText = NSMutableAttributedString()
        if let body = item["body"] as? [String: Any], let contents = body["content"] as? [[String: Any]] {
            contents.forEach { span in
                attributedText.append(getAttributedString(type: type, span: span))
            }
        }

        textBody.with(font: getFont(with: item))
        textBody.attributedText = attributedText
        textBody.snp.remakeConstraints { maker in
            maker.edges.equalTo(self).inset(getInsets(with: item)).priority(.high)
        }
        self.layoutIfNeeded()
        return self
    }

    func getInsets(with item: [String: Any]) -> UIEdgeInsets {
        switch item["type"] as! String {
        case "title":
            return UIEdgeInsets(top: 24, left: 24, bottom: 12, right: 24)
        case "h1":
            return UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        case "h2":
            return UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        default:
            return UIEdgeInsets(top: 0, left: 24, bottom: 12, right: 24)
        }
    }

    func getFont(with item: [String: Any]) -> UIFont {
        switch item["type"] as! String {
        case "title":
            return FontStyle.h2.font
        case "h1":
            return FontStyle.h2.font
        case "h2":
            return FontStyle.h3.font
        default:
            return FontStyle.regular.font
        }
    }

    func getAttributedString(type: String, span: [String: Any]) -> NSAttributedString {
        let text = span["text"] as? String ?? ""
        if type == "text" {
            return text.set(style: Style {
                $0.color = UIColor.black
                $0.lineHeightMultiple = 1.4
            })
        } else {
            return text.set(style: Style {
                $0.color = UIColor.ba75
            })
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}