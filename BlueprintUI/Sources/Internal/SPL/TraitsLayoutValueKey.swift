import Foundation


enum TraitsLayoutValueKey<LayoutType: Layout>: LayoutValueKey {

    static var defaultValue: LayoutType.Traits {
        LayoutType.defaultTraits
    }
}
