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
    
    public static func `default`(with view : UIView) -> Environment {
        return Environment {
            if #available(iOS 11.0, *) {
                $0[DefaultKeys.SafeAreaInsets.self] = view.safeAreaInsets
            }
            
            $0[DefaultKeys.ScreenScale.self] = view.window?.screen.scale ?? UIScreen.main.scale
            
            $0[DefaultKeys.CurrentLocale.self] = Locale.current
            
            $0[DefaultKeys.TraitCollection.self] = view.traitCollection
        }
    }

    internal init(_ configure : (inout Environment) -> () = { _ in}) {
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
}

public extension Environment {
    enum DefaultKeys {
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
    
    public var safeAreaInsets : UIEdgeInsets {
        return self[DefaultKeys.SafeAreaInsets.self]
    }
    
    public var screenScale : CGFloat {
        return self[DefaultKeys.ScreenScale.self]
    }
    
    public var locale : Locale {
        return self[DefaultKeys.CurrentLocale.self]
    }
    
    public var traitCollection : UITraitCollection {
        return self[DefaultKeys.TraitCollection.self]
    }
}


fileprivate extension Environment {
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
