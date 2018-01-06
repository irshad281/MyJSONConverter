//
//  SourceEditorCommand.swift
//  MyJSON2SwiftConverter
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
        var myDeclaration = "/*====Created by JSON2SwiftConverterExtension  on \(dateFrrmater.string(from: Date()))====*/\n //Developed by Irshad Ahmed(👨🏼‍💻). Contact Email:- ahmedirshad281@gmail.com\n"
        let requirement = "\n/*==================================== Requirement ====================================\n\nIf you don't have JSONDecodable protocol method then use the below protocol...\n\npublic protocol JSONDecodable{\n\tinit(json:JSON)\n}\n\nIf you don't have decode method then use the below it..\n\nextension Collection where Iterator.Element == JSON {\n\tfunc decode<T:JSONDecodable>() -> [T] {\n\t\treturn map({T(json:$0)})\n\t}\n}\n*/"
        myDeclaration.append(requirement)
        let name = "\n\nimport Foundation\nimport SwiftyJSON\n"
        myDeclaration.append(name)
        var convertedString = "\n\nclass MyModel:JSONDecodable{\n"
        var initilizerString = "required init(json: JSON) {\n"
        var mainConvertedString = "\(myDeclaration)"
        
        var otherObjectsArray:[String] = []
        /**/
        for index in range.start.line...range.end.line {
            jsonString += buffer.lines[index] as! String
        }
        print(jsonString)
        var isFoundArray:Bool = false
        if let dataString = jsonString.data(using: .utf8) {
            var dictionaryRepresentation:Dictionary<String,Any>?
            if let dictionaryArray = try? JSONSerialization.jsonObject(with: dataString, options: []) as? [Any] {
                if dictionaryArray != nil && dictionaryArray!.count > 0 {
                    dictionaryRepresentation = dictionaryArray![0] as? Dictionary<String,Any>
                    mainConvertedString.append("\n\nclass MyArrayModel:JSONDecodable{\n")
                    var initilizer = "\trequired init(json: JSON) {\n"
                    mainConvertedString.append("\t\tvar models:[MyModel]?\n")
                    initilizer.append("\t\tmodels = json.array?.decode()\n")
                    initilizer.append("\t}")
                    mainConvertedString.append(initilizer)
                    mainConvertedString.append("\n}\n\n")
                    isFoundArray = true
                }
            }
            if isFoundArray == false {
                if let dictionary = try? JSONSerialization.jsonObject(with: dataString, options: []) as? Dictionary<String, Any> {
                    dictionaryRepresentation = dictionary
                    
                }
            }
            if dictionaryRepresentation == nil {
                completionHandler(nil)
                return
            }
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
                        }else if let _ = arrayObject[0] as? String {
                            let model = convertStringArray(name: key, stringArray: value as! [String])
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
                }else if ((value as? Double) != nil) {
                    convertedString.append("\tvar \(key):Double?\n")
                    initilizerString.append("\t\(key) = json[\"\(key)\"].doubleValue\n")
                }else if ((value as? Float) != nil) {
                    convertedString.append("\tvar \(key):Float?\n")
                    initilizerString.append("\t\(key) = json[\"\(key)\"].floatValue\n")
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
            mainConvertedString.append(convertedString)
            print(mainConvertedString)
            buffer.lines.removeAllObjects()
            buffer.lines.insert(mainConvertedString, at: 0)
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
                    }else if let _ = arrayObject[0] as? String {
                        let model = convertStringArray(name: key, stringArray: value as! [String])
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
            }else if ((value as? Double) != nil) {
                classString.append("\tvar \(key):Double?\n")
                initilizerString.append("\t\(key) = json[\"\(key)\"].doubleValue\n")
            }else if ((value as? Float) != nil) {
                classString.append("\tvar \(key):Float?\n")
                initilizerString.append("\t\(key) = json[\"\(key)\"].floatValue\n")
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
    
    func convertStringArray( name:String ,stringArray:[String]) -> String{
        var classString = "\n\nclass \(name.capitalized):JSONDecodable{\n"
        var initilizerString = "required init(json: JSON) {\n"
        classString.append("\tvar value:String?\n")
        initilizerString.append("\tvalue = json.stringValue\n")
        initilizerString.append("\n\t}")
        classString.append("\n\(initilizerString)")
        classString.append("\n}")
        print(classString)
        return classString
    }
    
}

