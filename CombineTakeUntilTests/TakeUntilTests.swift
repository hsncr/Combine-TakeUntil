//
//  TakeUntilTests.swift
//  CombineTakeUntilTests
//
//  Created by hsncr on 20.01.2021.
//

import XCTest
import Foundation
import Combine
import CombineSchedulers
@testable import CombineTakeUntil

class TakeUntilTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: Each publisher is on current scheduler
    func testTakeUntilPassthroughSubjectCompleterCaseScheduleAllOnCurrentScheduler() {

        let expectation = self.expectation(description: "Done")

        let sourcePublisher = (0...10).publisher.print("Source")
            .breakpoint { _ -> Bool in
                Swift.print("Source: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("Source: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("Source: Completion CurrentThread \(Thread.current)")
                return false
            }

        let finisher = PassthroughSubject<Void, Never>()

        let finisherPublisher = finisher.print("Finisher")
            .breakpoint { _ -> Bool in
                Swift.print("Finisher: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("Finisher: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("Finisher: Completion CurrentThread \(Thread.current)")
                return false
            }

        var received = [Subscribers.Event<Int, Never>]()

        let cancellable = Publishers.TakeUntil(upstream: sourcePublisher, until: finisherPublisher)
            .print("TakeUntil")
            .breakpoint { _ -> Bool in
                Swift.print("TakeUntil: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("TakeUntil: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("TakeUntil: Completion CurrentThread \(Thread.current)")
                return false
            }
            .sink(event: { event in
                received.append(event)
                
                if case .complete(_) = event {
                    expectation.fulfill()
                }
            })

        withExtendedLifetime(cancellable) { wait(for: [expectation], timeout: 5.0) }
        XCTAssertEqual(received, (0...10).asEvents(completion: .finished))
    }
    
    func testTakeUntilCurrentValueSubjectCompleterCaseScheduleAllOnCurrentScheduler() {

        let expectation = self.expectation(description: "Done")

        let sourcePublisher = (0...10).publisher.print("Source")
            .breakpoint { _ -> Bool in
                Swift.print("Source: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("Source: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("Source: Completion CurrentThread \(Thread.current)")
                return false
            }

        let finisher = CurrentValueSubject<Void, Never>(())

        let finisherPublisher = finisher.print("Finisher")
            .breakpoint { _ -> Bool in
                Swift.print("Finisher: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("Finisher: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("Finisher: Completion CurrentThread \(Thread.current)")
                return false
            }

        var received = [Subscribers.Event<Int, Never>]()

        let cancellable = Publishers.TakeUntil(upstream: sourcePublisher, until: finisherPublisher)
            .print("TakeUntil")
            .breakpoint { _ -> Bool in
                Swift.print("TakeUntil: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("TakeUntil: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("TakeUntil: Completion CurrentThread \(Thread.current)")
                return false
            }
            .sink(event: { event in
                received.append(event)
                
                if case .complete(_) = event {
                    expectation.fulfill()
                }
            })

        withExtendedLifetime(cancellable) { wait(for: [expectation], timeout: 5.0) }
        XCTAssertEqual(true, received.contains(.complete(.finished)))
    }
   
    // MARK: all serial queue scheduler
    func testTakeUntilCurrentValueSubjectCompleterCaseScheduleAllSerialQueue() {

        let expectation = self.expectation(description: "Done")
        
        let scheduler = DispatchQueue(label: "Serial")

        let sourcePublisher = (0...10).publisher.print("Source")
            .subscribe(on: scheduler)
            .breakpoint { _ -> Bool in
                Swift.print("Source: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("Source: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("Source: Completion CurrentThread \(Thread.current)")
                return false
            }

        let finisher = CurrentValueSubject<Void, Never>(())

        let finisherPublisher = finisher.print("Finisher")
            .subscribe(on: scheduler)
            .breakpoint { _ -> Bool in
                Swift.print("Finisher: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("Finisher: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("Finisher: Completion CurrentThread \(Thread.current)")
                return false
            }


        var received = [Subscribers.Event<Int, Never>]()

        let cancellable = Publishers.TakeUntil(upstream: sourcePublisher, until: finisherPublisher)
            .print("TakeUntil")
            .subscribe(on: scheduler)
            .breakpoint { _ -> Bool in
                Swift.print("TakeUntil: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("TakeUntil: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("TakeUntil: Completion CurrentThread \(Thread.current)")
                return false
            }
            .sink(event: { event in
                received.append(event)
                
                if case .complete(_) = event {
                    expectation.fulfill()
                }
            })

        withExtendedLifetime(cancellable) { wait(for: [expectation], timeout: 5.0) }
        XCTAssertEqual(true, received.contains(.complete(.finished)))
    }
    
    func testTakeUntilCurrentValueSubjectCompleterCaseScheduleAllSerialQueueExceptFinisher() {

        let expectation = self.expectation(description: "Done")
        
        let scheduler = DispatchQueue(label: "Serial")

        let sourcePublisher = (0...10).publisher.print("Source")
            .subscribe(on: scheduler)
            .breakpoint { _ -> Bool in
                Swift.print("Source: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("Source: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("Source: Completion CurrentThread \(Thread.current)")
                return false
            }

        let finisher = CurrentValueSubject<Void, Never>(())

        let finisherPublisher = finisher.print("Finisher")
            .breakpoint { _ -> Bool in
                Swift.print("Finisher: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("Finisher: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("Finisher: Completion CurrentThread \(Thread.current)")
                return false
            }


        var received = [Subscribers.Event<Int, Never>]()

        let cancellable = Publishers.TakeUntil(upstream: sourcePublisher, until: finisherPublisher)
            .print("TakeUntil")
            .subscribe(on: scheduler)
            .breakpoint { _ -> Bool in
                Swift.print("TakeUntil: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("TakeUntil: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("TakeUntil: Completion CurrentThread \(Thread.current)")
                return false
            }
            .sink(event: { event in
                received.append(event)
                
                if case .complete(_) = event {
                    expectation.fulfill()
                }
            })

        withExtendedLifetime(cancellable) { wait(for: [expectation], timeout: 5.0) }
        XCTAssertEqual(true, received.contains(.complete(.finished)))
    }
    
    func testTakeUntilCurrentValueSubjectCompleterCaseProblemScheduleAllOnGlobalDispatchQueue() {

        let expectation = self.expectation(description: "Done")

        let sourcePublisher = (0...10).publisher.print("Source")
            .subscribe(on: DispatchQueue.global())
            .breakpoint { _ -> Bool in
                Swift.print("Source: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("Source: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("Source: Completion CurrentThread \(Thread.current)")
                return false
            }

        let finisher = CurrentValueSubject<Void, Never>(())

        let finisherPublisher = finisher.print("Finisher")
            .subscribe(on: DispatchQueue.global())
            .breakpoint { _ -> Bool in
                Swift.print("Finisher: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("Finisher: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("Finisher: Completion CurrentThread \(Thread.current)")
                return false
            }

        var received = [Subscribers.Event<Int, Never>]()

        let cancellable = Publishers.TakeUntil(upstream: sourcePublisher, until: finisherPublisher)
            .print("TakeUntil")
            .subscribe(on: DispatchQueue.global())
            .breakpoint { _ -> Bool in
                Swift.print("TakeUntil: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("TakeUntil: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("TakeUntil: Completion CurrentThread \(Thread.current)")
                return false
            }
            .sink(event: { event in
                received.append(event)
                
                if case .complete(_) = event {
                    expectation.fulfill()
                }
            })

        withExtendedLifetime(cancellable) { wait(for: [expectation], timeout: 5.0) }
        XCTAssertEqual(true, received.contains(.complete(.finished)))
    }
    
    // MARK: Prefix Until Operations
    
    // Values are discarded after finisher emits value
    func testTakeUntilAfterFinisherReceivesValue() {
        
        let expectation = self.expectation(description: "Done")
        
        let scheduler = DispatchQueue.testScheduler
        
        let source = PassthroughSubject<Int, Never>()
        
        let sourcePublisher = source.print("Source").subscribe(on: scheduler)
        
        let finisher = PassthroughSubject<Void, Never>()
        
        let finisherPublisher = finisher.print("Finisher").subscribe(on: scheduler)
        
        var received = [Subscribers.Event<Int, Never>]()
        
        
        scheduler.schedule(after: scheduler.now.advanced(by: 1)) {
            source.send(0)
            source.send(1)
        }
        
        scheduler.schedule(after: scheduler.now.advanced(by: 2)) {
            finisher.send(())
        }
        
        scheduler.schedule(after: scheduler.now.advanced(by: 3)) {
            source.send(2)
            source.send(3)
        }
        
        let cancellable = sourcePublisher.take(until: finisherPublisher)
            .print("TakeUntil")
            .subscribe(on: scheduler)
            .sink(event: { event in
                received.append(event)
                
                if case .complete(_) = event {
                    expectation.fulfill()
                }
            })
        
        scheduler.advance(by: 3)
        
        withExtendedLifetime(cancellable) { wait(for: [expectation], timeout: 5.0) }
        XCTAssertEqual(received, [0,1].asEvents(completion: .finished))
    }
    
    // values are discarded after finisher receives completion
    func testTakeUntilAfterFinisherReceivesCompletion() {
        
        let expectation = self.expectation(description: "Done")
        
        let scheduler = DispatchQueue.testScheduler
        
        let source = PassthroughSubject<Int, Never>()
        
        let sourcePublisher = source.print("Source").subscribe(on: scheduler)
        
        let finisher = PassthroughSubject<Void, Never>()
        
        let finisherPublisher = finisher.print("Finisher").subscribe(on: scheduler)
        
        var received = [Subscribers.Event<Int, Never>]()
        
        
        scheduler.schedule(after: scheduler.now.advanced(by: 1)) {
            source.send(0)
            source.send(1)
        }
        
        scheduler.schedule(after: scheduler.now.advanced(by: 2)) {
            finisher.send(completion: .finished)
        }
        
        scheduler.schedule(after: scheduler.now.advanced(by: 3)) {
            source.send(2)
            source.send(3)
        }
        
        let cancellable = sourcePublisher.take(until: finisherPublisher)
            .print("TakeUntil")
            .subscribe(on: scheduler)
            .sink(event: { event in
                received.append(event)
                
                if case .complete(_) = event {
                    expectation.fulfill()
                }
            })
        
        scheduler.advance(by: 3)
        
        withExtendedLifetime(cancellable) { wait(for: [expectation], timeout: 5.0) }
        XCTAssertEqual(received, [0,1].asEvents(completion: .finished))
    }
    
    // takeUntil errors out if finisher emits failure
    func testTakeUntilAfterFinisherErrorOut() {
        
        let expectation = self.expectation(description: "Done")
        
        let scheduler = DispatchQueue.testScheduler
        
        let source = PassthroughSubject<Int, TestError>()
        
        let sourcePublisher = source.print("Source").subscribe(on: scheduler)
        
        let finisher = PassthroughSubject<Void, TestError>()
        
        let finisherPublisher = finisher.print("Finisher").subscribe(on: scheduler)
        
        var received = [Subscribers.Event<Int, TestError>]()
        
        
        scheduler.schedule(after: scheduler.now.advanced(by: 1)) {
            source.send(0)
            source.send(1)
        }
        
        scheduler.schedule(after: scheduler.now.advanced(by: 2)) {
            finisher.send(completion: .failure(.fix))
        }
        
        scheduler.schedule(after: scheduler.now.advanced(by: 3)) {
            source.send(2)
            source.send(3)
        }
        
        let cancellable = sourcePublisher.take(until: finisherPublisher)
            .print("TakeUntil")
            .subscribe(on: scheduler)
            .sink(event: { event in
                received.append(event)
                
                if case .complete(.failure(.fix)) = event {
                    expectation.fulfill()
                }
            })
        
        scheduler.advance(by: 3)
        
        withExtendedLifetime(cancellable) { wait(for: [expectation], timeout: 5.0) }
        XCTAssertEqual(received, [0,1].asEvents(failure: TestError.self, completion: .failure(.fix)))
    }
    
    // MARK: Lifecycle tests
    func testTakeUntilSourceCompletes() {
        
        let expectation = self.expectation(description: "Done")
        
        let scheduler = DispatchQueue.testScheduler
        
        let source = PassthroughSubject<Int, Never>()
        
        let sourcePublisher = source.print("Source").subscribe(on: scheduler)
        
        let finisher = PassthroughSubject<Void, Never>()
        
        let finisherPublisher = finisher.print("Finisher").subscribe(on: scheduler)
        
        var received = [Subscribers.Event<Int, Never>]()
        
        
        scheduler.schedule(after: scheduler.now.advanced(by: 1)) {
            source.send(0)
            source.send(1)
        }
        
        scheduler.schedule(after: scheduler.now.advanced(by: 2)) {
            source.send(completion: .finished)
        }
        
        scheduler.schedule(after: scheduler.now.advanced(by: 3)) {
            finisher.send(())
        }
        
        let cancellable = sourcePublisher.take(until: finisherPublisher)
            .print("TakeUntil")
            .subscribe(on: scheduler)
            .sink(event: { event in
                received.append(event)
                
                if case .complete(_) = event {
                    expectation.fulfill()
                }
            })
        
        scheduler.advance(by: 3)
        
        withExtendedLifetime(cancellable) { wait(for: [expectation], timeout: 5.0) }
        XCTAssertEqual(received, [0,1].asEvents(completion: .finished))
    }
    
    
    func testTakeUntilCancelling() {
        
        let expectation = self.expectation(description: "Done")
        
        let scheduler = DispatchQueue.testScheduler
        
        let source = PassthroughSubject<Int, Never>()
        
        let sourcePublisher = source.print("Source").subscribe(on: scheduler)
        
        let finisher = PassthroughSubject<Void, Never>()
        
        let finisherPublisher = finisher.print("Finisher").subscribe(on: scheduler)
        
        var received = [Subscribers.Event<Int, Never>]()
        
        scheduler.schedule(after: scheduler.now.advanced(by: 1)) {
            source.send(0)
            source.send(1)
        }
        
        scheduler.schedule(after: scheduler.now.advanced(by: 3)) {
            source.send(2)
            finisher.send(())
        }
        
        let cancellable = sourcePublisher.take(until: finisherPublisher)
            .print("TakeUntil")
            .subscribe(on: scheduler)
            .sink(event: { event in
                received.append(event)
                
                if case .complete(_) = event {
                    expectation.fulfill()
                }
            })
        
        
        scheduler.schedule(after: scheduler.now.advanced(by: 2)) {
            cancellable.cancel()
            expectation.fulfill()
        }
        
        scheduler.advance(by: 3)
        
        withExtendedLifetime(cancellable) { wait(for: [expectation], timeout: 5.0) }
        XCTAssertEqual(received, [0,1].asEvents())
    }
    
    func testTakeUntilCustomDemand() {
        
        let expectation = self.expectation(description: "Done")
        
        let scheduler = DispatchQueue.testScheduler
        
        let source = (0...10).publisher
        
        let sourcePublisher = source.print("Source").subscribe(on: scheduler)
        
        let finisher = PassthroughSubject<Void, Never>()
        
        let finisherPublisher = finisher.print("Finisher").subscribe(on: scheduler)
        
        var received = [Subscribers.Event<Int, Never>]()
        
        var subscription: Subscription?
        
        scheduler.schedule(after: scheduler.now.advanced(by: 1)) {
            subscription?.request(.max(1))
        }
        
        scheduler.schedule(after: scheduler.now.advanced(by: 2)) {
            subscription?.request(.max(1))
        }
        
        scheduler.schedule(after: scheduler.now.advanced(by: 3)) {
            finisher.send(completion: .finished)
        }
        
        
        scheduler.schedule(after: scheduler.now.advanced(by: 3.5)) {
            subscription?.request(.max(3))
        }
        
        sourcePublisher.take(until: finisherPublisher)
            .print("TakeUntil")
            .subscribe(on: scheduler)
            .subscribe(AnySubscriber(receiveSubscription: { subs in
                subscription = subs
                subs.request(.max(2))
            }, receiveValue: { event -> Subscribers.Demand in
                received.append(.value(event))
                return .none
            }, receiveCompletion: { completion in
                received.append(.complete(completion))
                expectation.fulfill()
            }))
        
        
        scheduler.advance(by: 4)
        
        withExtendedLifetime(subscription) { wait(for: [expectation], timeout: 5.0) }
        XCTAssertEqual(received, [0,1,2,3].asEvents(completion: .finished))
    }
}
