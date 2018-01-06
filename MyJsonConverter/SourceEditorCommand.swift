//
//  SourceEditorCommand.swift
//  MyJsonConverter
//
//  Created by Innotical  Solutions  on 06/01/18.
//  Copyright © 2018 Innotical  Solutions . All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        
        print(invocation.commandIdentifier)
        print(invocation.buffer)
        let buffer = invocation.buffer
        print(buffer.selections.count)
        let range = buffer.selections.firstObject as! XCSourceTextRange
        print(range)
        let dateFrrmater = DateFormatter.init()
        dateFrrmater.dateStyle = .medium
        var jsonString = ""
        let myDeclaration = "//\n/*====Created by MyJSONConvertor  on \(dateFrrmater.string(from: Date()))====*/\n //Developed by Irshad Ahmed(👨🏼‍💻).\n//Contact Email:- ahmedirshad281@gmail.com\n//\n\nimport Foundation\nimport SwiftyJSON\n"
        var convertedString = "\(myDeclaration)\n\nclass MyFile:JSONDecodable{\n"
        var initilizerString = "required init(json: JSON) {\n"
        
        var otherObjectsArray:[String] = []
        for index in range.start.line...range.end.line {
            jsonString += buffer.lines[index] as! String
        }
        print(jsonString)
        if let dataString = jsonString.data(using: .utf8) {
            guard let dictionaryRepresentation = try? JSONSerialization.jsonObject(with: dataString, options: []) as? Dictionary<String, Any> else {print("Dict is Nil"); return}
            for (key,value) in dictionaryRepresentation! {
                if ((value as? Dictionary<String, Any>) != nil) {
                    let model = converDictionaryToModel(name: key, dict: value as! Dictionary<String, Any>)
                    otherObjectsArray.append(model)
                    convertedString.append("\tvar \(key):\(key.capitalized)?\n")
                    initilizerString.append("\t\(key) = \(key.capitalized).init(json:json[\"\(key)\"])\n")
                }else if ((value as? [Any]) != nil) {
                    let arrayObject = value as! [Any]
                    if arrayObject.count > 0 {
                        if let dictObject = arrayObject[0] as?  Dictionary<String,Any>{
                            let model = converDictionaryToModel(name: key, dict:dictObject)
                            otherObjectsArray.append(model)
                            convertedString.append("\tvar \(key):[\(key.capitalized)]?\n")
                            initilizerString.append("\t\(key) = json[\"\(key)\"].array?.decode()\n")
                        }
                    }
                }else if ((value as? String) != nil) {
                  
                    convertedString.append("\tvar \(key):String?\n")
                    initilizerString.append("\t\(key) = json[\"\(key)\"].stringValue\n")
                }else if ((value as? Int) != nil) {
                   
                    convertedString.append("\tvar \(key):Int?\n")
                    initilizerString.append("\t\(key) = json[\"\(key)\"].intValue\n")
                }else if ((value as? Bool) != nil) {
                    
                    convertedString.append("\tvar \(key):Bool?\n")
                    initilizerString.append("\t\(key) = json[\"\(key)\"].boolValue\n")
                }
            }
            initilizerString.append("\n\t}")
            convertedString.append("\n\(initilizerString)")
            convertedString.append("\n}")
            
            if otherObjectsArray.count > 0 {
                convertedString.append("\n\n")
                for str in otherObjectsArray {
                   convertedString.append(str)
                }
            }
            print(convertedString)
            buffer.lines.removeAllObjects()
            buffer.lines.insert(convertedString, at: 0)
        }else{
            print("Not Called")
        }
        
        //saveFile()
        completionHandler(nil)
        
    }
    
    
    
    func converDictionaryToModel(name:String,dict:Dictionary<String,Any>) ->String{
        var classString = "\n\nclass \(name.capitalized):JSONDecodable{\n"
        var initilizerString = "required init(json: JSON) {\n"
        var otherObjectsArray:[String] = []
        
        for (key,value) in dict {
            if ((value as? Dictionary<String, Any>) != nil) {
                let model = converDictionaryToModel(name: key, dict: value as! Dictionary<String, Any>)
                otherObjectsArray.append(model)
                classString.append("\tvar \(key):\(key.capitalized)?\n")
                initilizerString.append("\t\(key) = \(key.capitalized).init(json:json[\"\(key)\"])\n")
            }else if ((value as? [Any]) != nil) {
                let arrayObject = value as! [Any]
                if arrayObject.count > 0 {
                    if let dictObject = arrayObject[0] as?  Dictionary<String,Any>{
                        let model = converDictionaryToModel(name: key, dict:dictObject)
                        otherObjectsArray.append(model)
                        classString.append("\tvar \(key):[\(key.capitalized)]?\n")
                        initilizerString.append("\t\(key) = json[\"\(key)\"].array?.decode()\n")
                    }
                }
            }else if ((value as? String) != nil) {
                classString.append("\tvar \(key):String?\n")
                initilizerString.append("\t\(key) = json[\"\(key)\"].stringValue\n")
            }else if ((value as? Int) != nil) {
                classString.append("\tvar \(key):Int?\n")
                initilizerString.append("\t\(key) = json[\"\(key)\"].intValue\n")
            }else if ((value as? Bool) != nil) {
                classString.append("\tvar \(key):Bool?\n")
                initilizerString.append("\t\(key) = json[\"\(key)\"].boolValue\n")
            }
        }
        initilizerString.append("\n\t}")
        classString.append("\n\(initilizerString)")
        classString.append("\n}")
        if otherObjectsArray.count > 0 {
            classString.append("\n\n")
            for str in otherObjectsArray {
                classString.append(str)
            }
        }
        print(classString)
        return classString
    }
}
