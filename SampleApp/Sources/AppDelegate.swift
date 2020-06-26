import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        
        if #available(iOS 13.4, *) {
            window?.rootViewController = PointerInteractionViewController()
        }
        window?.makeKeyAndVisible()

        return true
    }

}

