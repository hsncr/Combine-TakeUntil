# Combine-TakeUntil implementation

```swift
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
```

