//
//  JSONConverter.swift
//  PlexConnectApp
//
//  Created by Janos Kis on 29/02/2016.
//  Copyright © 2016 Baa. All rights reserved.
//

import Foundation
import Mustache
import Alamofire
import SwiftyJSON

class cJSONConverter {
	var data : [JSON]? = []
    
    let usedKeys = ["title2", "theme", "thumb", "summary", "key", "_children"]
	
	func fetch(pmsId: String, pmsPath: String, completion: (JSON) -> Void) {
		let headers = ["Accept": "application/json"]
		
		Alamofire.request(.GET, getPmsUrl("", pmsId: pmsId, pmsPath: pmsPath), headers: headers)
			.responseJSON { response in
				if let json = response.result.value {
					completion(JSON(json))
				} else {
					// TODO
				}
		}
	}
	
    // TODO: This is too specific for TV Shows
    func transform(var json: JSON, pmsId: String, pmsPath: String, completion: (JSON) -> Void){
		// TODO: Optimise this
        var transformed : [String: AnyObject] = [:]
        var seasons : [AnyObject] = []
        var parent : JSON?

        // Set up completetion handler
        let done = {
            for (key,value) in json {
                
                if self.usedKeys.indexOf(key) == nil{
                    continue
                }
                
                switch key {
                case "thumb":
                    transformed[key] = getPmsUrl("", pmsId: pmsId, pmsPath: value.string!)
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
                            seasons.append(json[key][index].rawValue)
                        }
                    }
                    break
                case "title2":
                    transformed["title"] = value.string
                    break
                default:
                    transformed[key] = value.rawValue
                }
            }
            
            if seasons.count > 0 {
                transformed["seasons"] = seasons
            }
            
            if parent != nil {
                transformed["parent"] = parent?.rawValue
            }
            
            print("Transformed: \(transformed)")
            
            completion(JSON(transformed))
        }

        
        if json["key"].string != nil {
            // TODO: Caching
            self.fetch(pmsId, pmsPath: pmsPath.stringByReplacingOccurrencesOfString("/children", withString: ""), completion: { json in
                parent = json
                done()
            })
        } else {
            done()
        }
	}
	
	func render(view: String, pmsId: String, pmsPath: String, completion: (String) -> Void) {
		let templateStr = readTVMLTemplate(view, theme: settings.getSetting("theme"))
		var tvmlTemplate = ""
		
		self.fetch(pmsId, pmsPath: pmsPath, completion: { json in
            self.transform(json, pmsId: pmsId, pmsPath: pmsPath, completion: { transformedJson in
                do {
                    let template = try Template(string: templateStr);
                    tvmlTemplate = try template.render(Box(transformedJson.object as? NSObject))
                } catch _ {
                    print("Mustache parse error")
                }
                
                completion(tvmlTemplate)
            })
		})
	}
}