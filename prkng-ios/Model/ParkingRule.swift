//
//  ParkingRule.swift
//  prkng-ios
//
//  Created by Cagdas Altinkaya on 24/02/15.
//  Copyright (c) 2015 PRKNG. All rights reserved.
//

import UIKit

enum ParkingRuleType: String {
    case TimeMax = "TimeMax"
    case Restriction = "Restriction"
    case Paid = "Paid"
    case Free = "Free"
}


class ParkingRule: NSObject {

    var restrictionType: String
    var paidHourlyRate: Float
    var code: String
    var maxParkingTime: Int
    var seasonEnd: String
    var desc: String
    var agenda : Array<TimePeriod?>
    
    var bullshitRule : Bool // means this rule is empty

    var paidHourlyRateString: String {
        let hourlyRate = Float(round(100*paidHourlyRate)/100)
        return String(format: "%.2f", hourlyRate)
    }
    
    private var _ruleType: ParkingRuleType?
    var ruleType: ParkingRuleType {
        
        if _ruleType != nil {
            return _ruleType!
        }
        
        if bullshitRule {
            return .Free
        }
        if restrictionType == "paid" {
            return .Paid
        }
        if self.maxParkingTime > 0 {
            return .TimeMax
        } else {
            return .Restriction
        }

    }
    
    init(ruleType: ParkingRuleType) {
        _ruleType = ruleType
        restrictionType = ""
        code = ""
        paidHourlyRate = 0
        maxParkingTime = 0
        seasonEnd = ""
        desc = ""
        agenda = Array()
        bullshitRule = true
    }
    
    // bsIndex is a stupid parameter, because the data structure sucks. There may be two rule sets. Remove it when the data structure is fixed.
    init(json: JSON, bsIndex : Int) {

        restrictionType = json["restrict_typ"].stringValue
        code = json["code"].stringValue
        paidHourlyRate = json["paid_hourly_rate"].floatValue
        
        let timelimit = json["time_max_parking"].int
        
        if(timelimit != nil) {
            maxParkingTime = timelimit!
        } else {
            maxParkingTime = 0
        }
        
        seasonEnd = json["season_end"].stringValue
        desc = json["description"].stringValue
        
        var agendaJson = json["agenda"]
        
        agenda = Array()
        
        bullshitRule = true
        
        // MONDAY
        
        var mon : Array<Float> = Array()
        let monStart : Float? = agendaJson["1"][bsIndex][0].float
        let monEnd : Float? = agendaJson["1"][bsIndex][1].float
        
        var monTimePeriod : TimePeriod? = nil
        
        if monStart != nil && monEnd != nil  {
            monTimePeriod = TimePeriod(startTime: Double(monStart! * 3600), endTime: Double (monEnd! * 3600), maxParkingTime : NSTimeInterval(maxParkingTime * 60) )
            
            bullshitRule = false
        }
        agenda.append(monTimePeriod)
    
        // TUESDAY
        
        var tue : Array<Float> = Array()
        let tueStart : Float? = agendaJson["2"][bsIndex][0].float
        let tueEnd : Float? = agendaJson["2"][bsIndex][1].float
        
        var tueTimePeriod : TimePeriod? = nil
        
        if tueStart != nil && tueEnd != nil  {
            tueTimePeriod = TimePeriod(startTime: Double(tueStart! * 3600), endTime: Double (tueEnd! * 3600), maxParkingTime : NSTimeInterval(maxParkingTime * 60) )
            
            bullshitRule = false
        }
        agenda.append(tueTimePeriod)
        
        // WEDNESDAY
        
        var wed : Array<Float> = Array()
        let wedStart : Float? = agendaJson["3"][bsIndex][0].float
        let wedEnd : Float? = agendaJson["3"][bsIndex][1].float
        
        var wedTimePeriod : TimePeriod? = nil
        
        if wedStart != nil && wedEnd != nil  {
            wedTimePeriod = TimePeriod(startTime: Double(wedStart! * 3600), endTime: Double (wedEnd! * 3600), maxParkingTime : NSTimeInterval(maxParkingTime * 60) )
            
            bullshitRule = false
        }
        agenda.append(wedTimePeriod)
        
        // THURSDAY
        
        var thu : Array<Float> = Array()
        let thuStart : Float? = agendaJson["4"][bsIndex][0].float
        let thuEnd : Float? = agendaJson["4"][bsIndex][1].float
        
        var thuTimePeriod : TimePeriod? = nil
        
        if thuStart != nil && thuEnd != nil  {
            thuTimePeriod = TimePeriod(startTime: Double(thuStart! * 3600), endTime: Double (thuEnd! * 3600), maxParkingTime : NSTimeInterval(maxParkingTime * 60) )
            
            bullshitRule = false
        }
        agenda.append(thuTimePeriod)
        
        // FRIDAY
        
        var fri : Array<Float> = Array()
        let friStart : Float? = agendaJson["5"][bsIndex][0].float
        let friEnd : Float? = agendaJson["5"][bsIndex][1].float
        
        var friTimePeriod : TimePeriod? = nil
        
        if friStart != nil && friEnd != nil  {
            friTimePeriod = TimePeriod(startTime: Double(friStart! * 3600), endTime: Double (friEnd! * 3600), maxParkingTime : NSTimeInterval(maxParkingTime * 60) )
            
            bullshitRule = false
        }
        agenda.append(friTimePeriod)
        
        
        // SATURDAY
        
        var sat : Array<Float> = Array()
        let satStart : Float? = agendaJson["6"][bsIndex][0].float
        let satEnd : Float? = agendaJson["6"][bsIndex][1].float
        
        var satTimePeriod : TimePeriod? = nil
        
        if satStart != nil && satEnd != nil  {
            satTimePeriod = TimePeriod(startTime: Double(satStart! * 3600), endTime: Double (satEnd! * 3600), maxParkingTime : NSTimeInterval(maxParkingTime * 60) )
            
            bullshitRule = false

        }
        agenda.append(satTimePeriod)
        
        
        // SUNDAY
        
        var sun : Array<Float> = Array()
        let sunStart : Float? = agendaJson["7"][bsIndex][0].float
        let sunEnd : Float? = agendaJson["7"][bsIndex][1].float
        
        var sunTimePeriod : TimePeriod? = nil
        
        if sunStart != nil && sunEnd != nil  {
            sunTimePeriod = TimePeriod(startTime: Double(sunStart! * 3600), endTime: Double (sunEnd! * 3600), maxParkingTime : NSTimeInterval(maxParkingTime * 60) )
            
            bullshitRule = false

        }
        agenda.append(sunTimePeriod)
    }


}

//a TimePeriod holds the start time and end time in seconds on that day. 
func ==(lhs: TimePeriod, rhs: TimePeriod) -> Bool {
    return lhs.start == rhs.start
        && lhs.end == rhs.end
        && lhs.timeLimit == rhs.timeLimit
}

class TimePeriod : Equatable {
    var start : NSTimeInterval
    var end : NSTimeInterval
    var timeLimit : NSTimeInterval
    
    init (startTime : NSTimeInterval, endTime : NSTimeInterval, maxParkingTime : NSTimeInterval) {
        start = startTime
        end = endTime
        timeLimit = maxParkingTime
    }
}


class SimplifiedParkingRule {
    var timePeriod: TimePeriod
    var day: Int //0 means today, 1 tomorrow, etc

    init (timePeriod: TimePeriod, day: Int) {
        self.timePeriod = timePeriod
        self.day = day
    }
    
}
