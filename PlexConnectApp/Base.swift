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
import CoreMedia

public class BaseModel {
    var key : String?
    var pmsId : String?
    var transformed : [String: AnyObject] = [:]
    var children : JSON?
    
    init(key: String, pmsId: String){
        if key == "" {
            // TODO: Throw exception
        }
        
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
    
    func fetch(completion: (JSON) -> Void) {
        self.__GET(getPmsUrl("", pmsId: self.pmsId!, pmsPath: self.key!),
            success: { json in
                self.transform(json)
                completion(JSON(self.transformed))
            }
        )
    }
    
    func globalHelpers() -> [String: AnyObject] {
        var helpers : [String: AnyObject] = [:]
        
        helpers["imagePath"] = NSBundle.mainBundle().bundleURL.absoluteString + "Images"
        helpers["pmsId"] = self.pmsId
        
        return helpers
    }
    
    func getThumbUrls(thumb: String) -> [String: AnyObject] {
        var thumbs : [String: AnyObject] = [:]
        
        let thumb = getPmsUrl("", pmsId: self.pmsId!, pmsPath: thumb)
        
        let escaped = thumb.stringByAddingPercentEncodingWithAllowedCharacters(.alphanumericCharacterSet())!
        
        thumbs["300"] = getPmsUrl("", pmsId: self.pmsId!, pmsPath: "/photo/:/transcode?url=\(escaped)&width=300&height=300")
		thumbs["445"] = getPmsUrl("", pmsId: self.pmsId!, pmsPath: "/photo/:/transcode?url=\(escaped)&width=445&height=445")
        thumbs["768"] = getPmsUrl("", pmsId: self.pmsId!, pmsPath: "/photo/:/transcode?url=\(escaped)&width=768&height=768")
		thumbs["video"] = getPmsUrl("", pmsId: self.pmsId!, pmsPath: "/photo/:/transcode?url=\(escaped)&width=308&height=173")
        thumbs["original"] = thumb
        
        return thumbs
    }
	
	func getDurationFromTimestamp(timestamp: Int) -> Dictionary<String, Int>{
		let seconds = timestamp / 1000
		var duration = [String: Int]()
		
		duration["hours"] = (seconds / 3600)
		duration["minutes"] = (seconds % 3600) / 60
		
		return duration
	}
	
    // TODO: Error callback
    func __GET(url: String, success: (JSON) -> Void){
        let headers = ["Accept": "application/json"]
        
        Alamofire.request(.GET, url, headers: headers)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    if let json = response.result.value {
                        success(JSON(json))
                    } else {
                        // TODO
                    }
                case .Failure(let error):
                    // TODO
                    print(error)
                }
            }
    }
    
    func __PUT(url: String, success: () -> Void){
        let headers = ["Accept": "application/json"]
        
        Alamofire.request(.PUT, url, headers: headers)
            .responseString { response in
                switch response.result {
                case .Success:
                    if let _ = response.result.value {
                        success()
                    } else {
                        // TODO
                    }
                case .Failure(let error):
                    // TODO
                    print(error)
                }
            }
    }
    
    func setWatchedStatus(watched: Bool, completion: () -> Void){
        var path = ""
        
        if watched {
            path = "/:/scrobble?key=\(self.transformed["id"]!)&identifier=com.plexapp.plugins.library"
        } else {
            path = "/:/unscrobble?key=\(self.transformed["id"]!)&identifier=com.plexapp.plugins.library"
        }
        
        self.__PUT(getPmsUrl("", pmsId: self.pmsId!, pmsPath: path), success: { _ in
            completion()
        })
    }

    func transform(json: JSON){
        self._transform(json)
		
		self.transformed["_"] = self.globalHelpers()
    }
	
	func _transform(json: JSON){
		
	}
}
