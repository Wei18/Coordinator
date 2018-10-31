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
    var stop: Observable<ResultType> { get }
}

fileprivate protocol CoordinatorInput{
    associatedtype BindType
    var binder: Observable<BindType>! { get set }
}

class ResultCoordinator<Base>: Coordinator, CoordinatorOutput {
    
    let disposeBag = DisposeBag()
    
    fileprivate lazy var id = UUID()
    
    fileprivate var childCoordinators: [UUID: Coordinator] = [:]
    
    private var parentNavigationController: UINavigationController!
    
    func coordinate<T>(to coordinator: ResultCoordinator<T>) -> Observable<T>{
        store(coordinator)
        return coordinator.start()
            .do(onCompleted: { [unowned self] in self.free(coordinator) })
    }
    
    var stop: Observable<Base> {
        let vc = parentNavigationController.visibleViewController!
        return vc.rx.deallocated.flatMap{ _ -> Observable<Base> in .empty() }
    }
    
    func start() -> Observable<Base>{
        fatalError("\(#function) must be implemented.")
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
