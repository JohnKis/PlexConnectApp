//
//  Base.swift
//  PlexConnectApp
//
//  Created by Janos Kis on 08/03/2016.
//  Copyright © 2016 Baa. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class BaseModel {
    var key : String?
    var pmsId : String?
    var transformed : [String: AnyObject] = [:]
    
    func setKey(key: String, pmsId: String){
        if key == "" {
            // TODO: Throw exception
            
            return
        }
        
        if pmsId == "" {
            // TODO: Throw exception
            
            return
        }
        
        self.key = key
        self.pmsId = pmsId
    }
    
    func fetch(pmsId: String, pmsPath: String, completion: (JSON) -> Void) {
        self.__GET(getPmsUrl("", pmsId: pmsId, pmsPath: pmsPath),
            success: { json in
                self.transform(json, pmsId: pmsId, pmsPath: pmsPath, completion: { transformedJSON in
                    completion(transformedJSON)
                })
            }
        )
    }
    
    func globalHelpers() -> [String: AnyObject] {
        var helpers : [String: AnyObject] = [:]
        
        helpers["imagePath"] = NSBundle.mainBundle().bundleURL.absoluteString + "Images"
        helpers["pmsId"] = pmsId
        
        return helpers
    }
    
    // TODO: Error callback
    func __GET(url: String, success: (JSON) -> Void){
        let headers = ["Accept": "application/json"]
        
        Alamofire.request(.GET, url, headers: headers)
            .responseJSON { response in
                if let json = response.result.value {
                    success(JSON(json))
                } else {
                    // TODO
                }
            }
    }
    
    func transform(json: JSON, pmsId: String, pmsPath: String, completion: (JSON) -> Void){
        
    }
}
