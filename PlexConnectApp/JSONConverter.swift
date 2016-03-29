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
    func render(view: String, pmsId: String, pmsPath: String, completion: (String) -> Void) {
        let templateStr = readTVMLTemplate(view, theme: settings.getSetting("theme"))
        var Model = ModelRegister.sharedInstance.getModel(pmsPath, pmsId: pmsId)
        var tvmlTemplate = ""
        
        print(pmsPath)
        
        if Model == nil {
            Model = ModelRegister.sharedInstance.createModel(self.getModelTypeForView(view), path: pmsPath, pmsId: pmsId)
        }
        
        Model!.fetch({ json in
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
    
    func render(view: String, data: AnyObject) -> String {
        let templateStr = readTVMLTemplate(view, theme: settings.getSetting("theme"))
        var tvmlTemplate = ""
        
        do {
            let template = try Template(string: templateStr);
            template.registerInBaseContext("HTMLEscape", Box(StandardLibrary.HTMLEscape))
            tvmlTemplate = try template.render(Box(data as? NSObject))
        } catch _ {
            print("Mustache parse error")
        }
        
        return tvmlTemplate
    }
    
    func getModelTypeForView(view: String) -> String{
        var modelType = ""
        
        switch view {
        case "TVShow_ShowList":
            modelType = "shows"
            break
        case "TVShow_SeasonList":
            modelType = "series"
            break
		case "TVShow_EpisodeList":
			modelType = "season"
			break
        default:
            // TODO: Exception
            break
        }
        
        return modelType
    }
}