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
    let usedKeys = ["key", "ratingKey", "parentKey", "title", "parentTitle", "parentGenre", "summary", "thumb", "index", "leafCount"]
    var sourceJson : JSON?
    
    override func _transform(var json: JSON){
		 var episodes : [AnyObject] = []
		
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
				case "grandparentContentRating":
					self.transformed["contentRating"] = value.stringValue.lowercaseString
                default:
                    self.transformed[key] = value.rawValue
            }
        }
		
		self.transformed["HD"] = true
        
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
		
		if self.children != nil {
			
			if self.children!["grandparentContentRating"] != nil {
				self.transformed["contentRating"] = self.children!["grandparentContentRating"].stringValue.lowercaseString
			}
			
			for (index,_) in self.children!["_children"].array!.enumerate() {
				let episode = ModelRegister.sharedInstance.createModel("episode", path: "/library/metadata/" + self.children!["_children"][index]["ratingKey"].stringValue, pmsId: self.pmsId!)
				
				// TODO
				episode.transform(self.children!["_children"][index])
				
				if !episode.transformed["HD"]!.boolValue {
					self.transformed["HD"] = false
				}
				
				episodes.append(episode.transformed)
			}
			
			// Append seasons and next episode info
			if episodes.count > 0 {
				self.transformed["episodes"] = episodes
                
                var firstUnwatchedEpisode:JSON?
                var episode : [String: AnyObject] = [:]
                
                for ep in episodes {
                    if ep["watched"] as! Bool == true {
                        continue
                    }
                    
                    firstUnwatchedEpisode = JSON(ep)
                    
                    
                    break;
                }
                
                if firstUnwatchedEpisode == nil {
                    firstUnwatchedEpisode = JSON(episodes[0])
                }
                
                episode["index"] = firstUnwatchedEpisode!["index"].stringValue
                episode["path"] = firstUnwatchedEpisode!["path"].stringValue
                episode["description"] = "Episode \(firstUnwatchedEpisode!["index"].stringValue)"
                
                self.transformed["nextEpisode"] = episode
			}
		}
		
    }
	
	override func fetch(completion: (JSON) -> Void) {
		print("Fetching season: \(self.key!)")
		self.__GET(getPmsUrl("", pmsId: self.pmsId!, pmsPath: self.key!),
		           success: { json in
					let done = {
						self.transform(json["_children"][0])
						
						completion(JSON(self.transformed))
					}
					
					if json["_children"][0]["key"].string != nil {
						// Fetch children
						self.__GET(getPmsUrl("", pmsId: self.pmsId!, pmsPath: json["_children"][0]["key"].stringValue),
							success: { json in
								self.children = json
								done()
							}
						)
					} else {
						done()
					}
					
			}
		)
	}
}