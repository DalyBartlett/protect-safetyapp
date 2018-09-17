import Foundation
import UIKit
enum Pin {
    case green
    case blue
    case red
    case yellow
    var image: UIImage {
        switch self {
        case .green:
            return UIImage(named:"pin_green")!
        case .blue:
            return UIImage(named:"pin_blue")!
        case .red:
            return UIImage(named:"pin_red")!
        case .yellow:
            return UIImage(named:"pin_yellow")!
        }
    }
    var light:UIColor {
        switch self {
        case .green:
            return UIColor(red: 0/255, green: 220/255, blue: 0/255, alpha: 1)
        case .blue:
            return UIColor(red: 0/255, green: 0/255, blue: 220/255, alpha: 1)
        case .red:
            return UIColor(red: 220/255, green: 0/255, blue: 0/255, alpha: 1)
        case .yellow:
            return UIColor(red: 220/255, green: 220/255, blue: 0/255, alpha: 1)
        }
    }
    var dark:UIColor {
        switch self {
        case .green:
            return UIColor(red: 0/255, green: 160/255, blue: 0/255, alpha: 1)
        case .blue:
            return UIColor(red: 0/255, green: 0/255, blue: 160/255, alpha: 1)
        case .red:
            return UIColor(red: 160/255, green: 0/255, blue: 0/255, alpha: 1)
        case .yellow:
            return UIColor(red: 160/255, green: 160/255, blue: 0/255, alpha: 1)
        }
    }
}
