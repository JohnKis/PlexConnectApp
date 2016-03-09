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
    let usedKeys = ["title2", "theme", "thumb", "summary", "key", "_children"]
    
    override func transform(var json: JSON, pmsId: String, pmsPath: String, completion: (JSON) -> Void){
        // TODO: Optimise this
//        var transformed : [String: AnyObject] = [:]
        var seasons : [AnyObject] = []
        var cast : [AnyObject] = []
        var parent : JSON?
        
        // Set up completetion handler
        let done = {
            for (key,value) in json {
                
                if self.usedKeys.indexOf(key) == nil{
                    continue
                }
                
                switch key {
                case "thumb":
                    self.transformed[key] = getPmsUrl("", pmsId: pmsId, pmsPath: value.string!)
                    break
                case "_children":
                    for (index,child) in json[key].array!.enumerate() {
                        for (childkey, childvalue):(String, JSON) in child {
                            if childkey == "key" && json[key][index][childkey].string!.containsString("allLeaves"){
                                continue
                            }
                            
                            if childkey == "thumb" {
                                json[key][index][childkey].string = getPmsUrl("", pmsId: pmsId, pmsPath: childvalue.string!)
                            }
                        }
                        
                        if !json[key][index]["key"].string!.containsString("allLeaves"){
                            if json[key][index]["leafCount"].int != nil &&  json[key][index]["viewedLeafCount"].int != nil {
                                json[key][index]["watched"].bool = json[key][index]["leafCount"].int! == json[key][index]["viewedLeafCount"].int!
                                
                                json[key][index]["unwatchedCount"].int = json[key][index]["leafCount"].int! - json[key][index]["viewedLeafCount"].int!
                                
                                if json[key][index]["unwatchedCount"].int > 99 {
                                    json[key][index]["unwatchedCount"].string = "99+"
                                }
                            }
                            seasons.append(json[key][index].rawValue)
                        }
                    }
                    break
                case "title2":
                    self.transformed["title"] = value.string
                    break
                default:
                    self.transformed[key] = value.rawValue
                }
            }
            
            
            if parent != nil {
                if let elements = parent!["_children"][0]["_children"].array {
                    for item in elements {
                        if item["_elementType"].string == "Genre" {
                            self.transformed["genre"] = item["tag"].string
                        }
                        
                        if item["_elementType"].string != "Role" {
                            continue
                        }
                        
                        if cast.count > 4 {
                            continue
                        }
                        
                        cast.append(item.rawValue)
                    }
                }
                
                self.transformed["year"] = parent!["_children"][0]["year"].int
                
                self.transformed["studio"] = parent!["_children"][0]["studio"].string
                
                if parent!["_children"][0]["contentRating"].string != nil {
                    self.transformed["contentRating"] = parent!["_children"][0]["contentRating"].string!.lowercaseString
                }
                
                if parent!["_children"][0]["leafCount"].int != nil &&  parent!["_children"][0]["viewedLeafCount"].int != nil {
                    self.transformed["watched"] = parent!["_children"][0]["leafCount"].int == parent!["_children"][0]["viewedLeafCount"].int
                }
            }
            
            // Append seasons and next episode info
            if seasons.count > 0 {
                self.transformed["seasons"] = seasons
            }
            
            // Append cast
            if cast.count > 0 {
                self.transformed["cast"] = cast
            }
            
            // Append helpers
            self.transformed["_"] = self.globalHelpers()
            
            self.getNextUnwatchedEpisode({ episode in
                self.transformed["nextEpisode"] = episode
                
                completion(JSON(self.transformed))
            })
        }
        
        
        if json["key"].string != nil {
            // TODO: Caching
            // Fetch parent
            self.__GET(getPmsUrl("", pmsId: pmsId, pmsPath: pmsPath.stringByReplacingOccurrencesOfString("/children", withString: "")),
                success: { json in
                    parent = json
                    done()
                }
            )
        } else {
            done()
        }
    }
    
    func getNextUnwatchedEpisode(completion: ([String: AnyObject]) -> Void){
        var episode : [String: AnyObject] = [:]
        var firstUnwatchedSeason : JSON?
        
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
        
        if firstUnwatchedSeason != nil {
            self.__GET(getPmsUrl("", pmsId: self.pmsId!, pmsPath: firstUnwatchedSeason!["key"].stringValue), success: { json in
                
                for ep in json["_children"].array! {
                    if ep["viewCount"] == nil {
                        continue
                    }
                    
                    episode["key"] = ep["key"].stringValue
                    episode["description"] = "\(firstUnwatchedSeason!["index"].stringValue)x\(ep["index"].stringValue)"
                    
                    break;
                }
                // TODO: Find first unwatched
                
                completion(episode)
            })
        }
    }
}