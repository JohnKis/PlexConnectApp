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
    var aModels = [String: BaseModel]()
    
    func render(view: String, pmsId: String, pmsPath: String, completion: (String) -> Void) {
        let templateStr = readTVMLTemplate(view, theme: settings.getSetting("theme"))
        let Model = self.getModel(view)
        var tvmlTemplate = ""
        
        Model.setKey(pmsPath, pmsId: pmsId)
        
        Model.fetch(pmsId, pmsPath: pmsPath, completion: { json in
            do {
                let template = try Template(string: templateStr);
                template.registerInBaseContext("HTMLEscape", Box(StandardLibrary.HTMLEscape))
                tvmlTemplate = try template.render(Box(json.object as? NSObject))
            } catch _ {
                print("Mustache parse error")
            }
            
            completion(tvmlTemplate)
        })
    }
    
    func render(view: String, title: String, description: String) -> String {
        let templateStr = readTVMLTemplate(view, theme: settings.getSetting("theme"))
        var tvmlTemplate = ""
        
        do {
            let template = try Template(string: templateStr);
            template.registerInBaseContext("HTMLEscape", Box(StandardLibrary.HTMLEscape))
            tvmlTemplate = try template.render(Box([ "title": title, "description": description ]))
        } catch _ {
            print("Mustache parse error")
        }
        
        return tvmlTemplate
        
    }
    
    func getModel(type: String) -> BaseModel {
        if self.aModels[type] == nil {
            var Model : BaseModel?
            
            switch type {
            case "TVShow_SeasonList":
                Model = SeriesModel()
                break;
            default:
                break;
            }
            
            self.aModels[type] = Model
        }
        
        return self.aModels[type]!
    }
}