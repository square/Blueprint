//
//  Environment.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 3/28/20.
//

import Foundation


public protocol EnvironmentKey {
    associatedtype Value

    static var defaultValue: Self.Value { get }
}


public struct Environment {
    public static let empty = Environment()
    
    internal static func `default`(with base : Environment? = nil, in view : UIView) -> Environment {
        Environment(with: base) {
            if #available(iOS 11.0, *) {
                $0.safeAreaInsets = view.safeAreaInsets
            }
            
            $0.screenScale = view.window?.screen.scale ?? UIScreen.main.scale
            $0.locale = Locale.current
            $0.traitCollection = view.traitCollection
        }
    }
    
    public init(with base : Environment? = nil, _ configure : (inout Environment) -> () = { _ in}) {
        
        if let base = base {
            self.storage = base.storage
        }
        
        configure(&self)
    }
    
    public var values : [ObjectIdentifier:Any] {
        self.storage.values
    }
    
    private var storage : Storage = Storage(values: [:])

    public subscript<K>(key: K.Type) -> K.Value where K: EnvironmentKey {
        get {
            let objectId = ObjectIdentifier(key)

            if let value = storage.values[objectId] as? K.Value {
                return value
            }

            return key.defaultValue
        }
        set {
            if !isKnownUniquelyReferenced(&storage) {
                storage = storage.copy()
            }
            
            storage.values[ObjectIdentifier(key)] = newValue
        }
    }
    
    final class Storage {
        init(values : [ObjectIdentifier:Any]) {
            self.values = values
        }
        
        var values : [ObjectIdentifier: Any]
        
        func copy() -> Storage {
            return Storage(values: self.values)
        }
    }
}


extension Environment {
    
    public var safeAreaInsets : UIEdgeInsets {
        get {
            return self[Keys.SafeAreaInsets.self]
        }
        
        set {
            self[Keys.SafeAreaInsets.self] = newValue
        }
    }
    
    public var screenScale : CGFloat {
        get {
            return self[Keys.ScreenScale.self]
        }
        
        set {
            self[Keys.ScreenScale.self] = newValue
        }
    }
    
    public var locale : Locale {
        get {
            return self[Keys.CurrentLocale.self]
        }
        
        set {
            self[Keys.CurrentLocale.self] = newValue
        }
    }
    
    public var traitCollection : UITraitCollection {
        get {
            return self[Keys.TraitCollection.self]
        }
        
        set {
            self[Keys.TraitCollection.self] = newValue
        }
    }
    
    private enum Keys {
        struct SafeAreaInsets : EnvironmentKey {
            
            typealias Value = UIEdgeInsets
            
            static var defaultValue: Value {
                .zero
            }
        }
        
        struct ScreenScale : EnvironmentKey {
            
            typealias Value = CGFloat
            
            static var defaultValue: Value {
                1.0
            }
        }
        
        struct CurrentLocale : EnvironmentKey {
            
            typealias Value = Locale
            
            static var defaultValue: Value {
                Locale(identifier: "en-US")
            }
        }
        
        struct TraitCollection : EnvironmentKey {
            
            typealias Value = UITraitCollection
            
            static var defaultValue: Value {
                UITraitCollection()
            }
        }
    }
}
