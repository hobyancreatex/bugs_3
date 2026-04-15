//
//  InsectDetailDescriptionComposer.swift
//  Bugs
//

import UIKit

enum InsectDetailDescriptionComposer {

    static let readMoreURL = URL(string: "insect-detail://read-more")!
    static let readLessURL = URL(string: "insect-detail://read-less")!

    /// До 8 полных строк + девятая с «… Read More»; короткий текст без ссылки.
    private static let collapsedMaxLines: CGFloat = 9

    /// Текст длиннее «свернутого» превью — нужны Read More / Read Less.
    static func isTextLongEnoughToCollapse(fullText: String, width: CGFloat) -> Bool {
        guard width > 0, !fullText.isEmpty else { return false }
        let bodyFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.paragraphSpacing = 0
        paragraph.lineSpacing = 0
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: UIColor.appDescriptionBody,
            .paragraphStyle: paragraph
        ]
        let fullAttr = NSAttributedString(string: fullText, attributes: bodyAttrs)
        let maxHeight = bodyFont.lineHeight * collapsedMaxLines + 4
        return height(of: fullAttr, width: width) > maxHeight
    }

    static func expandedAttributed(fullText: String) -> NSAttributedString {
        let bodyFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.paragraphSpacing = 0
        paragraph.lineSpacing = 0
        let attrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: UIColor.appDescriptionBody,
            .paragraphStyle: paragraph
        ]
        return NSAttributedString(string: fullText, attributes: attrs)
    }

    /// Полный текст + ссылка «Read Less» сразу под текстом (без лишних пустых строк в конце описания).
    static func expandedAttributedWithReadLess(fullText: String, readLessTitle: String) -> NSAttributedString {
        let trimmedBody = fullText.replacingOccurrences(
            of: "\\s+$",
            with: "",
            options: .regularExpression
        )
        let base = NSMutableAttributedString(attributedString: expandedAttributed(fullText: trimmedBody))
        let readLessFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.paragraphSpacing = 0
        paragraph.lineSpacing = 0
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor.appDescriptionBody,
            .paragraphStyle: paragraph
        ]
        let readLessAttrs: [NSAttributedString.Key: Any] = [
            .font: readLessFont,
            .foregroundColor: UIColor.appReadMore,
            .link: readLessURL
        ]
        // Один перевод строки между абзацем и ссылкой — без «дыры» на несколько строк.
        base.append(NSAttributedString(string: "\n", attributes: bodyAttrs))
        base.append(NSAttributedString(string: readLessTitle, attributes: readLessAttrs))
        return base
    }

    static func collapsedAttributed(fullText: String, width: CGFloat, readMoreTitle: String) -> NSAttributedString {
        let bodyFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        let readMoreFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.paragraphSpacing = 0
        paragraph.lineSpacing = 0
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: UIColor.appDescriptionBody,
            .paragraphStyle: paragraph
        ]
        let readMoreAttrs: [NSAttributedString.Key: Any] = [
            .font: readMoreFont,
            .foregroundColor: UIColor.appReadMore,
            .link: readMoreURL
        ]

        let suffixTail = NSMutableAttributedString()
        suffixTail.append(NSAttributedString(string: "… ", attributes: bodyAttrs))
        suffixTail.append(NSAttributedString(string: readMoreTitle, attributes: readMoreAttrs))

        let maxHeight = bodyFont.lineHeight * collapsedMaxLines + 4
        let fullAttr = NSAttributedString(string: fullText, attributes: bodyAttrs)
        if height(of: fullAttr, width: width) <= maxHeight {
            return fullAttr
        }

        let ns = fullText as NSString
        let utf16Len = ns.length
        var low = 0
        var high = utf16Len
        while low < high {
            let mid = (low + high + 1) / 2
            let prefix = ns.substring(with: NSRange(location: 0, length: mid))
            let trial = NSMutableAttributedString(string: prefix, attributes: bodyAttrs)
            trial.append(suffixTail)
            if height(of: trial, width: width) <= maxHeight {
                low = mid
            } else {
                high = mid - 1
            }
        }

        var prefix = ns.substring(with: NSRange(location: 0, length: low))
        prefix = refinePrefix(prefix, utf16PrefixLength: low, in: fullText)
        if prefix.isEmpty, utf16Len > 0 {
            prefix = ns.substring(with: NSRange(location: 0, length: 1))
        }

        let result = NSMutableAttributedString(string: prefix, attributes: bodyAttrs)
        result.append(suffixTail)
        return result
    }

    /// Если обрезка пришлась на середину слова, откатываем к последнему пробелу.
    private static func refinePrefix(_ prefix: String, utf16PrefixLength: Int, in fullText: String) -> String {
        let nsFull = fullText as NSString
        guard utf16PrefixLength < nsFull.length, !prefix.isEmpty else {
            return prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let nextIdx = String.Index(utf16Offset: utf16PrefixLength, in: fullText)
        guard nextIdx < fullText.endIndex else { return prefix.trimmingCharacters(in: .whitespacesAndNewlines) }
        let next = fullText[nextIdx]
        if next.isWhitespace || next.isNewline {
            return prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let lastBreak = prefix.lastIndex(where: { $0.isWhitespace || $0.isNewline }) {
            return String(prefix[..<lastBreak]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return prefix.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func height(of attributed: NSAttributedString, width: CGFloat) -> CGFloat {
        guard width > 0 else { return 0 }
        let rect = attributed.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return ceil(rect.height)
    }
}
