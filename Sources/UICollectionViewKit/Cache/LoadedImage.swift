import UIKit

enum LoadedImage {
    case `static`(UIImage)
    case animated(AnimatedImageSequence)

    var posterImage: UIImage {
        switch self {
        case let .static(image):
            image
        case let .animated(sequence):
            sequence.posterFrame
        }
    }

    var isAnimated: Bool {
        if case .animated = self { return true }
        return false
    }
}

struct AnimatedImageSequence {
    let frames: [UIImage]
    let duration: TimeInterval

    var posterFrame: UIImage { frames[0] }
}

final class LoadedImageBox: NSObject {
    let value: LoadedImage

    init(_ value: LoadedImage) {
        self.value = value
    }
}
