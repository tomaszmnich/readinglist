//
//  Observables.swift
//  books
//
//  Created by Andrew Bennet on 15/04/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import RxSwift

enum Result<Value> {
    case success(Value)
    case failure(Error)
    
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    var value: Value? {
        switch self {
        case let .success(value):
            return value
        case .failure:
            return nil
        }
    }
    
    var error: Error? {
        switch self {
        case let .failure(error):
            return error
        case .success:
            return nil
        }
    }
    
    func toOptional() -> Result<Value?> {
        switch self {
        case let .success(value):
            return Result<Value?>.success(value)
        case let .failure(error):
            return Result<Value?>.failure(error)
        }
    }
}

extension Observable {
    static func createFrom<E>(dataTaskCreator: @escaping (@escaping (E) -> Void) -> URLSessionDataTask) -> Observable<E> {
        return Observable<E>.create { observer -> Disposable in
            let dataTask = dataTaskCreator { result in
                observer.onNext(result)
                observer.onCompleted()
            }
            return Disposables.create {
                dataTask.cancel()
            }
        }
    }
}
