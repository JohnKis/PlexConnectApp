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
	func getView(view: String, id: String, path: String, useMustache: Bool, completion: JSValue) -> Void
    
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
}



class cJsInterface: NSObject, jsInterfaceProtocol {
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
    
    // Mustache
	// TODO: Exception handling
    func getView(view: String, id: String, path: String, useMustache: Bool, completion: JSValue) -> Void {
		var tvmlTemplate = "",
			headers = ["Accept": "application/json"],
			completionWrapper = JSContext.currentContext().objectForKeyedSubscript("setTimeout")
		
		let templateStr = readTVMLTemplate(view, theme: settings.getSetting("theme"))
		
		Alamofire.request(.GET, getPmsUrl("", pmsId: id, pmsPath: path), headers: headers)
			.responseJSON { response in
				if let json = response.result.value {
					var jsonArray = JSON(json)

                    // TODO: Optimise this
					for (key,value) in jsonArray {
						if key == "thumb" {
							jsonArray[key].string = getPmsUrl("", pmsId: id, pmsPath: value.string!)
						}
						
						if key == "_children" {
							print(jsonArray[key])
                            for (index,child) in jsonArray[key].array!.enumerate() {
                                for (childkey, childvalue):(String, JSON) in child {
                                    if childkey == "thumb" {
                                        jsonArray[key][index][childkey].string = getPmsUrl("", pmsId: id, pmsPath: childvalue.string!)
                                    }
                                }
							}
						}
					}
					
					do {
						let template = try Template(string: templateStr);
						tvmlTemplate = try template.render(Box(jsonArray.object as? NSObject))
					} catch _ {
						print("Mustache parse error")
					}
					
					completionWrapper.callWithArguments([completion, 0, tvmlTemplate])
				}
			}
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
}
