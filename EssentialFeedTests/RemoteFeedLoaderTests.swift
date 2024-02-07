//
//  EssentialFeedTests.swift
//  EssentialFeedTests
//
//  Created by Matheus Gomes on 05/02/24.
//

import XCTest
import EssentialFeed

final class RemoteFeedLoaderTests: XCTestCase {

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
            tocompleteWith: .failure(.connectivity)
        ) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }
    func test_load_deliversErroOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()

        let samples = [199, 201, 400, 500]

        samples.enumerated().forEach { index, code in
            expect(sut: sut, tocompleteWith: .failure(.invalidData)) {
                client.complete(withStatusCode: code, at: index)
            }
        }
    }
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJson() {
        let (sut, client) = makeSUT()
        expect(sut: sut, tocompleteWith: .failure(.invalidData) ) {
            let invalidJson = Data("invalid_json".utf8)
            client.complete(withStatusCode: 200, data: invalidJson)
        }
    }
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJsonList() {
        let (sut, client) = makeSUT()
        
        expect(sut: sut, tocompleteWith: .success([])) {
            let emptyListJson = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyListJson)
        }
    }
    func test_load_deliversItemsOn200HTTPResponseWithJsonItems() {
        let (sut, client) = makeSUT()
        let item1 = FeedItem(
            id: UUID(), description: nil,
            location: nil, imageURL: URL(string: "http://a-url.com")!
        )
        let item1Json = [
            "id": item1.id.uuidString,
            "image": item1.imageURL.absoluteString
        ]
        let item2 = FeedItem(
            id: UUID(), description: "a description",
            location: "a location", imageURL: URL(string: "http://another-url.com")!
        )
        
        let item2Json = [
            "id": item2.id.uuidString,
            "description": item2.description,
            "location": item2.location,
            "image": item2.imageURL.absoluteString
        ]
        let itemsJson = [
            "items": [ item1Json, item2Json]
        ]
        expect(sut: sut, tocompleteWith: .success([item1, item2])) {
            let json = try! JSONSerialization.data(withJSONObject: itemsJson)
            client.complete(withStatusCode: 200, data: json)
        }
    }
}

// MARK: - Helpers
extension RemoteFeedLoaderTests {
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSPy) {
        let client = HTTPClientSPy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    func expect(
        sut: RemoteFeedLoader,
        tocompleteWith result: RemoteFeedLoader.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        action()
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }
    private class HTTPClientSPy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        var requestedURLs: [URL] {
            return messages.map {$0.url}
        }
        var completions = [(Error) -> Void]()
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url,completion))
        }
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error  ))
        }
        func complete(withStatusCode code: Int, data: Data = Data(),  at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success(data, response))
        }
    }
}

