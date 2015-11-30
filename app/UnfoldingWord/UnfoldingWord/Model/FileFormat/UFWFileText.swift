//
//  UFWFileText
//  UnfoldingWord
//
//  Created by David Solberg on 6/15/15.
//

import UIKit

@objc final class UFWFileText : NSObject {

    let sourceDictionary: NSDictionary
    let isValid : Bool
    
    /// Returns the data containing the JSON string that represents all the data needed to create
    var fileData : NSData? {
        get {
            guard isValid, let data = try? NSJSONSerialization.dataWithJSONObject(sourceDictionary, options: []) else {
                assertionFailure("Could not create gzipped data from dictionary \(sourceDictionary)")
                return nil
            }
            return data
        }
    }
    
    /// Returns the top level object used to populate the database with the enclosed file
    var topLevelObject : NSDictionary {
        get {
            if let dictionary = self.sourceDictionary[Constants.FileFormat.TopLevel] as? NSDictionary {
                return dictionary;
            }
            assertionFailure("Could not create dictionary for key \(Constants.FileFormat.TopLevel) from \(self.sourceDictionary)")
            return NSDictionary()
        }
    }
    
    /// Returns a source item to populate each toc item with content and signature json
    func sourceItemForUrl(url: NSString) -> UrlSourceItem? {
        if let
            sources = self.sourceDictionary[Constants.FileFormat.SourcesArray] as? NSDictionary,
            sourceContent = sources.valueForKey(url as String) as? NSString
            {
                return UrlSourceItem(url: url, content: sourceContent)
            }
        else {
            assertionFailure("Could not create sources for url \(url)")
            return nil
        }
    }
    
    init(sourceDictionary : NSDictionary) {
        self.isValid = UFWFileText.validateSource(sourceDictionary)
        self.sourceDictionary = sourceDictionary
    }
    
    init?(fileData : NSData) {
        
        guard
            let dictionary = try? NSJSONSerialization.JSONObjectWithData(fileData, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary,
            let source = dictionary
            else {
                // Why initialize this stuff to return nil? Because of a bug in Swift as of Nov 20, 2015
                self.sourceDictionary = NSDictionary()
                self.isValid = false
                super.init()
                return nil
        }
        self.sourceDictionary = source
        self.isValid = true
        super.init()

    }
    
    class func validateSource(source : NSDictionary?) -> Bool {
        
        guard let
            source = source,
            _ = source[Constants.FileFormat.TopLevel] as? NSDictionary,
            _ = source[Constants.FileFormat.SourcesArray] as? NSDictionary
            else
        {
            assertionFailure("At least one object was missing from the source.")
            return false
        }
        return true
    }
}