//
//  IntentHandler.swift
//  TicksWidgetIntentsExtension
//
//  Created by Isaac Lyons on 6/24/21.
//

import Intents
import CoreData

class IntentHandler: INExtension, ConfigurationIntentHandling {
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
    func provideTracksOptionsCollection(for intent: ConfigurationIntent, with completion: @escaping (INObjectCollection<TrackItem>?, Error?) -> Void) {
        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Track.index, ascending: true)]
        
        do {
            let context = PersistenceController.shared.container.viewContext
            let tracks: [TrackItem] = try context.fetch(fetchRequest).compactMap { track in
                let id = track.objectID.uriRepresentation().absoluteString
                return TrackItem(identifier: id, display: track.name ??? "New Track")
            }
            completion(INObjectCollection(items: tracks), nil)
        } catch {
            completion(nil, error)
        }
    }
    
    func provideGroupOptionsCollection(for intent: ConfigurationIntent, with completion: @escaping (INObjectCollection<GroupItem>?, Error?) -> Void) {
        let fetchRequest: NSFetchRequest<TrackGroup> = TrackGroup.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TrackGroup.index, ascending: true)]
        
        do {
            let context = PersistenceController.shared.container.viewContext
            let groups: [GroupItem] = try context.fetch(fetchRequest).compactMap { group in
                let id = group.objectID.uriRepresentation().absoluteString
                return GroupItem(identifier: id, display: group.displayName)
            }
            completion(INObjectCollection(items: groups), nil)
        } catch {
            completion(nil, error)
        }
    }
    
}
