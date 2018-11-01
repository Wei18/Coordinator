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

typealias Completion = (() -> Void)?
fileprivate extension Reactive where Base: UINavigationController{
    func push(_ vc: UIViewController, animated: Bool = true) -> Observable<Void>{
        base.pushViewController(vc, animated: animated)
        return vc.rx.deallocated
    }
    
    func present(_ vc: UIViewController, animated: Bool = true, completion: Completion) -> Observable<Void>{
        base.present(vc, animated: animated, completion: completion)
        return vc.rx.deallocated
    }
}

private protocol Coordinator{
    var id: UUID { get }
    var childCoordinators: [UUID: Coordinator] { get }
    func store(_ coordinator: Coordinator)
    func free(_ coordinator: Coordinator)
}

fileprivate protocol CoordinatorOutput{
    associatedtype ResultType
    func start() -> Observable<ResultType>
    func push(_ vc: UIViewController, animated: Bool) -> Observable<ResultType>
    func present(_ vc: UIViewController, animated: Bool, completion: Completion) -> Observable<ResultType>
}

fileprivate protocol CoordinatorInput{
    associatedtype BindType
    var binder: Observable<BindType>! { get set }
}


class BinderCoordinator<Bind, Result>: ResultCoordinator<Result>, CoordinatorInput{
    var binder: Observable<Bind>!
}

class ResultCoordinator<Base>: Coordinator, CoordinatorOutput {
    
    private(set) var parentNavController: UINavigationController!
    
    let disposeBag = DisposeBag()
    
    fileprivate lazy var id = UUID()
    
    fileprivate var childCoordinators: [UUID: Coordinator] = [:]
    
    init(root: UINavigationController){
        parentNavController = root
    }
    
    init(){}
    
    func coordinate<T>(to coordinator: ResultCoordinator<T>) -> Observable<T>{
        coordinator.parentNavController = parentNavController
        store(coordinator)
        return coordinator.start()
            .debug("\(#function) \(coordinator)")
            .do(onDispose: { [unowned self] in
                self.free(coordinator)
            })
    }
    
    func start() -> Observable<Base>{
        fatalError("\(#function) must be implemented.")
    }
    
    func push(_ vc: UIViewController, animated: Bool = true) -> Observable<Base>{
        let cancel = parentNavController.rx.push(vc, animated: animated)
        return cancel.flatMap{ _ in Observable.empty() }
    }
    
    func present(_ vc: UIViewController, animated: Bool = true, completion: Completion) -> Observable<Base>{
        let cancel = parentNavController.rx.present(vc, animated: animated, completion: completion)
        return cancel.flatMap{ _ in Observable.empty() }
    }
    
    fileprivate func store(_ coordinator: Coordinator){
        childCoordinators[coordinator.id] = coordinator
    }
    
    fileprivate func free(_ coordinator: Coordinator){
        childCoordinators[coordinator.id] = nil
    }
}
