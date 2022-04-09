import Foundation

/// Gets the address of a reference type as a string, for debugging purposes.
func address(of object: AnyObject) -> String {
    "\(Unmanaged.passUnretained(object).toOpaque())"
}
