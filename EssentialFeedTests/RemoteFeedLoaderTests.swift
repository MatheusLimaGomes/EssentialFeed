//
//  EssentialFeedTests.swift
//  EssentialFeedTests
//
//  Created by Matheus Gomes on 05/02/24.
//

import XCTest

class RemoteFeedLoader {
    let client: HTTPClient
    let url: URL
    init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    func load() {
        client.get(from: url)
    }
}
protocol HTTPClient {
    func get(from url: URL)
}
class HTTPClientSPy: HTTPClient {
    func get(from url: URL) {
        requestedURL = url
    }
    var requestedURL: URL?
}
final class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let url =  URL(string: "https://a-url.com")!
        let client = HTTPClientSPy()
        _ = RemoteFeedLoader(client: client, url: url)
        XCTAssertNil(client.requestedURL)
    }
    func test_load_requestDataFromURL() {
        let url =  URL(string: "https://a-url.com")!
        let client = HTTPClientSPy()
        let sut = RemoteFeedLoader(client: client, url: url)
        
        sut.load()
        XCTAssertEqual(url, client.requestedURL)
    }
}

