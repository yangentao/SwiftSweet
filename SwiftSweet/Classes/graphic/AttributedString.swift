//
// Created by entaoyang on 2019-02-19.
// Copyright (c) 2019 yet.net. All rights reserved.
//

import Foundation
import CoreGraphics

#if os(iOS) || os(tvOS)
import UIKit
#else
import AppKit
#endif

public class StyledText {
    private var buffer: String = ""
    private var map: [NSRange: MyMap<NSAttributedString.Key, Any>] = [:]
    private var paragraph: NSMutableParagraphStyle? = nil

    public var count: Int {
        return buffer.count
    }

    public var value: NSAttributedString {
        let ss = NSMutableAttributedString(string: buffer)
        for (r, d) in map {
            if !d.map.isEmpty {
                ss.setAttributes(d.map, range: r)
            }
        }
        if let p = paragraph {
            ss.setAttributes([NSAttributedString.Key.paragraphStyle: p], range: NSRange(location: 0, length: buffer.count))
        }
        return ss
    }

    public func paragraphStyle() -> ParagraphBuilder {
        let b = ParagraphBuilder()
        paragraph = b.paragraph
        return b
    }


}

public extension StyledText {
    @discardableResult
    private func append(_ text: String, _ attrs: MyMap<NSAttributedString.Key, Any>) -> Self {
        if text.isEmpty {
            return self
        }
        let r = NSRange(location: buffer.count, length: text.count)
        buffer.append(text)
        map[r] = attrs
        return self
    }

    @discardableResult
    func append(_ text: String, _ attrs: [NSAttributedString.Key: Any]) -> Self {
        append(text, MyMap(attrs))
    }

    func append(_ text: String, block: (TextStyleBuilder) -> Void) -> Self {
        let b = TextStyleBuilder()
        block(b)
        return append(text, b.map)
    }

    func append(_ text: String) -> TextStyleBuilder {
        let b = TextStyleBuilder()
        append(text, b.map)
        return b
    }
}

public class ParagraphBuilder {
    fileprivate var paragraph: NSMutableParagraphStyle = NSMutableParagraphStyle()
}

public extension ParagraphBuilder {
    @discardableResult
    func lineBreakMode(_ n: NSLineBreakMode) -> ParagraphBuilder {
        self.paragraph.lineBreakMode = n
        return self
    }

    @discardableResult
    func alignment(_ n: NSTextAlignment) -> ParagraphBuilder {
        self.paragraph.alignment = n
        return self
    }

    @discardableResult
    func paragraphSpacing(_ n: CGFloat) -> ParagraphBuilder {
        self.paragraph.paragraphSpacing = n
        return self
    }

    @discardableResult
    func lineSpace(_ n: CGFloat) -> ParagraphBuilder {
        self.paragraph.lineSpacing = n
        return self
    }

    @discardableResult
    func indent(_ n: CGFloat) -> ParagraphBuilder {
        self.paragraph.firstLineHeadIndent = n
        return self
    }
}

public class TextStyleBuilder {
    fileprivate var map: MyMap<NSAttributedString.Key, Any> = MyMap(4)
}

public extension TextStyleBuilder {
    @discardableResult
    func keyValue(_ key: NSAttributedString.Key, _ value: Any) -> Self {
        map.map[key] = value
        return self
    }

    @discardableResult
    func link(_ url: URL) -> Self {
        map.map[.link] = url
        return self
    }

    @discardableResult
    func foreColor(_ color: Color) -> Self {
        map.map[.foregroundColor] = color
        return self
    }

    @discardableResult
    func backColor(_ color: Color) -> Self {
        map.map[.backgroundColor] = color
        return self
    }

    @discardableResult
    func underlineColor(_ color: Color) -> Self {
        map.map[.underlineColor] = color
        return self
    }

    @discardableResult
    func underlineStyle(_ u: NSUnderlineStyle) -> Self {
        map.map[.underlineStyle] = u.rawValue
        return self
    }


    @discardableResult
    func shadow(_ c: NSShadow) -> Self {
        map.map[.shadow] = c
        return self
    }

    @discardableResult
    func font(_ c: Font) -> Self {
        map.map[.font] = c
        return self
    }
}


public func htmlStr(_ font: Font, _ s: String) -> NSAttributedString {
    let ss = try? NSMutableAttributedString(data: s.dataUnicode, options: [
        NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html
    ], documentAttributes: nil)
    if let sss = ss {
        sss.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: sss.length))
        return sss
    }
    return NSAttributedString(string: s)
}

public extension NSAttributedString {

    func linkfy() -> NSMutableAttributedString {
        let s = NSMutableAttributedString(attributedString: self)

        guard let detect = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.phoneNumber.rawValue) else {
            return s
        }
        let ms = detect.matches(in: s.string, range: NSRange(location: 0, length: s.length))
        for m in ms {
            if m.resultType == .link, let url = m.url {
                s.addAttributes([NSAttributedString.Key.link: url,
                                 NSAttributedString.Key.foregroundColor: Color.blue,
                                 NSAttributedString.Key.underlineStyle: NSUnderlineStyle.patternDot.rawValue
                ], range: m.range)
            } else if m.resultType == .phoneNumber, let pn = m.phoneNumber {
                s.addAttributes([NSAttributedString.Key.link: pn,
                                 NSAttributedString.Key.foregroundColor: Color.blue,
                                 NSAttributedString.Key.underlineStyle: NSUnderlineStyle.patternDot.rawValue
                ], range: m.range)
            }
        }
        return s
    }

}
