//
//  LoadFeedFromRemoteUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Matheus Gomes on 05/02/24.
//

import XCTest
import EssentialFeed

final class LoadFeedFromRemoteUseCaseTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-different-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load { _ in }
        XCTAssertEqual([url], client.requestedURLs)
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-different-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load { _ in }
        sut.load { _ in }
        XCTAssertEqual(client.requestedURLs, [url,url])
    }
    func test_load_deliversErroOnClientError() {
        let (sut, client) = makeSUT()
        expect(
            sut: sut,
            tocompleteWith: failure(RemoteFeedLoader.Error.connectivity)
        ) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }
    func test_load_deliversErroOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()

        let samples = [199, 201, 400, 500]

        samples.enumerated().forEach { index, code in
            expect(sut: sut, tocompleteWith: failure(RemoteFeedLoader.Error.invalidData)) {
                let json = makeItemsJson([])
                client.complete(withStatusCode: code, data: json, at: index)
            }
        }
    }
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJson() {
        let (sut, client) = makeSUT()
        expect(sut: sut, tocompleteWith: failure(RemoteFeedLoader.Error.invalidData) ) {
            let invalidJson = Data("invalid_json".utf8)
            client.complete(withStatusCode: 200, data: invalidJson)
        }
    }
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJsonList() {
        let (sut, client) = makeSUT()
        
        expect(sut: sut, tocompleteWith: .success([])) {
            let emptyListJson = makeItemsJson([])
            client.complete(withStatusCode: 200, data: emptyListJson)
        }
    }
    func test_load_deliversItemsOn200HTTPResponseWithJsonItems() {
        let (sut, client) = makeSUT()
        let item1 = makeItem(
            id: UUID(),
            imageURL: URL(string: "http://a-url.com")!
        )
        let item2 = makeItem(
            id: UUID(), description: "a description",
            location: "a location", imageURL: URL(string: "http://another-url.com")!
        )
        let items = [item1.model, item2.model]
        
        expect(sut: sut, tocompleteWith: .success(items)) {
            let json = makeItemsJson([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: json)
        }
    }
    func test_load_doesNotDeliverResultAfterSutInstanceHasBeenDeallocaterd() {
        let url = URL(string: "http://any-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = .init(client: client, url: url)
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append($0)}
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJson([]))
        
        
        XCTAssertTrue(capturedResults.isEmpty)
        
    }
}

// MARK: - Helpers
extension LoadFeedFromRemoteUseCaseTests {
    private func makeSUT(
        url: URL = URL(string: "https://a-url.com")!,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        trackForMemoryLeaks(instance: sut, file: file, line: line)
        trackForMemoryLeaks(instance: client, file: file, line: line)
        return (sut, client)
    }
    func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        return .failure(error)
    }
    func makeItem(
        id: UUID, description: String? = nil,
        location: String? = nil, imageURL: URL
    ) -> (model: FeedItem, json: [String: Any]) {
        let model = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].reduce(into: [String: Any]()) { (acc, e) in
            if let value = e.value { acc[e.key] = value }
        }
        return (model, json)
    }
    func makeItemsJson(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    func expect(
        sut: RemoteFeedLoader,
        tocompleteWith expectedResult: RemoteFeedLoader.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load completion")
        sut.load { receivedResult in
            switch(receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default: XCTFail("Expected Result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        action()
        waitForExpectations(timeout: 0.1)
    }
}

