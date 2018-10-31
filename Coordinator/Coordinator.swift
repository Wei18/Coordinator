//
//  Coordinator.swift
//  Coordinator
//
//  Created by ZhiWei Cao on 10/31/18.
//  Copyright © 2018 ZhiWei Cao. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

private protocol Coordinator{
    var id: UUID { get }
    var childCoordinators: [UUID: Coordinator] { get }
    func store(_ coordinator: Coordinator)
    func free(_ coordinator: Coordinator)
}

fileprivate protocol CoordinatorOutput{
    associatedtype ResultType
    func start() -> Observable<ResultType>
    func push(vc: UIViewController, animated: Bool) -> Observable<ResultType>
}

fileprivate protocol CoordinatorInput{
    associatedtype BindType
    var binder: Observable<BindType>! { get set }
}

public class ResultCoordinator<Base>: Coordinator, CoordinatorOutput {
    
    public private(set) var parentNavController: UINavigationController!
    
    let disposeBag = DisposeBag()
    
    fileprivate lazy var id = UUID()
    
    fileprivate var childCoordinators: [UUID: Coordinator] = [:]
    
    init(root: UINavigationController){
        print(self, #function)
        parentNavController = root
    }
    
    init(){
        print(self, #function)
    }
    
    deinit {
        print(self, #function)
    }
    
    func coordinate<T>(to coordinator: ResultCoordinator<T>) -> Observable<T>{
        print(self, #function)
        coordinator.parentNavController = parentNavController
        store(coordinator)
        return coordinator.start()
            .debug("\(self)")
            .do(onCompleted: { [unowned self] in self.free(coordinator) })
    }
    
    func start() -> Observable<Base>{
        fatalError("\(#function) must be implemented.")
    }

    func push(vc: UIViewController, animated: Bool = true) -> Observable<Base>{
        print(self, #function)
        parentNavController.pushViewController(vc, animated: animated)
        return vc.rx.deallocated.flatMap{ _ in Observable.empty() }
    }
    
    func present(vc: UIViewController, animated: Bool = true, completion: (() -> Void)?) -> Observable<Base>{
        print(self, #function)
        parentNavController.present(vc, animated: animated, completion: completion)
        return vc.rx.deallocated.flatMap{ _ in Observable.empty() }
    }
    
    fileprivate func store(_ coordinator: Coordinator){
        childCoordinators[coordinator.id] = coordinator
    }
    
    fileprivate func free(_ coordinator: Coordinator){
        childCoordinators[coordinator.id] = nil
    }
}

class BinderCoordinator<Bind, Result>: ResultCoordinator<Result>, CoordinatorInput{
    var binder: Observable<Bind>!
}
