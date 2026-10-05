import UIKit

enum SampleText {
    /// The editor maps fonts onto its configured fonts by size, and treats
    /// `•\t` / `1.\t` prefixes as list items, so sample text can be built by hand.
    static var journal: NSAttributedString {
        let text = NSMutableAttributedString()
        func add(_ string: String, size: CGFloat = 17, weight: UIFont.Weight = .regular, _ extra: [NSAttributedString.Key: Any] = [:]) {
            var attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: size, weight: weight)]
            attributes.merge(extra) { $1 }
            text.append(NSAttributedString(string: string, attributes: attributes))
        }
        add("A quiet Sunday\n", size: 28, weight: .bold)
        add("Woke up early and went for a walk. The air was ")
        add("cold", weight: .bold)
        add(" but ")
        add("clear", [.underlineStyle: NSUnderlineStyle.single.rawValue])
        add(".\n")
        add("Things I'm grateful for\n", size: 22, weight: .bold)
        add("•\tCoffee with a friend\n•\tA long, slow lunch\n")
        add("Tomorrow\n", size: 22, weight: .bold)
        add("1.\tFinish the chapter\n2.\tCall mom\n3.\t")
        add("Old plan", [.strikethroughStyle: NSUnderlineStyle.single.rawValue])
        return text
    }
}
