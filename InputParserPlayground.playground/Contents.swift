import Foundation

extension String {
    func numberOfMatches(pattern: String) -> Int {
        let options: NSRegularExpression.Options = [.caseInsensitive]
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return 0 }
        
        let range = NSRange(
            self.startIndex..<self.endIndex,
            in: self
        )
        
        return regex.numberOfMatches(in: self, options: [], range: range)
    }
}

class InputParser {
    enum Day: String, CaseIterable {
        case tomorrow
        case today
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday
        case sunday
    }
    
    static let dayStrings: [String: Day] = Day.allCases.reduce([String: Day]()) { days, day -> [String: Day] in
        var days = days
        
        let dayText = day.rawValue.lowercased()
        let shortDayText = String(dayText[..<dayText.index(dayText.startIndex, offsetBy: 3)])
        
        switch day {
        case .today, .tomorrow:
            days[dayText] = day
        default:
            days[dayText] = day
            days[shortDayText] = day
        }
        return days
    }
    
    struct Output {
        let raw: String
        let title: String
        let date: Date?
    }
    
    static let excludedTerms: [String] = ["at", "due"]
    
    func isTime(text: String) -> Bool {
        let longFormatMatches = text.numberOfMatches(pattern: #"^[\d]{1,2}((a|p)|:[\d]{2})"#)
        
        let shortFormMatch: Bool
        
        if let val = Int(text), val < 13, val > 0 {
            shortFormMatch = true
        }
        else {
            shortFormMatch = false
        }
        
        return longFormatMatches > 0 || shortFormMatch
    }
    
    func makeDate(day: Day, timeText: String) -> Date {
        return Date()
    }
    
    func parse(text: String) -> Output {
        let tokens = text.split(separator: " ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !InputParser.excludedTerms.contains($0)  }
        
        var strings = [String]()
        var days = [Day]()
        var times = [String]()
        
        for token in tokens {
            if let day = InputParser.dayStrings[token.lowercased()] {
                days.append(day)
            }
            else if isTime(text: token) {
                times.append(token)
            }
            else {
                strings.append(token)
            }
        }
        
        let title = strings.joined(separator: " ")
        
        let day = days.first
        
        var time = times.first
        
        if day != nil, time == nil {
            time = "11:59pm"
        }
        
        let date: Date?
        
        if let day = day, let time = time {
            date = makeDate(day: day, timeText: time)
        }
        else {
            date = nil
        }
        
        return Output(raw: text, title: title, date: date)
    }
}

let parser = InputParser()

parser.parse(text: "do laundry")
parser.parse(text: "paper due at 11 tomorrow")
parser.parse(text: "ee411 homework due tue 11:59")
parser.parse(text: "ee411 homework due tue 11:59a")
parser.parse(text: "ee41 homework due tue 11:59pm")
