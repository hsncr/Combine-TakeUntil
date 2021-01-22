//
//  PrefixUntilTests.swift
//  CombinePrefixUntilTests
//
//  Created by hsncr on 20.01.2021.
//

import XCTest
import Combine
import CombineSchedulers
@testable import CombineTakeUntil

class PrefixUntilTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: Each publisher is on current scheduler
    
    // Execution order changes by finisher operation.
    // If finisher is PassthroughSubject(testPrefixUntilPassthroughSubjectCompleterCaseScheduleAllOnCurrentScheduler)
    // and doesn't receive value to complete upstream publisher asap.
    // execution goes as following; finisher, source and prefixUntil gets subscription in that order and
    // after prefixUntil receives demand, passes it onto source. from that on,
    // source feed downstream subscriber.
    // If finisher is CurrentValueSubject(testPrefixUntilCurrentValueSubjectCompleterCaseScheduleAllOnCurrentScheduler), then after finisher receives value,
    // it immediately calls completion on downstream subscriber to complete prefixUntil Publisher. This sometimes creates problem because downstream subscriber receives event before getting subscription object.
    // If finisher executes on its serial scheduler that is defined by subscribe(on:), it can pass finished event even downstream subscriber doesn't get subscription.
    // It is really weird edge case that can be a problem if upstream execution doesn't fit in timing.
    func testPrefixUntilPassthroughSubjectCompleterCaseScheduleAllOnCurrentScheduler() {

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

        let cancellable = sourcePublisher.prefix(untilOutputFrom: finisherPublisher)
            .print("PrefixUntil")
            .breakpoint { _ -> Bool in
                Swift.print("PrefixUntil: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("PrefixUntil: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("PrefixUntil: Completion CurrentThread \(Thread.current)")
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
    
    // finished event is received, even downstream subscriber doesn't receive subscription object because it is on main queue,
    func testPrefixUntilCurrentValueSubjectCompleterCaseScheduleAllOnCurrentScheduler() {

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

        let cancellable = Publishers.PrefixUntilOutput(upstream: sourcePublisher, other: finisherPublisher)
            .print("PrefixUntil")
            .breakpoint { _ -> Bool in
                Swift.print("PrefixUntil: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("PrefixUntil: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("PrefixUntil: Completion CurrentThread \(Thread.current)")
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
    // finished event is received because downstream subscriber receives subscription before finisher emits value if serial scheduler is set.
    func testPrefixUntilCurrentValueSubjectCompleterCaseScheduleAllSerialQueue() {

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

        let cancellable = Publishers.PrefixUntilOutput(upstream: sourcePublisher, other: finisherPublisher)
            .print("PrefixUntil")
            .subscribe(on: scheduler)
            .breakpoint { _ -> Bool in
                Swift.print("PrefixUntil: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("PrefixUntil: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("PrefixUntil: Completion CurrentThread \(Thread.current)")
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
    
    // MARK: Fails
    // finished event isn't received because it is executed on received subscribe(on:) command from upstream scheduler, and downstream subscriber needs to receive subscription object first now.
    func testPrefixUntilCurrentValueSubjectCompleterCaseScheduleAllSerialQueueExceptFinisher() {

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

        let cancellable = Publishers.PrefixUntilOutput(upstream: sourcePublisher, other: finisherPublisher)
            .print("PrefixUntil")
            .subscribe(on: scheduler)
            .breakpoint { _ -> Bool in
                Swift.print("PrefixUntil: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("PrefixUntil: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("PrefixUntil: Completion CurrentThread \(Thread.current)")
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
    
    // MARK: Fails randomly
    // if prefixUntil receives subscription before finisher emits value, then downstream subscriber receives completion event. otherwise this test fails too.
    func testPrefixUntilCurrentValueSubjectCompleterCaseProblemScheduleAllOnGlobalDispatchQueue() {

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

        let cancellable = Publishers.PrefixUntilOutput(upstream: sourcePublisher, other: finisherPublisher)
            .print("PrefixUntil")
            .subscribe(on: DispatchQueue.global())
            .breakpoint { _ -> Bool in
                Swift.print("PrefixUntil: Subs CurrentThread \(Thread.current)")
                return false
            } receiveOutput: { _ -> Bool in
                Swift.print("PrefixUntil: Output CurrentThread \(Thread.current)")
                return false
            } receiveCompletion: { _ -> Bool in
                Swift.print("PrefixUntil: Completion CurrentThread \(Thread.current)")
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
    func testPrefixUntilAfterFinisherReceivesValue() {
        
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
        
        let cancellable = sourcePublisher.prefix(untilOutputFrom: finisherPublisher)
            .print("PrefixUntil")
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
    
    // values are continued to be emitted after finisher receives completion
    func testPrefixUntilAfterFinisherReceivesCompletion() {
        
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
            expectation.fulfill()
        }
        
        let cancellable = sourcePublisher.prefix(untilOutputFrom: finisherPublisher)
            .print("PrefixUntil")
            .subscribe(on: scheduler)
            .sink(event: { event in
                received.append(event)
                
                if case .complete(_) = event {
                    expectation.fulfill()
                }
            })
        
        scheduler.advance(by: 3)
        
        withExtendedLifetime(cancellable) { wait(for: [expectation], timeout: 5.0) }
        XCTAssertEqual(received, [0,1,2,3].asEvents())
    }
    
    // prefixUntil ignores if finisher emits failure
    func testPrefixUntilAfterFinisherErrorOut() {
        
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
            expectation.fulfill()
        }
        
        let cancellable = sourcePublisher.prefix(untilOutputFrom: finisherPublisher)
            .print("PrefixUntil")
            .subscribe(on: scheduler)
            .sink(event: { event in
                received.append(event)
                
                if case .complete(_) = event {
                    expectation.fulfill()
                }
            })
        
        scheduler.advance(by: 3)
        
        withExtendedLifetime(cancellable) { wait(for: [expectation], timeout: 5.0) }
        XCTAssertEqual(received, [0,1,2,3].asEvents(failure: TestError.self))
    }
    
    // MARK: Lifecycle tests
    func testPrefixUntilSourceCompletes() {
        
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
        
        let cancellable = sourcePublisher.prefix(untilOutputFrom: finisherPublisher)
            .print("PrefixUntil")
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
    
    
    func testPrefixUntilCancelling() {
        
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
        
        let cancellable = sourcePublisher.prefix(untilOutputFrom: finisherPublisher)
            .print("PrefixUntil")
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

}
