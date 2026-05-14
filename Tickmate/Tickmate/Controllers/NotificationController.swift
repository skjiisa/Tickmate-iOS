//
//  NotificationController.swift
//  Tickmate
//
//  Created by Elaine Lyons on 5/13/26.
//

import UserNotifications
import CoreData
import SwiftDate

struct NotificationController {
    static func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    static func rescheduleAll(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "enabled == YES AND isArchived == NO")

        do {
            let tracks = try context.fetch(fetchRequest)
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            for track in tracks {
                reschedule(track: track, context: context)
            }
        } catch {
            NSLog("Error fetching tracks for notification reschedule: \(error)")
        }
    }

    static func reschedule(track: Track, context: NSManagedObjectContext) {
        guard let notificationMinute = track.notificationMinute as? Int16 else {
            cancel(for: track)
            return
        }

        guard !track.isArchived && track.enabled && !track.reversed else {
            cancel(for: track)
            return
        }

        guard let trackAlreadyTicked = isTrackTickedToday(track: track, context: context) else {
            return
        }

        if trackAlreadyTicked {
            cancel(for: track)
            return
        }

        let hour = Int(notificationMinute) / 60
        let minute = Int(notificationMinute) % 60

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        var triggerComponents = dateComponents
        let now = Date()

        let trigger: UNCalendarNotificationTrigger
        let testTrigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        if let nextFireDate = testTrigger.nextTriggerDate(), nextFireDate <= now {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
            triggerComponents.year = Calendar.current.component(.year, from: tomorrow)
            triggerComponents.month = Calendar.current.component(.month, from: tomorrow)
            triggerComponents.day = Calendar.current.component(.day, from: tomorrow)
            trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        } else {
            trigger = testTrigger
        }

        let content = UNMutableNotificationContent()
        content.title = track.name ?? "Track"
        content.body = "Don't forget to complete \"\(track.name ?? "this track")\" today."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier(for: track),
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("Error scheduling notification for track \(track.name ?? "unknown"): \(error)")
            }
        }
    }

    static func cancel(for track: Track) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier(for: track)]
        )
    }

    static func identifier(for track: Track) -> String {
        track.objectID.uriRepresentation().absoluteString
    }

    private static func isTrackTickedToday(track: Track, context: NSManagedObjectContext) -> Bool? {
        guard let startDateString = track.startDate,
              let startDate = DateInRegion(startDateString, region: .current)?.dateTruncated(at: [.hour, .minute, .second]) else {
            return nil
        }

        let adjustedDate = Date() - TrackController.dayOffset
        guard let today = adjustedDate.in(region: .current).dateTruncated(at: [.hour, .minute, .second]) else {
            return nil
        }

        let todayOffset = (today - (startDate - 2.hours)).toUnit(.day) ?? 0

        let fetchRequest: NSFetchRequest<Tick> = Tick.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "track == %@ AND dayOffset == %d", track, todayOffset)

        do {
            let ticks = try context.fetch(fetchRequest)
            return !ticks.isEmpty
        } catch {
            NSLog("Error checking if track is ticked today: \(error)")
            return nil
        }
    }
}
