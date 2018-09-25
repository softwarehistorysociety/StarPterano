
//
//  TimelineView.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/16.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 各種タイムラインやお気に入りなどを表示するUITableView

import UIKit

final class TimeLineView: UITableView {
    let type: TimeLineViewController.TimeLineType
    let option: String?
    private let model = TimeLineViewModel()
    private let refreshCon = UIRefreshControl()
    private weak var waitIndicator: UIView?
    private static let tableDispatchQueue = DispatchQueue(label: "TimeLineView")
    private static var isBusy = false
    
    var accountList: [String: AnalyzeJson.AccountData] = [:]
    
    init(type: TimeLineViewController.TimeLineType, option: String?, mensions: ([AnalyzeJson.ContentData], [String: AnalyzeJson.AccountData])?) {
        self.type = type
        self.option = option
        
        super.init(frame: UIScreen.main.bounds, style: UITableViewStyle.plain)
        
        self.delegate = model
        self.dataSource = model
        
        self.backgroundColor = ThemeColor.viewBgColor
        self.separatorColor = UIColor.clear
        
        if type != .mensions {
            // 引っ張って更新するやつを追加
            self.refreshCon.attributedTitle = NSAttributedString(string: I18n.get("REFRESH_TIMELINE"))
            self.refreshCon.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
            if #available(iOS 10.0, *) {
                self.refreshControl = self.refreshCon
            } else {
                self.backgroundView = self.refreshCon
            }
            
            let waitIndicator = WaitIndicator()
            self.waitIndicator = waitIndicator
            self.addSubview(waitIndicator)
        } else {
            // 会話表示
            self.model.showAutoPagerizeCell = false
            self.model.isDetailTimeline = true
            self.model.change(tableView: self, addList: mensions!.0, accountList: mensions!.1)
            self.model.selectedRow = 0
            DispatchQueue.main.async {
                // 古い物を取りに行く
                self.refresh()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if type == .home {
                // ストリーミング開始
                self?.streaming(streamingType: "user")
            }
            else if type == .local {
                // ストリーミング開始
                self?.streaming(streamingType: "public:local")
            }
            else if type == .global {
                // ストリーミング開始
                self?.streaming(streamingType: "public")
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // ストリーミングを受信
    //   ホーム(通知含む)、ローカル、連合のみ
    private var streamingObject: MastodonStreaming?
    @objc func streaming(streamingType: String) {
        guard let hostName = SettingsData.hostName else { return }
        guard let url = URL(string: "wss://\(hostName)/api/v1/streaming/?access_token=\(SettingsData.accessToken!)&stream=\(streamingType)") else { return }
        
        self.streamingObject = MastodonStreaming(url: url, callback: { [weak self] (string) in
            guard let strongSelf = self else { return }
            
            if let data = string?.data(using: String.Encoding.utf8) {
                do {
                    let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                    
                    guard let event = responseJson?["event"] as? String else { return }
                    let payload = responseJson?["payload"]
                    
                    switch event {
                    case "update":
                        if let string = payload as? String {
                            guard let json = try JSONSerialization.jsonObject(with: string.data(using: String.Encoding.utf8)!, options: .allowFragments) as? [String: Any] else { return }
                            TimeLineView.tableDispatchQueue.async {
                                var acct = ""
                                let statusData = AnalyzeJson.analyzeJson(view: strongSelf, model: strongSelf.model, json: json, acct: &acct)
                                strongSelf.model.change(tableView: strongSelf, addList: [statusData], accountList: strongSelf.accountList)
                                
                                if TimeLineView.isBusy {
                                    return
                                }
                                TimeLineView.isBusy = true
                                DispatchQueue.main.sync {
                                    strongSelf.refresh() // #### １つずつ追加するようにしたい
                                }
                                TimeLineView.isBusy = false
                            }
                        }
                    case "notification":
                        break
                    case "delete":
                        break
                    case "filters_changed":
                        break
                    default:
                        break
                    }
                } catch { }
            }
        })
    }
    
    // タイムラインを手動更新
    @objc func refresh() {
        guard let hostName = SettingsData.hostName else { return }
        
        var sinceIdStr = ""
        if let id = model.getFirstTootId() {
            sinceIdStr = "&since_id=\(id)"
        }
        
        let url: URL?
        switch self.type {
        case .home:
            url = URL(string: "https://\(hostName)/api/v1/timelines/home?limit=100\(sinceIdStr)")
        case .local:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?local=1&limit=100\(sinceIdStr)")
        case .global:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?limit=100\(sinceIdStr)")
        case .user:
            guard let option = option else { return }
            url = URL(string: "https://\(hostName)/api/v1/accounts/\(option)/statuses?limit=100\(sinceIdStr)")
        case .favorites:
            url = URL(string: "https://\(hostName)/api/v1/favourites?limit=50\(sinceIdStr)")
        case .localTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?local=1&limit=100\(sinceIdStr)")
        case .globalTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?&limit=100\(sinceIdStr)")
        case .mensions:
            guard let lastInReplyToId = model.getLastInReplyToId() else { return }
            url = URL(string: "https://\(hostName)/api/v1/statuses/\(lastInReplyToId)")
        }
        
        guard let requestUrl = url else { return }
        
        try? MastodonRequest.get(url: requestUrl) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            DispatchQueue.main.async {
                self?.refreshCon.endRefreshing()
                self?.waitIndicator?.removeFromSuperview()
            }
            
            if let data = data {
                do {
                    if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [AnyObject] {
                        AnalyzeJson.analyzeJsonArray(view: strongSelf, model: strongSelf.model, jsonList: responseJson, isNew: true)
                    } else if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                        TimeLineView.tableDispatchQueue.async {
                            var acct = ""
                            let contentData = AnalyzeJson.analyzeJson(view: strongSelf, model: strongSelf.model, json: responseJson, acct: &acct)
                            let contentList = [contentData]
                            
                            strongSelf.model.change(tableView: strongSelf, addList: contentList, accountList: strongSelf.accountList)
                            
                            // 続きを取得
                            DispatchQueue.main.sync {
                                if self?.type == .mensions && contentData.in_reply_to_id == nil {
                                    return // ループ防止
                                }
                                strongSelf.refresh()
                            }
                        }
                    }
                } catch {
                }
            } else if let error = error {
                print(error)
            }
        }
    }
    
    // タイムラインに古いトゥートを追加
    func refreshOld(id: String?) {
        guard let hostName = SettingsData.hostName else { return }
        
        if id == nil { return }
        
        let maxIdStr = "&max_id=\(id ?? "")"
        
        let url: URL?
        switch self.type {
        case .home:
            url = URL(string: "https://\(hostName)/api/v1/timelines/home?limit=50\(maxIdStr)")
        case .local:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?local=1&limit=50\(maxIdStr)")
        case .global:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?limit=50\(maxIdStr)")
        case .user:
            guard let option = option else { return }
            url = URL(string: "https://\(hostName)/api/v1/accounts/\(option)/statuses?limit=50\(maxIdStr)")
        case .favorites:
            url = URL(string: "https://\(hostName)/api/v1/favourites?limit=50\(maxIdStr)")
        case .localTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?local=1&limit=50\(maxIdStr)")
        case .globalTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?&limit=50\(maxIdStr)")
        case .mensions:
            return
        }
        
        guard let requestUrl = url else { return }
        
        try? MastodonRequest.get(url: requestUrl) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            if let data = data {
                do {
                    let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject>
                    
                    if let responseJson = responseJson {
                        TimeLineView.tableDispatchQueue.async {
                            AnalyzeJson.analyzeJsonArray(view: strongSelf, model: strongSelf.model, jsonList: responseJson, isNew: false)
                        }
                    }
                } catch {
                }
            } else if let error = error {
                print(error)
            }
        }
    }
    
    // お気に入りにする/解除する
    func favoriteAction(id: String, isFaved: Bool) {
        guard let hostName = SettingsData.hostName else { return }
        
        let url: URL
        if isFaved {
            url = URL(string: "https://\(hostName)/api/v1/statuses/\(id)/unfavourite")!
        } else {
            url = URL(string: "https://\(hostName)/api/v1/statuses/\(id)/favourite")!
        }
        
        try? MastodonRequest.post(url: url, body: [:]) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            if let data = data {
                do {
                    if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                        var acct = ""
                        let contentData = AnalyzeJson.analyzeJson(view: strongSelf, model: strongSelf.model, json: responseJson, acct: &acct)
                        let contentList = [contentData]
                        strongSelf.model.change(tableView: strongSelf, addList: contentList, accountList: strongSelf.accountList)
                    }
                } catch {
                    
                }
            }
        }
    }
    
    // ブーストする/解除する
    func boostAction(id: String, isBoosted: Bool) {
        guard let hostName = SettingsData.hostName else { return }
        
        let url: URL
        if isBoosted {
            url = URL(string: "https://\(hostName)/api/v1/statuses/\(id)/unreblog")!
        } else {
            url = URL(string: "https://\(hostName)/api/v1/statuses/\(id)/reblog")!
        }
        
        try? MastodonRequest.post(url: url, body: [:]) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            if let data = data {
                do {
                    if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                        var acct = ""
                        let contentData = AnalyzeJson.analyzeJson(view: strongSelf, model: strongSelf.model, json: responseJson, acct: &acct)
                        let contentList = [contentData]
                        strongSelf.model.change(tableView: strongSelf, addList: contentList, accountList: strongSelf.accountList)
                    }
                } catch {
                    
                }
            }
        }
    }
    
    // ミニビューにする
    func enterMiniView() {
        switch SettingsData.isMiniView {
        case .normal:
            SettingsData.isMiniView = .miniView
        case .miniView:
            SettingsData.isMiniView = .superMini
        case .superMini:
            break
        }
        
        self.reloadData()
    }
    
    // ミニビューを解除する
    func exitMiniView() {
        switch SettingsData.isMiniView {
        case .normal:
            break
        case .miniView:
            SettingsData.isMiniView = .normal
        case .superMini:
            SettingsData.isMiniView = .miniView
        }
        
        self.reloadData()
    }
    
    // タッチしている間ボタンを隠す
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        MainViewController.instance?.hideButtons()
    }
}
