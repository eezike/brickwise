import SwiftUI
import UIKit

extension UIColor {
    /// Accepts "#RRGGBB" or "RRGGBB".
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

enum Theme {
    static let background = Color(hex: "#0E1116")
    static let surface = Color(hex: "#171B22")
    static let border = Color(hex: "#2A303B")
    static let text = Color(hex: "#F2F4F7")
    static let secondary = Color(hex: "#A7B0BD")
    static let holo = Color(hex: "#4FE3F0")
    static let onHolo = Color(hex: "#06242A")
    static let success = Color(hex: "#5DD39E")
}
