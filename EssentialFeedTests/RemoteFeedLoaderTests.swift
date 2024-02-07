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
        // Arrange: Given the sut and HTTP client spy.
        let (sut, client) = makeSUT()
        // Act: When we tell the sut to load and we complete the client's HTTP request with an error.
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
        // Assert: Then we expect the captured load error to be a connectivity error.
        XCTAssertEqual(capturedErrors, [.connectivity])
    }
    func test_load_deliversErroOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()

        let samples = [199, 201, 400, 500]

        samples.enumerated().forEach { index, code in
            var capturedErrors = [RemoteFeedLoader.Error]()
            sut.load { capturedErrors.append($0) }
            
            client.complete(withStatusCode: code, at: index)
            
            XCTAssertEqual(capturedErrors, [.invalidData])
            capturedErrors = []
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
        func complete(withStatusCode code: Int, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success(response))
        }
    }
}

