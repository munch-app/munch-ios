
//
//class PlaceBasicBusinessHourCard: PlaceCardView {
//    static let openStyle = Style {
//        $0.color = UIColor.secondary500
//        $0.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
//    }
//    static let closeStyle = Style {
//        $0.color = UIColor.primary500
//        $0.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
//    }
//    static let hourStyle = Style {
//        $0.color = UIColor.black
//        $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
//    }
//    static let boldStyle = Style {
//        $0.color = UIColor.black
//        $0.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
//    }
//
//    let grid = UIView()
//    let indicator = UIButton()
//    let openLabel = UILabel()
//    let dayView = DayView()
//
//    var openHeightConstraint: Constraint!
//    var dayHeightConstraint: Constraint!
//
//    override func didLoad(card: PlaceCard) {
//        self.selectionStyle = .default
//        self.addSubview(grid)
//        grid.addSubview(indicator)
//        grid.addSubview(openLabel)
//        grid.addSubview(dayView)
//
//        grid.snp.makeConstraints { (make) in
//            make.left.right.equalTo(self).inset(leftRight)
//            make.top.bottom.equalTo(self).inset(topBottom)
//        }
//
//        indicator.isUserInteractionEnabled = false
//        indicator.setImage(UIImage(named: "RIP-Expand"), for: .normal)
//        indicator.contentHorizontalAlignment = .right
//        indicator.tintColor = .black
//        indicator.snp.makeConstraints { make in
//            make.right.equalTo(self).inset(leftRight)
//            make.top.bottom.equalTo(self).inset(topBottom)
//            make.width.equalTo(25)
//        }
//
//        openLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
//        openLabel.numberOfLines = 2
//        openLabel.snp.makeConstraints { (make) in
//            make.top.bottom.equalTo(grid)
//            make.left.equalTo(grid)
//            make.right.equalTo(indicator.snp.left)
//        }
//
//
//        if let hours: [Hour] = card.decode(name: "hours", [Hour].self) {
//            let grouped = hours.grouped
//            dayView.render(hourGrouped: grouped)
//            dayView.isHidden = true
//
//            let attributedText = NSMutableAttributedString()
//            switch grouped.isOpen() {
//            case .opening:
//                attributedText.append("Opening Soon\n".set(style: PlaceBasicBusinessHourCard.openStyle))
//            case .open:
//                attributedText.append("Open Now\n".set(style: PlaceBasicBusinessHourCard.openStyle))
//            case .closing:
//                attributedText.append("Closing Soon\n".set(style: PlaceBasicBusinessHourCard.closeStyle))
//            case .closed: fallthrough
//            case .none:
//                attributedText.append("Closed Now\n".set(style: PlaceBasicBusinessHourCard.closeStyle))
//
//            }
//
//
//            attributedText.append(grouped.todayDayTimeRange.set(style: PlaceBasicBusinessHourCard.hourStyle))
//            openLabel.attributedText = attributedText
//        }
//    }
//
//    override func didTap() {
//        dayView.isHidden = !dayView.isHidden
//        openLabel.isHidden = !openLabel.isHidden
//        indicator.isHidden = !indicator.isHidden
//
//        if (openLabel.isHidden) {
//            openLabel.snp.removeConstraints()
//            dayView.snp.makeConstraints { (make) in
//                make.top.bottom.equalTo(grid)
//                make.left.right.equalTo(grid)
//                make.height.equalTo(39 * 7).priority(999)
//            }
//        }
//
//        if (dayView.isHidden) {
//            dayView.snp.removeConstraints()
//            openLabel.snp.makeConstraints { (make) in
//                make.top.bottom.equalTo(grid)
//                make.left.equalTo(grid)
//                make.right.equalTo(indicator.snp.left)
//            }
//        }
//
//        self.controller.apply(click: .hours)
//    }
//
//    override class var cardId: String? {
//        return "basic_BusinessHour_20170907"
//    }
//
//    class DayView: UIView {
//        let dayLabels = [UILabel(), UILabel(), UILabel(), UILabel(), UILabel(), UILabel(), UILabel()]
//
//        override init(frame: CGRect = CGRect.zero) {
//            super.init(frame: frame)
//            self.clipsToBounds = true
//
//            for (index, label) in dayLabels.enumerated() {
//                label.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
//                label.numberOfLines = 2
//                self.addSubview(label)
//
//                label.snp.makeConstraints { make in
//                    make.left.right.equalTo(self)
//                    make.height.equalTo(39).priority(998)
//
//                    if index == 0 {
//                        make.top.equalTo(self)
//                    } else {
//                        make.top.equalTo(dayLabels[index - 1].snp.bottom)
//                    }
//                }
//            }
//        }
//
//        required init?(coder aDecoder: NSCoder) {
//            fatalError("init(coder:) has not been implemented")
//        }
//
//        func render(hourGrouped: Hour.Grouped) {
//            func createLine(day: Hour.Day, dayText: String) -> NSAttributedString {
//                if day.isToday {
//                    switch hourGrouped.isOpen() {
//                    case .opening: fallthrough
//                    case .closing: fallthrough
//                    case .open:
//                        return dayText.set(style: PlaceBasicBusinessHourCard.boldStyle) + "\n"
//                                + hourGrouped[day].set(style: PlaceBasicBusinessHourCard.openStyle)
//                    case .closed: fallthrough
//                    case .none:
//                        return dayText.set(style: PlaceBasicBusinessHourCard.boldStyle) + "\n"
//                                + hourGrouped[day].set(style: PlaceBasicBusinessHourCard.closeStyle)
//                    }
//                } else {
//                    return NSAttributedString(string: "\(dayText)\n\(hourGrouped[day])")
//                }
//            }
//
//            dayLabels[0].attributedText = createLine(day: Hour.Day.mon, dayText: "Monday")
//            dayLabels[1].attributedText = createLine(day: Hour.Day.tue, dayText: "Tuesday")
//            dayLabels[2].attributedText = createLine(day: Hour.Day.wed, dayText: "Wednesday")
//            dayLabels[3].attributedText = createLine(day: Hour.Day.thu, dayText: "Thursday")
//            dayLabels[4].attributedText = createLine(day: Hour.Day.fri, dayText: "Friday")
//            dayLabels[5].attributedText = createLine(day: Hour.Day.sat, dayText: "Saturday")
//            dayLabels[6].attributedText = createLine(day: Hour.Day.sun, dayText: "Sunday")
//        }
//    }
//}
//
//
