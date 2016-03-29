//
//  Series.swift
//  PlexConnectApp
//
//  Created by Janos Kis on 08/03/2016.
//  Copyright © 2016 Baa. All rights reserved.
//

import Foundation
import SwiftyJSON

class EpisodeModel: BaseModel {
    let usedKeys = ["key", "ratingKey", "parentRatingKey", "title", "summary", "thumb", "index", "duration"]
    var sourceJson : JSON?
    
    override func _transform(var json: JSON){
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
                case "parentRatingKey":
                    self.transformed["parentPath"] = value.string
                    break
                case "thumb":
                    self.transformed[key] = self.getThumbUrls(value.stringValue)
				case "duration":
					self.transformed[key] = self.getDurationFromTimestamp(value.intValue)
                default:
                    self.transformed[key] = value.rawValue
            }
            
        }
		
		if json["viewCount"].int != nil && json["viewCount"].intValue > 0 {
			self.transformed["watched"] = true
		} else {
			self.transformed["watched"] = false
		}
    }	
}