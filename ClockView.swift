import UIKit
@IBDesignable
class ClockView: UIView {
    @IBInspectable
    var currentTime:Double = 1.0 {
        didSet{
            self.setNeedsDisplay()
        }
    }
    override func draw(_ rect: CGRect) {
        let contexto:CGContext! = UIGraphicsGetCurrentContext()
        contexto.saveGState()
        let raio = 90.0
        contexto.setFillColor(UIColor(red: 235/255, green: 0/255, blue: 0/255, alpha: 1).cgColor)
        contexto.setStrokeColor(UIColor(red: 235/255, green: 0/255, blue: 0/255, alpha: 1).cgColor)
        contexto.setLineWidth(10.0)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let endAngle = (3 * .pi / 2.0) + (currentTime < 1.0 ? -2 * .pi * currentTime : 0)
        contexto.addArc(center: center, radius: CGFloat(raio), startAngle: -(.pi / 2) , endAngle: CGFloat(endAngle) , clockwise: (currentTime < 1.0))
        let drawPath = UIBezierPath()
        drawPath.lineWidth = 10.0
        drawPath.stroke()
    }
}
