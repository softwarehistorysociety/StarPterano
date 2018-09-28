//
//  SettingsModel.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/16.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit

final class SettingsModel: NSObject, UITableViewDataSource, UITableViewDelegate {
    // カテゴリー
    private enum Category: String {
        case selectAccount = "SETTINGS_SELECT_ACCOUNT"
        case account = "SETTINGS_ACCOUNT"
        case mypage = "SETTINGS_MASTODON"
        case application = "SETTINGS_APPLICATION"
        case other = "SETTINGS_OTHER"
    }
    private let categoryList: [Category] = [.selectAccount,
                                            .account,
                                            .mypage,
                                            .application,
                                            .other]
    
    // 1.アカウントの切り替え
    //   SettingsDataに登録してあるアカウントを表示する
    
    // 2.アカウントの追加
    private enum Account: String {
        case add = "SETTINGS_ADD_ACCOUNT"
    }
    private let accountList: [Account] = [.add]
    
    // 3.マストドン設定
    private enum MyPage: String {
        case mastodonSite = "SETTINGS_MASTODON_SITE"
        case mypage = "SETTINGS_MYPAGE"
        //case list = "SETTINGS_LIST"
        case dm = "SETTINGS_DMLIST"
        case favorite = "SETTINGS_FAVORITELIST"
        case mute = "SETTINGS_MUTELIST"
        case block = "SETTINGS_BLOCKLIST"
        case searchAccount = "SETTINGS_SEARCH_ACCOUNT"
    }
    private let myPageList: [MyPage] = [.mastodonSite,
                                        .mypage,
                                        .dm,
                                        .favorite]
                                        //.mute,
                                        //.block,
                                        //.searchAccount]
    
    // 4.アプリの設定
    private enum Application: String {
        case tootProtectDefault = "SETTINGS_TOOT_PROTECT_DEFAULT"
        case darkMode = "SETTINGS_DARKMODE"
        case coloring = "SETTINGS_CELLCOLORING"
        case fontSize = "SETTINGS_FONTSIZE"
        case streaming = "SETTINGS_STREAMING"
        case iconSize = "SETTINGS_ICONSIZE"
        case loadPreviewImage = "SETTINGS_LOADPREVIEW"
        case nameTappable = "SETTINGS_NAMETAPPABLE" // アカウント名をタップできるか
    }
    private let applicationList: [Application] = [.tootProtectDefault,
                                                  .darkMode,
                                                  .coloring,
                                                  .fontSize,
                                                  .iconSize,
                                                  .loadPreviewImage,
                                                  .nameTappable,
                                                  .streaming]
    
    // 5.キャッシュ
    private enum Cache: String {
        case clearCache = "SETTINGS_CLEAR_CACHE"
        //case showIcons = "SETTINGS_SHOW_ICONS"
    }
    private let cacheList: [Cache] = [.clearCache]
    
    // 6.その他
    private enum Other: String {
        //case search = "SETTINGS_SEARCH" // 表示しているタイムラインから検索
        case license = "SETTINGS_LICENSE"
        case version = "SETTINGS_VERSION"
    }
    private let otherList: [Other] = [.license,
                                      .version]
    
    // セクションの数
    func numberOfSections(in tableView: UITableView) -> Int {
        return categoryList.count
    }
    
    // セクションの名前
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return I18n.get(categoryList[section].rawValue)
    }
    
    // セクション内のセルの数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return SettingsData.accountList.count
        case 1:
            return accountList.count
        case 2:
            return myPageList.count
        case 3:
            return applicationList.count
        case 4:
            return otherList.count
        default:
            return 0
        }
    }
    
    // セルを返す
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "SettingsModel"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: reuseIdentifier)
        
        cell.accessoryType = .none
        
        var title = ""
        var subtitle: String? = nil
        switch indexPath.section {
        case 0:
            let data = SettingsData.accountList[indexPath.row]
            title = (SettingsData.accountUsername(accessToken: data.1) ?? "") + " @ " + data.0.replacingOccurrences(of: "https://", with: "") 
            
            if SettingsData.hostName == data.0 && SettingsData.accessToken == data.1 {
                cell.accessoryType = .checkmark
            }
        case 1:
            title = I18n.get(accountList[indexPath.row].rawValue)
            cell.accessoryType = .disclosureIndicator
        case 2:
            title = I18n.get(myPageList[indexPath.row].rawValue)
            cell.accessoryType = .disclosureIndicator
        case 3:
            title = I18n.get(applicationList[indexPath.row].rawValue)
            switch applicationList[indexPath.row] {
            case .tootProtectDefault:
                cell.accessoryType = .disclosureIndicator
                
                switch SettingsData.protectMode {
                case .publicMode:
                    subtitle = I18n.get("PROTECTMODE_PUBLIC")
                case .unlisted:
                    subtitle = I18n.get("PROTECTMODE_UNLISTED")
                case .privateMode:
                    subtitle = I18n.get("PROTECTMODE_PRIVATE")
                case .direct:
                    subtitle = I18n.get("PROTECTMODE_DIRECT")
                }
            case .darkMode:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.isDarkMode)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.isDarkMode = isOn
                }
                return cell
            case .coloring:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.useColoring)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.useColoring = isOn
                }
                return cell
            case .fontSize:
                let cell = SettingsStepperCell(style: .default,
                                               value: Double(SettingsData.fontSize),
                                               minValue: 12,
                                               maxValue: 24,
                                               step: 1)
                cell.textLabel?.text = title + " : " + "\(Int(SettingsData.fontSize))pt"
                cell.callback = { [weak cell] value in
                    SettingsData.fontSize = CGFloat(value)
                    cell?.textLabel?.text = title + " : " + "\(Int(SettingsData.fontSize))pt"
                }
                return cell
            case .streaming:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.isStreamingMode)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.isStreamingMode = isOn
                }
                return cell
            case .loadPreviewImage:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.isLoadPreviewImage)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.isLoadPreviewImage = isOn
                }
                return cell
            case .nameTappable:
                let cell = SettingsSwitchCell(style: .default, isOn: SettingsData.isNameTappable)
                cell.textLabel?.text = title
                cell.callback = { isOn in
                    SettingsData.isNameTappable = isOn
                }
                return cell
            case .iconSize:
                let cell = SettingsStepperCell(style: .default,
                                               value: Double(SettingsData.iconSize),
                                               minValue: 24,
                                               maxValue: 50,
                                               step: 2)
                cell.textLabel?.text = title + " : " + "\(Int(SettingsData.iconSize))pt"
                cell.callback = { [weak cell] value in
                    SettingsData.iconSize = CGFloat(value)
                    cell?.textLabel?.text = title + " : " + "\(Int(SettingsData.iconSize))pt"
                }
                return cell
            }
        case 4:
            title = I18n.get(otherList[indexPath.row].rawValue)
            switch otherList[indexPath.row] {
            case .license:
                cell.accessoryType = .disclosureIndicator
            case .version:
                let data = Bundle.main.infoDictionary
                let version = data?["CFBundleShortVersionString"] as? String
                subtitle = version
            }
        default:
            break
        }
        
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = subtitle
        
        return cell
    }
    
    // セルを選択
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            let data = SettingsData.accountList[indexPath.row]
            SettingsData.hostName = data.0
            SettingsData.accessToken = data.1
            tableView.reloadData()
        case 1:
            switch accountList[indexPath.row] {
            case .add:
                SettingsViewController.instance?.dismiss(animated: false, completion: nil)
                MainViewController.instance?.dismiss(animated: false, completion: nil)
                
                // ログイン画面を表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let vc = UIUtils.getFrontViewController() as? LoginViewController {
                        (vc.view as? LoginView)?.reset()
                    } else {
                        let loginViewController = LoginViewController()
                        UIUtils.getFrontViewController()?.present(loginViewController, animated: false, completion: nil)
                    }
                }
            }
        case 2:
            switch myPageList[indexPath.row] {
            case .mastodonSite:
                guard let url = URL(string: "https://\(SettingsData.hostName ?? "")") else { return }
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            case .mypage:
                ShowMyAnyList.showMyPage(rootVc: SettingsViewController.instance!)
            case .dm:
                ShowMyAnyList.showDMList(rootVc: SettingsViewController.instance!)
            case .favorite:
                ShowMyAnyList.showFavoriteList(rootVc: SettingsViewController.instance!)
            case .block:
                ShowMyAnyList.showBlockList(rootVc: SettingsViewController.instance!)
            case .mute:
                ShowMyAnyList.showMuteList(rootVc: SettingsViewController.instance!)
            case .searchAccount:
                break
            }
        case 3:
            switch applicationList[indexPath.row] {
            case .tootProtectDefault:
                SettingsSelectProtectMode.showActionSheet() { mode in
                    SettingsData.protectMode = mode
                    tableView.reloadData()
                }
            default:
                break
            }
        case 4:
            switch otherList[indexPath.row] {
            case .license:
                guard let path = Bundle.main.path(forResource: "License", ofType: "text") else { return }
                guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return }
                guard let licenseStr = String(data: data, encoding: String.Encoding.utf8) else { return }
                Dialog.show(message: licenseStr)
            case .version:
                break
            }
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    // セルが削除対応かどうかを決める
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section == 0 {
            return UITableViewCellEditingStyle.delete
        }
        
        return UITableViewCellEditingStyle.none
    }
    
    // スワイプでの削除
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.section == 0 && indexPath.row < SettingsData.accountList.count {
                Dialog.show(message: I18n.get("DIALOG_REMOVE_ACCOUNT"),
                            okName: I18n.get("BUTTON_REMOVE"),
                            cancelName: I18n.get("BUTTON_CANCEL"))
                { result in
                    if result {
                        let oldData = SettingsData.accountList[indexPath.row]
                        
                        // 削除
                        SettingsData.accountList.remove(at: indexPath.row)
                        
                        // 選択中のアカウントを削除した場合、最初のアカウントに移動するか、ログアウト状態にする
                        if oldData.0 == SettingsData.hostName && oldData.0 == SettingsData.accessToken {
                            SettingsData.hostName = SettingsData.accountList.first?.0
                            SettingsData.accessToken = SettingsData.accountList.first?.1
                        }
                    }
                }
            }
        }
    }
}
