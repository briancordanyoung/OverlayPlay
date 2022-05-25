import Foundation

public func delay(bySeconds seconds: Double, dispatchLevel: DispatchLevel = .main, closure: @escaping VoidClosure) {
    let dispatchTime = DispatchTime.now() + seconds
    dispatchLevel.dispatchQueue.asyncAfter(deadline: dispatchTime, execute: closure)
}

public func delay(bySeconds seconds: Double, dispatchLevel: DispatchLevel = .main, execute workItem: DispatchWorkItem) {
    let dispatchWallTime = DispatchWallTime.now() + seconds
    dispatchLevel.dispatchQueue.asyncAfter(wallDeadline: dispatchWallTime, execute: workItem)
}

public enum DispatchLevel {
    case main, userInteractive, userInitiated, utility, background
    public var dispatchQueue: DispatchQueue {
        switch self {
        case .main:                 return DispatchQueue.main
        case .userInteractive:      return DispatchQueue.global(qos: .userInteractive)
        case .userInitiated:        return DispatchQueue.global(qos: .userInitiated)
        case .utility:              return DispatchQueue.global(qos: .utility)
        case .background:           return DispatchQueue.global(qos: .background)
        }
    }
}
