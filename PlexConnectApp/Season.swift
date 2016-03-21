//
//  Series.swift
//  PlexConnectApp
//
//  Created by Janos Kis on 08/03/2016.
//  Copyright © 2016 Baa. All rights reserved.
//

import Foundation
import SwiftyJSON

class SeasonModel: BaseModel {
    let usedKeys = ["key", "ratingKey", "title", "summary", "thumb", "index", "parentKey", "index"]
    var sourceJson : JSON?
    
    override func transform(var json: JSON){
        // Set up completetion handler
        for (key,value) in json {
            // Continue if we're not interested in the key
            if self.usedKeys.indexOf(key) == nil{
                continue
            }
            
            switch key {
                case "ratingKey":
                    self.transformed["id"] = value.int
                    self.transformed["path"] = "/library/metadata/" + value.stringValue
                    break
                case "key":
                    self.transformed["childPath"] = value.string
                    break
                case "parentKey":
                    self.transformed["parentPath"] = value.string
                    break
                case "thumb":
                    self.transformed[key] = self.getThumbUrls(value.stringValue)
                default:
                    self.transformed[key] = value.rawValue
            }
            
        }
        
        if json["leafCount"].int != nil &&  json["viewedLeafCount"].int != nil {
            self.transformed["watched"] = (json["leafCount"].int! == json["viewedLeafCount"].int!) as Bool
            
            if self.transformed["watched"]!.boolValue == false && json["viewedLeafCount"].int > 0 {
                self.transformed["partiallyWatched"] = true
            } else {
                self.transformed["partiallyWatched"] = false
            }
            
            self.transformed["unwatchedCount"] = json["leafCount"].int! - json["viewedLeafCount"].int!
            
            if self.transformed["unwatchedCount"] as! Int > 99 {
                self.transformed["unwatchedCount"] = "99+"
            }
        }
    }	
}