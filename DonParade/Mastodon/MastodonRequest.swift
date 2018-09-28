//
//  MastodonRequest.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// MastodonサーバーにHTTP GET/POSTメソッドでJSONを送信する

import Foundation

final class MastodonRequest {
    static let session = URLSession.shared
    
    // GETメソッド
    private static var lastRequestStr = "" // GETメソッドをループして呼ぶのを防ぐ
    private static var lastReqestDate = Date()
    static func get(url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
        if lastRequestStr == url.absoluteString && Date().timeIntervalSince(lastReqestDate) <= 1 {
            print("1秒以内に同一URLへのGETがありました \(url.absoluteString)")
            return
        }
        
        print("get \(url.absoluteString)")
        
        lastRequestStr = url.absoluteString
        lastReqestDate = Date()
        
        var request: URLRequest = URLRequest(url: url)
        
        guard let accessToken = SettingsData.accessToken else { return }
        
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        session.dataTask(with: request, completionHandler: completionHandler).resume()
    }
    
    // POSTメソッド
    static func post(url: URL, body: Dictionary<String, Any>, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
        print("post \(url.path)")
        
        var request: URLRequest = URLRequest(url: url)
        
        guard let accessToken = SettingsData.accessToken else { return }
        
        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        
        session.dataTask(with: request, completionHandler: completionHandler).resume()
    }
    
    // DELETEメソッド
    static func delete(url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
        var request: URLRequest = URLRequest(url: url)
        
        guard let accessToken = SettingsData.accessToken else { return }
        
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        session.dataTask(with: request, completionHandler: completionHandler).resume()
    }
    
    // POSTメソッド (アクセストークンなし、認証前に使う)
    static func firstPost(url: URL, body: Dictionary<String, String>, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
        var request: URLRequest = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        
        session.dataTask(with: request, completionHandler: completionHandler).resume()
    }
}
