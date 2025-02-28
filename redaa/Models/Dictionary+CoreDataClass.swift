//
//  Dictionary+CoreDataClass.swift
//  redaa
//
//  Created by Pierre on 2025/02/28.
//
//

import Foundation
import CoreData
import redaaDic

@objc(Dictionary)
public class Dictionary: NSManagedObject {

    private(set) var dictionary: RedaaDictionary? = nil
    
    public func loadDictionary() throws {
        //        let index: Path
        let fm = FileManager.default
        let documents = fm.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("dictionaries")

        var index = documents.appending(component: self.path).appending(component: "index.json")
        print(index)
#if targetEnvironment(simulator)
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            index = URL(string: self.path)!.appending(component: "index.json")
        }
#endif
        self.dictionary = try RedaaDictionary.loadFromJson(path: index)
    }
    
}
