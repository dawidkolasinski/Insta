import Foundation

extension Date {
    func timeAgoShort() -> String {
        let now = Date()
        let seconds = max(0, Int(now.timeIntervalSince(self)))
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day

        func safeDiv(_ a: Int, _ b: Int) -> Int {
            b > 0 ? a / b : 0
        }

        switch seconds {
        case ..<minute:
            return "\(seconds)s"
        case minute..<(hour):
            return "\(safeDiv(seconds, minute))m"
        case hour..<(day):
            return "\(safeDiv(seconds, hour))h"
        case day..<(week):
            return "\(safeDiv(seconds, day))d"
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "d.MM"
            return formatter.string(from: self)
        }
    }
}
