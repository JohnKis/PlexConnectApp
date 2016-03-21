//
//  ModelRegister.swift
//  PlexConnectApp
//
//  Created by Janos Kis on 13/03/2016.
//  Copyright © 2016 Baa. All rights reserved.
//

import Foundation

public class ModelRegister {
    public static let sharedInstance = ModelRegister()
    
    var aModels = [String: BaseModel]()
    
    private init() {}
    
    public func getModel(path: String, pmsId: String) -> BaseModel? {
        return self.aModels["\(path)_\(pmsId)"]
    }
    
    public func createModel(type: String, path: String, pmsId: String) -> BaseModel {
        if self.aModels["\(path)_\(pmsId)"] == nil {
            var Model : BaseModel?
            
            switch type {
            case "shows":
                Model = ShowsModel(key: path, pmsId: pmsId)
                break;
            case "series":
                Model = SeriesModel(key: path, pmsId: pmsId)
                break;
            case "season":
                Model = SeasonModel(key: path, pmsId: pmsId)
                break;
            default:
                break;
            }
            
            self.aModels["\(path)_\(pmsId)"] = Model
        }
        
        return self.aModels["\(path)_\(pmsId)"]!
    }
}
