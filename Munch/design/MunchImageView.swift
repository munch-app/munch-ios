//
//  MunchImageView.swift
//  Munch
//
//  Created by Fuxing Loh on 28/6/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import Kingfisher
import Shimmer

// TODO Need to deprecate this class, giving me headaches
public class MunchImageView: UIImageView {

    var size: CGSize?
    var images: [(CGSize, String)]?
    var rendered = false
    var completionHandler: CompletionHandler?
    let overlay = UIView()

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(overlay)
        overlay.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(named: String) {
        self.image = UIImage(named: named)
    }

    /**
     Render SourcedImage to UIImageView
     SourcedImage will contain a ImageMeta to use for rendering
     Shimmer is set to true by default
     */
    func render(sourcedImage: SourcedImage?, completionHandler: CompletionHandler? = nil) {
        render(images: sourcedImage?.images, completionHandler: completionHandler)
    }

    /**
     Render ImageMeta to UIImageView
     Choose the smallest fitting image if available
     Else if the largest images if none fit
     If imageMeta is nil, image will be set to nil too
     Shimmer is set to true by default
     */
    func render(images: [String: String]?, completionHandler: CompletionHandler? = nil) {
        self.images = MunchImageView.imageList(images: images)
        self.completionHandler = completionHandler
        self.rendered = false
        self.tryRender()
    }

    /**
     This try render code might be giving performance issues
     */
    private func tryRender() {
        if rendered {
            return
        }

        if let size = size, let images = self.images {
            if let url = MunchImageView.selectImage(images: images, size: size) {
                kf.setImage(with: URL(string: url), completionHandler: completionHandler)
            }
            self.rendered = true
        } else {
            kf.setImage(with: nil, completionHandler: completionHandler)
            self.rendered = false
        }
    }

    class func selectImage(images: [(CGSize, String)], size: CGSize) -> String? {
        let fitting = images.filter {
                    $0.0.width >= size.width && $0.0.height >= size.height
                }
                .sorted {
                    $0.0.width * $0.0.height < $1.0.width * $1.0.height
                }

        if let fit = fitting.get(0) {
            // Found the smallest fitting image
            return fit.1
        } else {
            // No fitting image found, take largest image
            let images = images.sorted {
                $0.0.width * $0.0.height > $1.0.width * $1.0.height
            }
            if let image = images.get(0) {
                return image.1
            } else {
                return nil
            }
        }
    }

    /**
     Parse [WidthxHeight: Url] into [(Width, Height, Url)]
     */
    class func imageList(images: [String: String]?) -> [(CGSize, String)]? {
        if let images = images {
            return images.map { key, value -> (CGSize, String) in
                let widthHeight = key.lowercased().components(separatedBy: "x")
                if (widthHeight.count == 2) {
                    if let width = Int(widthHeight[0]), let height = Int(widthHeight[1]) {
                        return (CGSize(width: width, height: height), value)
                    }
                } else if key == "original" {
                    // Original Image will be the max
                    return (CGSize(width: 10000, height: 10000), value)
                }

                // AnyFormat that cannot be parsed will be 0,0
                return (CGSize(width: 0, height: 0), value)
            }
        }
        return nil
    }

    class func prefetch(imageList: [[String: String]], size: CGSize) {
        let images: [URL] = imageList.compactMap({
            if let images = MunchImageView.imageList(images: $0) {
                if let image = selectImage(images: images, size: size) {
                    return URL(string: image)
                }
            }
            return nil
        })
        ImagePrefetcher(urls: images).start()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // So that it will only run once
        if self.size == nil {
            self.size = frameSize()
            self.tryRender()
        }
    }

    /**
     Return width and height in pixel
     */
    private func frameSize() -> CGSize {
        let scale = UIScreen.main.scale
        let width = frame.size.width
        let height = frame.size.height
        return CGSize(width: width * scale, height: height * scale)
    }
}