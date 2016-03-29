//
//  Series.swift
//  PlexConnectApp
//
//  Created by Janos Kis on 16/03/2016.
//  Copyright © 2016 Baa. All rights reserved.
//

import Foundation
import SwiftyJSON

class ShowsModel: BaseModel {
    let usedKeys = ["title1", "_children"]
    var sourceJson : JSON?
    var shows : [AnyObject] = []
    
	override func _transform(var json: JSON){
        for (key,value) in json {
            // Continue if we're not interested in the key
            if self.usedKeys.indexOf(key) == nil{
                continue
            }
            
            switch key {
            case "title1":
                self.transformed["title"] = value.rawValue
                break
            default: break
            }
        }
        
        for (index,_) in json["_children"].array!.enumerate() {
            let series = ModelRegister.sharedInstance.createModel("series", path: "/library/metadata/" + json["_children"][index]["ratingKey"].stringValue, pmsId: self.pmsId!)
            
            // TODO
            series.transform(json["_children"][index])
            self.shows.append(series.transformed)
            
            if self.shows.count == json["_children"].array!.count {
                self.transformed["shows"] = self.shows
            }
        }
    }
    
}