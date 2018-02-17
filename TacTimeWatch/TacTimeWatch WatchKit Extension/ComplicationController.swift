//
//  ComplicationController.swift
//  TacTimeWatch WatchKit Extension
//
//  Created by bibek timalsina on 1/24/18.
//  Copyright © 2018 bibek timalsina. All rights reserved.
//

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        //handler([.forward, .backward])
        handler([])
    }
    
    func getNextRequestedUpdateDate(handler: @escaping (Date?) -> Void) {
        handler(Date(timeIntervalSinceNow: TimeInterval(10*60)))
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        switch complication.family {
            
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallRingText()
            template.textProvider = CLKSimpleTextProvider(text: "")
            template.fillFraction = self.dayFraction
            handler(CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template))
            
        case .utilitarianSmall:
            let template = CLKComplicationTemplateUtilitarianSmallRingText()
            template.textProvider = CLKSimpleTextProvider(text: "")
            template.fillFraction = self.dayFraction
            handler(CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template))
            
        default:
            NSLog("%@", "Unknown complication type: \(complication.family)")
            handler(nil)
        }
    }
 /*
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
 */
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        if complication.family == .utilitarianSmall {
            let template = CLKComplicationTemplateUtilitarianSmallRingText()
            template.textProvider = CLKSimpleTextProvider(text: "XX")
            template.fillFraction = self.dayFraction
            handler(template)
        } else {
            handler(nil)
        }
    }
    
    var dayFraction : Float {
        let now = Date()
        let calendar = Calendar.current
        let componentFlags = Set<Calendar.Component>([.year, .month, .day, .weekOfYear,  .hour, .minute, .second, .weekday, .weekdayOrdinal])
        var components = calendar.dateComponents(componentFlags, from: now)
        components.hour = 0
        components.minute = 0
        components.second = 0
        let startOfDay = calendar.date(from: components)!
        return Float(now.timeIntervalSince(startOfDay)) / Float(24*60*60)
    }
    
}
