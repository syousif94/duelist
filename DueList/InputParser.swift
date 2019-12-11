//
//  InputParser.swift
//  DueList
//
//  Created by Sammy Yousif on 12/9/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//

import Foundation
import SwiftDate

class InputParser {
    
    enum Invalid: String {
        case time = "Time"
        case month = "Date"
        case year = "Year"
    }
    
    struct Output {
        let raw: String
        let title: String
        let date: DateInRegion?
        let invalid: Invalid?
    }
    
    static let excludedTerms: [String] = ["at", "due"]
    
    func isTime(text: String) -> Bool {
        let longFormatMatches = text.numberOfMatches(pattern: #"^[\d]{1,2}((a|p)|:[\d]{0,2})"#)
        
        let shortFormMatch: Bool
        
        if let val = Int(text), val < 13, val > 0 {
            shortFormMatch = true
        }
        else {
            shortFormMatch = false
        }
        
        return longFormatMatches > 0 || shortFormMatch
    }
    
    func makeDate(month: ParsableMonth? = nil, dayOfMonth: Int? = nil, day: Day? = nil, timeText: String, year: Int? = nil) -> (DateInRegion?, Invalid?) {
        
        let currentDate = Date().in(region: Region.current)
        var date = currentDate
        
        guard let (hour, minutes) = breakTime(text: timeText),
            let newDate = date.dateBySet(hour: hour, min: minutes, secs: nil) else {
            return (nil, .time)
        }
        
        date = newDate
        
        let extendedYear: Int?
        if let year = year, year < 100 {
            let currentYear = date.year
            let shortYear = currentYear % 1000
            let modifiedYear = currentYear - shortYear + year
            if modifiedYear >= currentYear {
                extendedYear = modifiedYear
            }
            else {
                extendedYear = nil
            }
        }
        else {
            extendedYear = year
        }
        
        if let month = month {
            let monthValue = month.monthValue
            let monthInt = monthValue.rawValue + 1
            var dateComponents: [Calendar.Component: Int?] = [.month: monthInt, .day: dayOfMonth]
            if let year = extendedYear {
                dateComponents[.year] = year
            }
            guard let dayOfMonth = dayOfMonth,
                dayOfMonth > 0,
                let newDate = date.dateBySet(dateComponents) else {
                return (nil, .month)
            }
            
            date = newDate
            
            if date.isBeforeDate(currentDate, orEqual: true, granularity: .minute) {
                if extendedYear != nil {
                    return (nil, .year)
                }
                date = date.dateByAdding(1, .year)
            }
            
            guard monthInt == date.month, dayOfMonth <= month.monthValue.numberOfDays(year: date.year) else {
                return (nil, .month)
            }
        }
        else if let day = day {
            switch day {
            case .today:
                if date.isBeforeDate(currentDate, orEqual: true, granularity: .minute) {
                    date = date.dateByAdding(1, .day)
                }
            case .tomorrow:
                date = date.dateByAdding(1, .day)
            default:
                date = date.dateAt(.nextWeekday(day.weekdayValue!))
                if date.isBeforeDate(currentDate, orEqual: true, granularity: .minute) {
                    date = date.dateByAdding(7, .day)
                }
            }
        }
        
        return (date, nil)
    }
    
    func breakTime(text: String) -> (hour: Int, minutes: Int)? {
        
        var hour: Int? = nil
        var minutes: Int? = nil
        
        let hasColon = text.numberOfMatches(pattern: #":"#) > 0
        let hasAM = text.numberOfMatches(pattern: #"a"#) > 0
        
        if hasColon {
            if text.numberOfMatches(pattern: #":[\d]{2}"#) == 0 {
                return nil
            }
            let components = text.replace(pattern: #"(a|p)m?"#, with: "").split(separator: ":").map { Int($0) }
            hour = components[0]
            minutes = components[1]
        }
        else {
            hour = Int(text.replace(pattern: #"(a|p)m?"#, with: ""))
            minutes = 0
        }
        
        if !hasAM, let tempHour = hour, tempHour < 12 {
            hour = tempHour + 12
        }
        else if hasAM, let tempHour = hour, tempHour == 12 {
            hour = 0
        }
        
        if let hour = hour, let minutes = minutes {
            return (hour, minutes)
        }
        
        return nil
    }
    
    func isSlashedDate(text: String) -> Bool {
        let matches = text.numberOfMatches(pattern: #"\/[\d]"#)
        return matches > 0 && matches < 3
    }
    
    func parse(text: String) -> Output {
        let tokens = text.split(separator: " ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !InputParser.excludedTerms.contains($0)  }
        
        var strings = [String]()
        var month: ParsableMonth? = nil
        var monthIndex: Int? = nil
        var dayOfMonth: Int? = nil
        var year: Int? = nil
        var days = [Day]()
        var times = [String]()
        
        for (index, token) in tokens.enumerated() {
            if let parsedMonth = InputParser.monthStrings[token.lowercased()] {
                month = parsedMonth
                monthIndex = index
            }
            else if let monthIndex = monthIndex, index == monthIndex + 1, dayOfMonth == nil {
                if let day = Int(token.replace(pattern: #","#, with: "")) {
                    dayOfMonth = day
                }
            }
            else if let monthIndex = monthIndex, index == monthIndex + 2, dayOfMonth != nil {
                if token.count == 4 {
                    year = Int(token)
                }
            }
            else if isSlashedDate(text: token) {
                let components = token.split(separator: "/").compactMap { Int($0) }
                if components.count > 1 {
                    month = ParsableMonth(month: components[0])
                    dayOfMonth = components[1]
                    if components.count > 2 {
                        year = components[2]
                    }
                }
            }
            else if let day = InputParser.dayStrings[token.lowercased()] {
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
        
        var day = days.first
        
        var time = times.first
        
        if day != nil || month != nil, time == nil {
            time = "11:59pm"
        }
        else if month == nil, day == nil, time != nil {
            day = .today
        }
        
        let date: DateInRegion?
        let invalid: Invalid?
        
        if let month = month, let time = time {
            (date, invalid) = makeDate(month: month, dayOfMonth: dayOfMonth, timeText: time, year: year)
        }
        else if let day = day, let time = time {
            (date, invalid) = makeDate(day: day, timeText: time)
        }
        else {
            date = nil
            invalid = nil
        }
        
        return Output(raw: text, title: title, date: date, invalid: invalid)
    }
    
    enum ParsableMonth: String, CaseIterable {
        case january
        case february
        case march
        case april
        case may
        case june
        case july
        case august
        case september
        case october
        case november
        case december
        
        init?(month: Int) {
            if month < 1 || month > 12 {
                return nil
            }
            self = ParsableMonth.allCases[month - 1]
        }
        
        var monthValue: Month {
            switch self {
            case .january:
                return Month.january
            case .february:
                return Month.february
            case .march:
                return Month.march
            case .april:
                return Month.april
            case .may:
                return Month.may
            case .june:
                return Month.june
            case .july:
                return Month.july
            case .august:
                return Month.august
            case .september:
                return Month.september
            case .october:
                return Month.october
            case .november:
                return Month.november
            case .december:
                return Month.december
            }
        }
    }
    
    static let monthStrings: [String: ParsableMonth] = ParsableMonth.allCases.reduce([String: ParsableMonth]()) { months, month -> [String: ParsableMonth] in
       var months = months
       
       let text = month.rawValue.lowercased()
       let shortText = String(text[..<text.index(text.startIndex, offsetBy: 3)])
       
       months[text] = month
       months[shortText] = month
    
       return months
    }
    
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
        
        var weekdayValue: WeekDay? {
            switch self {
            case .today, .tomorrow:
                return nil
            case .monday:
                return WeekDay.monday
            case .tuesday:
                return WeekDay.tuesday
            case .wednesday:
                return WeekDay.wednesday
            case .thursday:
                return WeekDay.thursday
            case .friday:
                return WeekDay.friday
            case .saturday:
                return WeekDay.saturday
            case .sunday:
                return WeekDay.sunday
            }
        }
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
}
