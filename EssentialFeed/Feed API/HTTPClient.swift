//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Matheus Gomes on 08/02/24.
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    func get(from url: URL, completion: @escaping (Result) -> Void)
}
