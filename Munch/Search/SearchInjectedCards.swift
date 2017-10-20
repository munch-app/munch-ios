//
//  SearchInjectedCards.swift
//  Munch
//
//  Created by Fuxing Loh on 20/10/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

class SearchNoLocationCard: UITableViewCell, SearchCardView {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        let label = UILabel()
        label.text = "No Location"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.regular)
        self.addSubview(label)
        
        let button = UIButton()
        button.setTitle("Enable Location", for: .normal)
        button.setTitleColor(.primary300, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.regular)
        button.addTarget(self, action: #selector(enableLocation(button:)), for: .touchUpInside)
        self.addSubview(button)
        
        label.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            
            make.top.equalTo(self).inset(topBottom)
            make.height.equalTo(40)
        }
        
        button.snp.makeConstraints { make in
            make.left.right.equalTo(self).inset(leftRight)
            
            make.top.equalTo(label.snp.bottom)
            make.height.equalTo(40)
            make.bottom.equalTo(self).inset(topBottom)
        }
    }
    
    @objc func enableLocation(button: UIButton) {
        MunchLocation.scheduleOnce()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(card: SearchCard) {
    }
    
    static var cardId: String {
        return "injected_NoLocation_20171020"
    }
}
