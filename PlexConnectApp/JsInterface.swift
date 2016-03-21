//
//  Settigns.swift
//  PlexConnectApp
//
//  Created by Baa on 28.10.15.
//  Copyright © 2015 Baa. All rights reserved.
//

import Foundation
import TVMLKit
import Mustache
import Alamofire
import SwiftyJSON


@objc protocol jsInterfaceProtocol : JSExport {
    func log(message: String) -> Void
    
    // XMLConverter
    func getView(view: String, id: String, path: String) -> String
    
    // JSONConverter
	func getView(view: String, id: String, path: String, useMustache: Bool, completion: JSValue) -> Void
    func getView(view: String, data: JSValue) -> String
    
    // Settings
    func toggleSetting(setting: String, view: String) -> String
    func resetSetting(setting: String) -> String
    func getCustomSetting(setting: String) -> String
    func setCustomSetting(setting: String, value: String)
    
    // PlexAPI
    func discover(view: String) -> String
    func signInUser(username: String, password: String, view: String) -> String
    func signOut(view: String) -> String
    func switchHomeUserId(id: String, pin: String, view: String) -> String
    
    func sendPms(id: String, path: String) -> Void
    func setWatchedStatus(id: String, path: String, watched: Bool, completion: JSValue) -> Void
}



class cJsInterface: NSObject, jsInterfaceProtocol {
	var jsonConverter : cJSONConverter?
	
    func log(message: String) -> Void {
        print("JS: \(message)")
    }
    
    // XMLConverter
    func getView(view: String, id: String, path: String) -> String {
        let processor = cXmlConverter()  // new class instance each time? or just re-setup and run?
        processor.setup(view, pmsId: id, pmsPath: path, query: [:])
        
        let TVMLTemplate = processor.doIt()
        return TVMLTemplate
    }
    
    // JSONConverter
    func getView(view: String, id: String, path: String, useMustache: Bool, completion: JSValue) -> Void {
		let completionWrapper = JSContext.currentContext().objectForKeyedSubscript("setTimeout")
		
		if self.jsonConverter == nil {
			self.jsonConverter = cJSONConverter()
		}
		
		self.jsonConverter!.render(view, pmsId: id, pmsPath: path, completion: { template in
			completionWrapper.callWithArguments([completion, 0, template])
		})
	}
    
    func getView(view: String, data: JSValue) -> String {
        if self.jsonConverter == nil {
            self.jsonConverter = cJSONConverter()
        }
        
        return self.jsonConverter!.render(view, data: data.toObject())
    }
	
    // Settings
    func toggleSetting(setting: String, view: String) -> String {
        settings.toggleSetting(setting)
        
        return getView(view, id: "", path: "")
    }
    func resetSetting(setting: String) -> String {
        settings.setSetting(setting, ix: 0)
        
        return settings.getSetting(setting)
    }
    func getCustomSetting(setting: String) -> String {
        let value = settings.getCustomString(setting)
        
        return value
    }
    func setCustomSetting(setting: String, value: String) {
        settings.setCustomString(setting, value: value)
    }
    
    // PlexAPI
    func discover(view: String) -> String {
        discoverServers()
        return getView(view, id: "", path: "")
    }
    
    func signInUser(username: String, password: String, view: String) -> String {
        myPlexSignIn(username, password: password)
        return getView(view, id: "", path: "")
    }
    
    func signOut(view: String) -> String {
        myPlexSignOut()
        return getView(view, id: "", path: "")
    }
    
    func switchHomeUserId(id: String, pin: String, view: String) -> String {
        myPlexSwitchHomeUser(id, pin: pin)
        return getView(view, id: "", path: "")
    }
    
    func sendPms(id: String, path: String) -> Void {
        let url = getPmsUrl("", pmsId: id, pmsPath: path)
        reqXML(url, fn_success: {_ in }, fn_error: {_ in })  // send notification to PMS, don't care about response
    }
    
    func setWatchedStatus(id: String, path: String, watched: Bool, completion: JSValue) {
        let completionWrapper = JSContext.currentContext().objectForKeyedSubscript("setTimeout")

        if let Model = ModelRegister.sharedInstance.getModel(path, pmsId: id){
            Model.setWatchedStatus(watched, completion: {
                completionWrapper.callWithArguments([completion, 0])
            })
        } else {
            print("Couldn't find model for id: \(id) and path: \(path)")
            // TODO: Expection
        }
    }
}
