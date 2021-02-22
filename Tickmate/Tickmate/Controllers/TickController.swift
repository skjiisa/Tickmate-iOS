//
//  TickController.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/21/21.
//

import CoreData
import SwiftDate

class TickController: ObservableObject {
    
    let track: Track
    @Published var ticks: [Set<Tick>] = []
    
    init(track: Track) {
        self.track = track
        loadTicks()
    }
    
    func loadTicks() {
        let fetchRequest: NSFetchRequest<Tick> = Tick.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "track == %@", track)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Tick.timestamp, ascending: false)]
        guard let ticks = try? track.managedObjectContext?.fetch(fetchRequest),
              let today = Date().dateTruncated([.hour, .minute, .second]) else { return }
        
        var tickDays: [(day: Int, tick: Tick)] = []
        
        for tick in ticks {
            guard let timestamp = tick.timestamp?.dateTruncated([.hour, .minute, .second]),
                  let days = (today - timestamp).day else { continue }
            guard days < 365 else { break }
            tickDays.append((days, tick))
        }
        
        var days: [Set<Tick>] = []
        var i = 0
        
        for day in 0..<365 {
            var dayTicks = Set<Tick>()
            while i < tickDays.count,
                  tickDays[i].day == day {
                dayTicks.insert(tickDays[i].tick)
                i += 1
            }
            
            days.append(dayTicks)
            
            guard i < tickDays.count else { break }
        }
        
        self.ticks = days
        print(self.ticks)
    }
    
    func ticks(on day: Int) -> Set<Tick> {
        guard ticks.indices.contains(day) else { return [] }
        return ticks[day]
    }
    
}
