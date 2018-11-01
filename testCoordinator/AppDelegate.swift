//
//  AppDelegate.swift
//  testCoordinator
//
//  Created by ZhiWei Cao on 10/31/18.
//  Copyright © 2018 ZhiWei Cao. All rights reserved.
//

import UIKit
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    lazy var appCoor = AppCoordinator()
    
    private let disposeBag = DisposeBag()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        appCoor.start()
            .subscribe()
            .disposed(by: disposeBag)
        
        return true
    }
}

class AppCoordinator: ResultCoordinator<Void>{
    
    private var window: UIWindow!
    
    override convenience init(){
        let nav = UINavigationController()
        self.init(root: nav)
        window = UIWindow()
        window.rootViewController = nav
        window.makeKeyAndVisible()
    }
    
    override func start() -> Observable<Void> {
        #warning("for test, parentNavController.pushViewController")
        parentNavController.pushViewController(UIViewController(), animated: true)
        let coor = ACoordinator()
        return coordinate(to: coor).map{ _ in () }
    }
}

class ACoordinator: ResultCoordinator<Bool>{
    override func start() -> Observable<Bool> {
        let vc = ViewController()
        let selected = Observable<Int>.interval(5.0, scheduler: MainScheduler.instance)
            .take(1)
            .map{ _ -> BCoordinator in
                let coor = BCoordinator()
                coor.binder = Observable.of(true)
                return coor
            }
            .flatMap{ [weak self] coor in
                return self?.coordinate(to: coor) ?? .empty()
            }
        return Observable.amb([push(vc), selected])
    }
}

class BCoordinator: BinderCoordinator<Bool, Bool>{
    override func start() -> Observable<Bool> {
        let vc = ViewController()
        return Observable.amb([push(vc), binder ?? .empty()])
    }
}
