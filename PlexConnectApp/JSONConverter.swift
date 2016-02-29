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
	
	func fetch(pmsId: String, pmsPath: String, completion: (JSON) -> Void) {
		let headers = ["Accept": "application/json"]
		
		Alamofire.request(.GET, getPmsUrl("", pmsId: pmsId, pmsPath: pmsPath), headers: headers)
			.responseJSON { response in
				if let json = response.result.value {
					let JSONdata = self.transform(JSON(json), pmsId: pmsId)
					
					completion(JSONdata)
				} else {
					// TODO
				}
		}
	}
	
	func transform(var json: JSON, pmsId: String) -> JSON{
		// TODO: Optimise this
		for (key,value) in json {
			if key == "thumb" {
				json[key].string = getPmsUrl("", pmsId: pmsId, pmsPath: value.string!)
			}
			
			if key == "_children" {
				for (index,child) in json[key].array!.enumerate() {
					for (childkey, childvalue):(String, JSON) in child {
						if childkey == "thumb" {
							json[key][index][childkey].string = getPmsUrl("", pmsId: pmsId, pmsPath: childvalue.string!)
						}
					}
				}
			}
		}
		
		
		return json;
	}
	
	func render(view: String, pmsId: String, pmsPath: String, completion: (String) -> Void) {
		let templateStr = readTVMLTemplate(view, theme: settings.getSetting("theme"))
		var tvmlTemplate = ""
		
		self.fetch(pmsId, pmsPath: pmsPath, completion: { json in
			do {
				let template = try Template(string: templateStr);
				tvmlTemplate = try template.render(Box(json.object as? NSObject))
			} catch _ {
				print("Mustache parse error")
			}
			
			completion(tvmlTemplate)
		})
		
		
	}
}