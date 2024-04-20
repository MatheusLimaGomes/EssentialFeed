//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Matheus Gomes on 08/02/24.
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    
    /// - Parameters:
    ///   - url: URL from foundation.
    ///   - completion: The completion handler can be invoked in any thread.
    /// Clients are resposible to dispach to appropriate threads, if needed.
    func get(from url: URL, completion: @escaping (Result) -> Void)
}
