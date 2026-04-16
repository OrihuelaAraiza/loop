import SwiftUI

struct LoopFont {
    static func black(_ size: CGFloat) -> Font { .custom("Nunito-Black", size: size) }
    static func bold(_ size: CGFloat) -> Font { .custom("Nunito-Bold", size: size) }
    static func semiBold(_ size: CGFloat) -> Font { .custom("Nunito-SemiBold", size: size) }
    static func medium(_ size: CGFloat) -> Font { .custom("Nunito-Medium", size: size) }
    static func regular(_ size: CGFloat) -> Font { .custom("Nunito-Regular", size: size) }
}
