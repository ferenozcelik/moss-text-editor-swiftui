import UIKit

/// Format used by ``Foundation/NSAttributedString/richTextData(format:)``.
public enum RichTextDataFormat: Sendable {
    /// A keyed archive of the attributed string. Lossless; readable by this package.
    case archive
    /// Rich Text Format. Readable by other apps and platforms.
    case rtf
}

public enum RichTextDataError: Error {
    case unreadableData
}

extension NSAttributedString {
    /// Encodes the text for storage.
    ///
    /// Text colors are left out so the text follows the editor's (light or dark)
    /// text color when it is loaded again.
    public func richTextData(format: RichTextDataFormat = .archive) throws -> Data {
        let text = NSMutableAttributedString(attributedString: self)
        text.removeAttribute(.foregroundColor, range: NSRange(location: 0, length: text.length))
        switch format {
        case .archive:
            return try NSKeyedArchiver.archivedData(withRootObject: text, requiringSecureCoding: true)
        case .rtf:
            return try text.data(
                from: NSRange(location: 0, length: text.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            )
        }
    }

    /// Decodes text created with ``richTextData(format:)``.
    public convenience init(richTextData data: Data, format: RichTextDataFormat = .archive) throws {
        switch format {
        case .archive:
            let classes: [AnyClass] = [
                NSAttributedString.self, NSString.self, NSNumber.self, NSDictionary.self, NSArray.self,
                UIFont.self, UIColor.self, NSParagraphStyle.self, NSTextTab.self,
            ]
            guard let text = try NSKeyedUnarchiver.unarchivedObject(ofClasses: classes, from: data) as? NSAttributedString else {
                throw RichTextDataError.unreadableData
            }
            self.init(attributedString: text)
        case .rtf:
            try self.init(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
        }
    }
}
