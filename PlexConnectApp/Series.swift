//
//  Series.swift
//  PlexConnectApp
//
//  Created by Janos Kis on 08/03/2016.
//  Copyright © 2016 Baa. All rights reserved.
//

import Foundation
import SwiftyJSON

class SeriesModel: BaseModel {
    let usedKeys = ["title", "contentRating", "thumb", "summary", "key", "ratingKey", "studio", "year", "art", "_children"]
    
	override func _transform(var json: JSON){
        // TODO: Optimise this
        var seasons : [AnyObject] = []
        var cast : [AnyObject] = []
        
        for (key,value) in json {
            // Continue if we're not interested in the key
            if self.usedKeys.indexOf(key) == nil{
                continue
            }
            
            switch key {
            case "key":
                self.transformed["childPath"] = value.stringValue
                break
            case "ratingKey":
                self.transformed["id"] = value.stringValue
                self.transformed["path"] = "/library/metadata/" + value.stringValue
                break
            case "contentRating":
                self.transformed["contentRating"] = value.stringValue.lowercaseString
                break
            case "thumb":
                self.transformed[key] = self.getThumbUrls(value.stringValue)
                break
			case "art":
				self.transformed[key] = getPmsUrl("", pmsId: self.pmsId!, pmsPath: value.stringValue)
				break;
            case "_children":
                if let elements = value.array {
                    for item in elements {
                        if item["_elementType"].string == "Genre" {
                            self.transformed["genre"] = item["tag"].string
                        }
                        
                        if item["_elementType"].string != "Role" {
                            continue
                        }
                        
                        if cast.count > 7 {
                            continue
                        }
                        
                        cast.append(item.rawValue)
                    }
                }
                break
            default:
                self.transformed[key] = value.rawValue
            }
        }
        
        if json["leafCount"].int != nil &&  json["viewedLeafCount"].int != nil {
            self.transformed["watched"] = json["leafCount"].int == json["viewedLeafCount"].int
            
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
		
        // Append cast
        if cast.count > 0 {
            self.transformed["cast"] = cast
        }
		
        if self.children != nil {
            for (index,_) in self.children!["_children"].array!.enumerate() {
                let season = ModelRegister.sharedInstance.createModel("season", path: "/library/metadata/" + self.children!["_children"][index]["ratingKey"].stringValue, pmsId: self.pmsId!)
				
				self.children!["_children"][index]["parentTitle"].string = self.transformed["title"] as? String
				self.children!["_children"][index]["parentGenre"].string = self.transformed["genre"] as? String
				
                // TODO
                season.transform(self.children!["_children"][index])
                seasons.append(season.transformed)
            }
            
            // Append seasons and next episode info
            if seasons.count > 0 {
                self.transformed["seasons"] = seasons
            }
        }
        
        
        //print("Series: \(self.transformed)")
    }
	
    override func fetch(completion: (JSON) -> Void) {
        self.__GET(getPmsUrl("", pmsId: self.pmsId!, pmsPath: self.key!),
            success: { json in
                let done = {
                    self.transform(json["_children"][0])
                    
                    self.getNextUnwatchedEpisode({ episode in
                        self.transformed["nextEpisode"] = episode
                        
                        completion(JSON(self.transformed))
                    })
                }
                
                if json["_children"][0]["key"].string != nil {
                    // Fetch children
                    self.__GET(getPmsUrl("", pmsId: self.pmsId!, pmsPath: json["_children"][0]["key"].stringValue + "?excludeAllLeaves=1"),
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
    
	// TODO: Not working if all episodes are unwatched
    func getNextUnwatchedEpisode(completion: ([String: AnyObject]) -> Void){
        var episode : [String: AnyObject] = [:]
        var firstUnwatchedSeason : JSON?
        var firstUnwatchedEpisode: JSON?
        
        if self.pmsId == nil || self.key == nil {
            // TODO: throw exception
            return
        }
        
        let seasons = self.transformed["seasons"] as! Array<AnyObject>
        
        for season in seasons {
            if season["watched"] as! Bool == true {
                continue
            }
            
            firstUnwatchedSeason = JSON(season)
            
            break
        }
        
        if firstUnwatchedSeason == nil {
            firstUnwatchedSeason = JSON(seasons[0])
        }
        
        if firstUnwatchedSeason != nil {
            self.__GET(getPmsUrl("", pmsId: self.pmsId!, pmsPath: firstUnwatchedSeason!["childPath"].stringValue), success: { json in
                
                for ep in json["_children"].array! {
                    if ep["viewCount"] != nil {
                        continue
                    }
					
                    firstUnwatchedEpisode = ep
                    
                    
                    break;
                }
                
                if firstUnwatchedEpisode == nil {
                    firstUnwatchedEpisode = json["_children"].array![0]
                }
                
                let episodeNumber : String = firstUnwatchedEpisode!["index"].intValue < 10 ? "0\(firstUnwatchedEpisode!["index"].stringValue)" : firstUnwatchedEpisode!["index"].stringValue
                
                episode["key"] = firstUnwatchedEpisode!["key"].stringValue
                episode["description"] = "\(firstUnwatchedSeason!["index"].stringValue)x\(episodeNumber)"

                
                completion(episode)
            })
        }
    }
}