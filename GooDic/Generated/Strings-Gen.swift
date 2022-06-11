// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// 「以前の購入」が存在しないアカウントである
  internal static let userHaveNotEverBeenPurchase = L10n.tr("Localizable", "user_have_not_ever_been_purchase")

  internal enum BackUpSetting {
    /// バックアップデータが作成されていません。
    internal static let notFound = L10n.tr("Localizable", "BackUpSetting.NotFound")
  }

  internal enum BackupDetail {
    internal enum Restore {
      /// バックアップを選択中のフォルダに復元しました。「OK」で、選択中のフォルダ画面を移動します。
      /// 
      internal static let message = L10n.tr("Localizable", "BackupDetail.Restore.Message")
    }
    internal enum RestoreConfirm {
      /// このバックアップを復元してよろしいですか？
      /// 
      internal static let message = L10n.tr("Localizable", "BackupDetail.RestoreConfirm.Message")
    }
  }

  internal enum BackupList {
    internal enum Backup {
      /// のバックアップ
      internal static let title = L10n.tr("Localizable", "BackupList.Backup.Title")
    }
    internal enum Created {
      /// 作成中の文章
      internal static let title = L10n.tr("Localizable", "BackupList.Created.Title")
    }
  }

  internal enum SettingBackup {
    /// 分毎
    internal static let minute = L10n.tr("Localizable", "SettingBackup.Minute")
    internal enum AlertEnableBackup {
      /// オンにすると、クラウドの下書きのバックアップを作成します（作成時に通信が発生します）。バックアップが30件を超えた場合は、古いものから削除されます。
      internal static let title = L10n.tr("Localizable", "SettingBackup.AlertEnableBackup.Title")
    }
    internal enum BackupCreationCell {
      /// オンにするとクラウドの下書きのバックアップを作成します。
      internal static let contentBackupOnOrOff = L10n.tr("Localizable", "SettingBackup.BackupCreationCell.ContentBackupOnOrOff")
      /// バックアップ作成
      internal static let titleBackupOnOrOff = L10n.tr("Localizable", "SettingBackup.BackupCreationCell.TitleBackupOnOrOff")
    }
    internal enum BackupCreationRuleCell {
      /// 文章作成画面の保存ボタンをタップした時に作成します。※文章に差分がある時のみ
      internal static let contentBackupManual = L10n.tr("Localizable", "SettingBackup.BackupCreationRuleCell.ContentBackupManual")
      /// 文章作成画面を開いている間、設定した間隔で作成します。※文章に差分がある時のみ
      internal static let contentBackupRegular = L10n.tr("Localizable", "SettingBackup.BackupCreationRuleCell.ContentBackupRegular")
      /// 手動保存時に作成する
      internal static let titleBackupManual = L10n.tr("Localizable", "SettingBackup.BackupCreationRuleCell.TitleBackupManual")
      /// 定期的に作成する
      internal static let titleBackupRegular = L10n.tr("Localizable", "SettingBackup.BackupCreationRuleCell.TitleBackupRegular")
    }
    internal enum BackupCreationRuleTitleCell {
      /// バックアップ作成ルール
      internal static let title = L10n.tr("Localizable", "SettingBackup.BackupCreationRuleTitleCell.Title")
    }
    internal enum Error {
      /// 設定値が存在しません。
      internal static let settingBackupNotFound = L10n.tr("Localizable", "SettingBackup.Error.SettingBackupNotFound")
    }
  }

  internal enum SettingEnviromental {
    internal enum AutoCloudSaveCell {
      /// オンにするとクラウドの下書きが自動保存されます。
      internal static let content = L10n.tr("Localizable", "SettingEnviromental.AutoCloudSaveCell.Content")
      /// クラウドの自動保存
      internal static let title = L10n.tr("Localizable", "SettingEnviromental.AutoCloudSaveCell.Title")
    }
    internal enum BackupCell {
      /// オン
      internal static let on = L10n.tr("Localizable", "SettingEnviromental.BackupCell.On")
      /// バックアップ
      internal static let title = L10n.tr("Localizable", "SettingEnviromental.BackupCell.Title")
    }
  }

  internal enum SettingFont {
    /// 自動保存を「ON」にした場合、文章作成画面で文章を変更すると、一定時間毎にデータ通信が発生します。
    internal static let alertAutoSave = L10n.tr("Localizable", "SettingFont.AlertAutoSave")
  }

  internal enum Sort {
    /// 作成日
    internal static let createDate = L10n.tr("Localizable", "Sort.CreateDate")
    /// 手動
    internal static let manual = L10n.tr("Localizable", "Sort.Manual")
    /// タイトル
    internal static let title = L10n.tr("Localizable", "Sort.Title")
    /// 更新日
    internal static let updateDate = L10n.tr("Localizable", "Sort.UpdateDate")
  }

  internal enum Account {
    /// アカウントID
    internal static let accountID = L10n.tr("Localizable", "account.accountID")
    /// 登録備末
    internal static let deviceRegister = L10n.tr("Localizable", "account.deviceRegister")
    /// ログイン
    internal static let login = L10n.tr("Localizable", "account.login")
    /// ログアウト
    internal static let logout = L10n.tr("Localizable", "account.logout")
    /// 今はログインしていない
    internal static let notLoginYet = L10n.tr("Localizable", "account.notLoginYet")
    /// バックアップ設定
    internal static let syncData = L10n.tr("Localizable", "account.syncData")
    /// アカウント
    internal static let title = L10n.tr("Localizable", "account.title")
    internal enum LogoutConfirmation {
      /// キャンセル
      internal static let cancel = L10n.tr("Localizable", "account.logoutConfirmation.cancel")
      /// ログアウトするとクラウドを利用できなくなります。
      internal static let message = L10n.tr("Localizable", "account.logoutConfirmation.message")
      /// OK
      internal static let ok = L10n.tr("Localizable", "account.logoutConfirmation.ok")
      /// ログアウトしますか？
      internal static let title = L10n.tr("Localizable", "account.logoutConfirmation.title")
    }
  }

  internal enum AccountInfo {
    internal enum Premium {
      /// Google Play決済
      internal static let android = L10n.tr("Localizable", "accountInfo.premium.android")
      /// iTunes Store決済
      internal static let apple = L10n.tr("Localizable", "accountInfo.premium.apple")
      /// gooストア決済
      internal static let other = L10n.tr("Localizable", "accountInfo.premium.other")
    }
  }

  internal enum Agreement {
    internal enum Confirm {
      /// 終了
      internal static let close = L10n.tr("Localizable", "agreement.confirm.close")
      /// %@ を終了してもいいですか？
      internal static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "agreement.confirm.message", String(describing: p1))
      }
      /// 戻る
      internal static let `return` = L10n.tr("Localizable", "agreement.confirm.return")
    }
    internal enum New {
      /// 続けるには利用規約をお読みの上、
      /// 同意いただく必要があります。
      internal static let message = L10n.tr("Localizable", "agreement.new.message")
      /// OK
      internal static let ok = L10n.tr("Localizable", "agreement.new.ok")
      /// 利用規約が変更されました
      internal static let title = L10n.tr("Localizable", "agreement.new.title")
    }
  }

  internal enum Alert {
    /// キャンセル
    internal static let cancel = L10n.tr("Localizable", "alert.cancel")
    /// いいえ
    internal static let no = L10n.tr("Localizable", "alert.no")
    /// OK
    internal static let ok = L10n.tr("Localizable", "alert.ok")
    /// 他の端末
    internal static let otherDevices = L10n.tr("Localizable", "alert.otherDevices")
    /// 使用中の端末
    internal static let thisDevices = L10n.tr("Localizable", "alert.thisDevices")
    /// Try Again
    internal static let tryAgain = L10n.tr("Localizable", "alert.tryAgain")
    /// はい
    internal static let yes = L10n.tr("Localizable", "alert.yes")
    internal enum Network {
      /// 通信状況を確認のうえ、再度実行してください。
      internal static let message = L10n.tr("Localizable", "alert.network.message")
      /// ネットワークエラー
      internal static let title = L10n.tr("Localizable", "alert.network.title")
    }
    internal enum Server {
      /// 通信状況を確認のうえ、再度実行してください。
      internal static let message = L10n.tr("Localizable", "alert.server.message")
      /// サーバーエラー
      internal static let title = L10n.tr("Localizable", "alert.server.title")
    }
  }

  internal enum Banner {
    /// 下に引っ張ると、一覧を更新できます。
    internal static let pullToRefresh = L10n.tr("Localizable", "banner.pullToRefresh")
    /// クラウドでは、自動保存のON/OFFを設定メニューで変更できます。
    /// OFFの間は、必ず手動で保存してください。
    internal static let saveCloudDraft = L10n.tr("Localizable", "banner.saveCloudDraft")
  }

  internal enum CreateFolder {
    internal enum Error {
      /// フォルダ名が重複しています。
      internal static let duplicate = L10n.tr("Localizable", "createFolder.error.duplicate")
      /// 上限1,000件に達したため、フォルダを作成できません。
      internal static let limit = L10n.tr("Localizable", "createFolder.error.limit")
      /// 上限1万件に達したため、フォルダを作成できません。
      internal static let limitPaid = L10n.tr("Localizable", "createFolder.error.limitPaid")
      /// メンテナンス中のため、クラウドにフォルダを作成できません。しばらく経ってからお試しください。  
      internal static let maintenance = L10n.tr("Localizable", "createFolder.error.maintenance")
      /// 端末の登録を解除しました。クラウドを利用する場合は再度端末登録を行ってください。
      internal static let unregisteredDevice = L10n.tr("Localizable", "createFolder.error.unregisteredDevice")
    }
  }

  internal enum Creation {
    /// 内容を保存せずに下書きを閉じますか？編集中の内容を残したい場合は「キャンセル」を選択して、下書きを別のアプリ等にコピーしてください。
    internal static let closeDraftWithoutSaving = L10n.tr("Localizable", "creation.closeDraftWithoutSaving")
    /// 上限5万字に達したため、貼り付ける文章を切り捨てました。
    internal static let overLenght = L10n.tr("Localizable", "creation.overLenght")
    /// 上限5万文字に達したため、文章を切り捨てました。
    internal static let overLenghtInput = L10n.tr("Localizable", "creation.overLenghtInput")
    /// 上限5万字を超えるため、置換できません。置換する言葉を短くしてください。
    internal static let overLenghtReplace = L10n.tr("Localizable", "creation.overLenghtReplace")
    /// 上限2千字に達したため、貼り付ける文章を切り捨てました。
    internal static let overTitleLenghtInput = L10n.tr("Localizable", "creation.overTitleLenghtInput")
    /// 言い換え
    internal static let paraphrase = L10n.tr("Localizable", "creation.paraphrase")
    /// 校正
    internal static let proofreading = L10n.tr("Localizable", "creation.proofreading")
    /// 保存
    internal static let save = L10n.tr("Localizable", "creation.save")
    /// 下書きを保存しました
    internal static let saveMessage = L10n.tr("Localizable", "creation.saveMessage")
    /// 字
    internal static let word = L10n.tr("Localizable", "creation.word")
    internal enum BarItem {
      /// 辞書
      internal static let dictionary = L10n.tr("Localizable", "creation.barItem.dictionary")
    }
    internal enum Error {
      /// メンテナンス中のため、クラウドへの保存ができません。この下書きは、端末の未分類フォルダに保存されます。
      internal static let authentication = L10n.tr("Localizable", "creation.error.authentication")
      /// この下書きは、他の端末で更新されました。
      /// 「他の端末」で更新した内容で上書きするか、「使用中の端末」の内容を残すかを選択してください。
      internal static let execution = L10n.tr("Localizable", "creation.error.execution")
      /// 選択したフォルダが削除されました。この下書きは、端末の未分類フォルダに保存されます。
      internal static let folderNotFound = L10n.tr("Localizable", "creation.error.folderNotFound")
      /// クラウドの下書きが、上限1,000件に達したため保存できません。この下書きは、端末の未分類フォルダに保存されます。
      internal static let limitation = L10n.tr("Localizable", "creation.error.limitation")
      /// クラウドの下書きが、上限1万件に達したため保存できません。この下書きは、端末の未分類フォルダに保存されます。
      internal static let limitationPaid = L10n.tr("Localizable", "creation.error.limitationPaid")
      /// メンテナンス中のため、クラウドへの保存ができません。この下書きは、端末の未分類フォルダに保存されます。
      internal static let maintenance = L10n.tr("Localizable", "creation.error.maintenance")
      /// クラウドの下書きが、上限1,000件に達したため移動できません。
      internal static let movelimit = L10n.tr("Localizable", "creation.error.movelimit")
      /// クラウドの下書きが、上限1万件に達したため移動できません。
      internal static let movelimitPaid = L10n.tr("Localizable", "creation.error.movelimitPaid")
      /// 通信状況を確認するか、しばらく経ってから再度お試しください。
      internal static let timeOut = L10n.tr("Localizable", "creation.error.timeOut")
      /// 端末の登録を解除しました。クラウドを利用する場合は再度端末登録を行ってください。この下書きは、端末の未分類フォルダに保存されます。
      internal static let unregisteredDevice = L10n.tr("Localizable", "creation.error.unregisteredDevice")
      internal enum Other {
        /// しばらく経ってから再度お試しください。解消しない場合は、エラーコードを添えてお問い合わせください。この下書きは、端末の未分類フォルダに保存されます。
        internal static let message = L10n.tr("Localizable", "creation.error.other.message")
        /// エラー：%@
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "creation.error.other.title", String(describing: p1))
        }
      }
    }
    internal enum Placeholder {
      /// 本文入力
      internal static let content = L10n.tr("Localizable", "creation.placeholder.content")
      /// 置換する言葉を入力
      internal static let replace = L10n.tr("Localizable", "creation.placeholder.replace")
      /// 検索する言葉を入力
      internal static let search = L10n.tr("Localizable", "creation.placeholder.search")
      /// タイトル入力
      internal static let title = L10n.tr("Localizable", "creation.placeholder.title")
    }
  }

  internal enum Dictionary {
    /// 辞書検索
    internal static let title = L10n.tr("Localizable", "dictionary.title")
    internal enum Result {
      /// goo辞書
      internal static let title = L10n.tr("Localizable", "dictionary.result.title")
    }
  }

  internal enum Draft {
    /// すべての下書き
    internal static let title = L10n.tr("Localizable", "draft.title")
    internal enum BarButtonItem {
      /// キャンセル
      internal static let cancel = L10n.tr("Localizable", "draft.barButtonItem.cancel")
      /// 削除
      internal static let delete = L10n.tr("Localizable", "draft.barButtonItem.delete")
      /// 選択解除
      internal static let deselectAll = L10n.tr("Localizable", "draft.barButtonItem.deselectAll")
      /// 編集
      internal static let edit = L10n.tr("Localizable", "draft.barButtonItem.edit")
      /// 移動...
      internal static let move = L10n.tr("Localizable", "draft.barButtonItem.move")
      /// 一括選択
      internal static let selectAll = L10n.tr("Localizable", "draft.barButtonItem.selectAll")
    }
    internal enum EditMode {
      /// %d件を選択
      internal static func title(_ p1: Int) -> String {
        return L10n.tr("Localizable", "draft.editMode.title", p1)
      }
    }
  }

  internal enum Drafts {
    internal enum Error {
      /// バックアップデータが見つかりません。
      internal static let backupNotFound = L10n.tr("Localizable", "drafts.error.backupNotFound")
      /// この下書きは削除されています。
      internal static let draftNotFound = L10n.tr("Localizable", "drafts.error.draftNotFound")
      /// 他の端末で並び替えが行われたため一覧を再読み込みします。
      internal static let exclusiveError = L10n.tr("Localizable", "drafts.error.exclusiveError")
      /// 選択したフォルダは削除されています。
      internal static let folderNotFound = L10n.tr("Localizable", "drafts.error.folderNotFound")
      /// メンテナンス中のため、クラウドを利用できません。しばらく経ってから再度お試しください。
      internal static let maintenance = L10n.tr("Localizable", "drafts.error.maintenance")
      /// メンテナンス中のため、クラウドでの編集ができません。 クラウドの下書きを端末に移動して、編集してください。
      internal static let maintenanceCannotUpdate = L10n.tr("Localizable", "drafts.error.maintenanceCannotUpdate")
      /// 端末の登録を解除しました。クラウドを利用する場合は再度端末登録を行ってください。
      internal static let unregisteredDevice = L10n.tr("Localizable", "drafts.error.unregisteredDevice")
      internal enum CreateDraft {
        /// メンテナンス中のため、クラウドに下書きを作成できません。しばらく経ってからお試しください。
        internal static let maintenance = L10n.tr("Localizable", "drafts.error.createDraft.maintenance")
      }
      internal enum Delete {
        /// メンテナンス中のため、クラウドの下書きを削除できません。しばらく経ってからお試しください。
        internal static let maintenance = L10n.tr("Localizable", "drafts.error.delete.maintenance")
      }
    }
  }

  internal enum DraftsAtHome {
    internal enum Error {
      /// メンテナンス中のため、クラウドでの編集ができません。 クラウドの下書きを端末に移動して、編集してください。
      internal static let maintenanceCannotUpdate = L10n.tr("Localizable", "draftsAtHome.error.maintenanceCannotUpdate")
    }
  }

  internal enum Error {
    /// 端末に問題が発生しました。
    internal static let otherErrorAtLocal = L10n.tr("Localizable", "error.otherErrorAtLocal")
  }

  internal enum ErrorDevice {
    internal enum Error {
      /// メンテナンス中のため、端末登録ができません。しばらく経ってから再度お試しください。
      internal static let maintenance = L10n.tr("Localizable", "errorDevice.error.maintenance")
    }
  }

  internal enum Folder {
    /// 新規フォルダを作成
    internal static let createFolder = L10n.tr("Localizable", "folder.createFolder")
    /// フォルダ名を入力してください。
    internal static let emptyName = L10n.tr("Localizable", "folder.emptyName")
    /// フォルダ名が重複しています。
    internal static let existName = L10n.tr("Localizable", "folder.existName")
    /// 新しいフォルダ
    internal static let placeholder = L10n.tr("Localizable", "folder.placeholder")
    /// 未分類
    internal static let uncategorized = L10n.tr("Localizable", "folder.uncategorized")
    internal enum Action {
      /// 削除
      internal static let delete = L10n.tr("Localizable", "folder.action.delete")
      /// 変更
      internal static let rename = L10n.tr("Localizable", "folder.action.rename")
    }
    internal enum Browser {
      /// フォルダ
      internal static let title = L10n.tr("Localizable", "folder.browser.title")
    }
    internal enum ConfirmationAlert {
      /// フォルダ内の下書きも削除されます。
      internal static let message = L10n.tr("Localizable", "folder.confirmationAlert.message")
      /// OK
      internal static let ok = L10n.tr("Localizable", "folder.confirmationAlert.ok")
      /// フォルダを削除しますか？
      internal static let title = L10n.tr("Localizable", "folder.confirmationAlert.title")
    }
    internal enum CreationAlert {
      /// キャンセル
      internal static let cancel = L10n.tr("Localizable", "folder.creationAlert.cancel")
      /// 名前を入力してください。
      internal static let message = L10n.tr("Localizable", "folder.creationAlert.message")
      /// 作成
      internal static let ok = L10n.tr("Localizable", "folder.creationAlert.ok")
      /// 新規フォルダ
      internal static let title = L10n.tr("Localizable", "folder.creationAlert.title")
    }
    internal enum RenameAlert {
      /// 名前を入力してください。
      internal static let message = L10n.tr("Localizable", "folder.renameAlert.message")
      /// 名前を変更
      internal static let ok = L10n.tr("Localizable", "folder.renameAlert.ok")
      /// フォルダ名の変更
      internal static let title = L10n.tr("Localizable", "folder.renameAlert.title")
    }
    internal enum Selection {
      /// キャンセル
      internal static let cancel = L10n.tr("Localizable", "folder.selection.cancel")
      /// ここに移動
      internal static let done = L10n.tr("Localizable", "folder.selection.done")
      /// 移動先を選択
      internal static let title = L10n.tr("Localizable", "folder.selection.title")
    }
  }

  internal enum FolderBrowser {
    internal enum Delete {
      internal enum Error {
        /// このフォルダは削除されています。
        internal static let folderNotFound = L10n.tr("Localizable", "folderBrowser.delete.error.folderNotFound")
        /// メンテナンス中のため、クラウドのフォルダを削除できません。しばらく経ってからお試しください。
        internal static let maintenance = L10n.tr("Localizable", "folderBrowser.delete.error.maintenance")
      }
    }
    internal enum Error {
      /// 他の端末で並び替えが行われたためフォルダ一覧を再読み込みします。
      internal static let exclusiveError = L10n.tr("Localizable", "folderBrowser.error.exclusiveError")
      /// メンテナンス中のため、クラウドを利用できません。しばらく経ってから再度お試しください。
      internal static let maintenance = L10n.tr("Localizable", "folderBrowser.error.maintenance")
      /// メンテナンス中のため、クラウドでの編集ができません。クラウドの下書きを端末に移動して、編集してください。
      internal static let maintenanceCannotUpdate = L10n.tr("Localizable", "folderBrowser.error.maintenanceCannotUpdate")
      /// 無課金による権限エラー
      internal static let receiptInvalid = L10n.tr("Localizable", "folderBrowser.error.receiptInvalid")
      /// 端末の登録を解除しました。クラウドを利用する場合は再度端末登録を行ってください。
      internal static let unregisteredDevice = L10n.tr("Localizable", "folderBrowser.error.unregisteredDevice")
    }
  }

  internal enum FolderSelection {
    internal enum Error {
      /// この下書きは削除されています。
      internal static let draftNotFound = L10n.tr("Localizable", "folderSelection.error.draftNotFound")
      /// このフォルダは削除されています。
      internal static let folderNotFound = L10n.tr("Localizable", "folderSelection.error.folderNotFound")
      /// メンテナンス中のため、移動した下書きはクラウドから削除されません。復旧後に削除してください。
      internal static let maintenanceCannotUpdate = L10n.tr("Localizable", "folderSelection.error.maintenanceCannotUpdate")
      internal enum Maintenance {
        /// メンテナンス中のため、クラウドへの移動ができません。しばらく経ってからお試しください。
        internal static let cannotMoveToCloudFolder = L10n.tr("Localizable", "folderSelection.error.maintenance.cannotMoveToCloudFolder")
        /// メンテナンス中のため、クラウドから下書きの移動ができません。しばらく経ってからお試しください。
        internal static let draftsCannotBeMovedFromCloud = L10n.tr("Localizable", "folderSelection.error.maintenance.draftsCannotBeMovedFromCloud")
      }
    }
  }

  internal enum Gatracking {
    /// screen_name
    internal static let screenName = L10n.tr("Localizable", "gatracking.screenName")
  }

  internal enum Home {
    internal enum Cell {
      /// 内容なし
      internal static let noContent = L10n.tr("Localizable", "home.cell.noContent")
      /// タイトルなし
      internal static let noTitle = L10n.tr("Localizable", "home.cell.noTitle")
    }
    internal enum Error {
      internal enum CreateDraft {
        /// メンテナンス中のため、クラウドに下書きを作成できません。しばらく経ってからお試しください。
        internal static let maintenance = L10n.tr("Localizable", "home.error.createDraft.maintenance")
      }
    }
    internal enum Selectdraft {
      /// 一括選択できるのは20件までです。
      internal static let over = L10n.tr("Localizable", "home.selectdraft.over")
    }
  }

  internal enum ListDevice {
    /// 登録解除した端末からは、クラウドにアクセスできなくなります。端末に残したい下書きは、あらかじめクラウドからその端末に移動してください。
    internal static let note = L10n.tr("Localizable", "listDevice.note")
  }

  internal enum ListDevivice {
    internal enum MessageError {
      /// ※同機種が登録されています。アプリを再インストールした場合は、「登録済の端末」から以前の登録を解除して、再度登録してください。
      internal static let install = L10n.tr("Localizable", "listDevivice.messageError.install")
    }
    internal enum Server {
      internal enum Error {
        /// メンテナンス中のため、クラウドを利用できません。
        /// 【端末登録済の方】 
        /// ログインすると、クラウドの下書きを閲覧できます。下書きを端末に保存すれば、更新できます。
        internal static let cannotBeUpdate = L10n.tr("Localizable", "listDevivice.server.error.cannotBeUpdate")
      }
    }
  }

  internal enum Login {
    /// Loading API List Devices
    internal static let loadingAPIListDevices = L10n.tr("Localizable", "login.loadingAPIListDevices")
    internal enum Server {
      internal enum Error {
        /// メンテナンス中のため、クラウドを利用できません。下書きの作成や更新は、端末上でのみ可能です。
        /// 【初めて利用する方】
        /// 「ログインしない」を選択してください。
        /// 【端末登録済の方】
        /// ログインすると、クラウドの下書きを閲覧できます。下書きを端末に保存すれば、更新できます。
        internal static let cannotBeUpdate = L10n.tr("Localizable", "login.server.error.cannotBeUpdate")
        /// メンテナンス中のため、クラウドが利用できません。しばらく経ってから再度お試しください。「ログインしない」を選択すると、その他の機能を利用できます。
        internal static let maintain = L10n.tr("Localizable", "login.server.error.maintain")
        /// しばらく経ってから再度お試しください。解消しない場合は、エラーコードを添えてお問い合わせください。
        internal static let other = L10n.tr("Localizable", "login.server.error.other")
        /// 通信状況を確認するか、しばらく経ってから再度お試しください。
        internal static let timeOut = L10n.tr("Localizable", "login.server.error.timeOut")
      }
    }
  }

  internal enum Menu {
    /// 取得できません
    internal static let cannotGetInfo = L10n.tr("Localizable", "menu.cannotGetInfo")
    /// 登録なし
    internal static let noAccount = L10n.tr("Localizable", "menu.noAccount")
    /// 登録済の端末
    internal static let registeredDevice = L10n.tr("Localizable", "menu.registeredDevice")
    /// goo辞書が作ったメモアプリ『%@』
    /// 
    /// 表現豊かな文章が作れて、語彙力アップ！
    /// ・書きながら辞書を調べられる
    /// ・誤りやすい日本語をチェックできる
    /// ・言い換え(類語)表現を教えてくれる
    /// 
    /// 【iPhone/Android版・無料】
    /// https://dictionary.goo.ne.jp/info/app/
    internal static func shareContent(_ p1: Any) -> String {
      return L10n.tr("Localizable", "menu.shareContent", String(describing: p1))
    }
    /// 未登録の端末
    internal static let unregisteredDevice = L10n.tr("Localizable", "menu.unregisteredDevice")
    internal enum Cell {
      /// プライバシーポリシー
      internal static let appPrivacyPolicy = L10n.tr("Localizable", "menu.cell.appPrivacyPolicy")
      /// 特定商取引法に基づく表示
      internal static let commercialTransactions = L10n.tr("Localizable", "menu.cell.commercialTransactions")
      /// ヘルプ
      internal static let help = L10n.tr("Localizable", "menu.cell.help")
      /// お知らせ
      internal static let notification = L10n.tr("Localizable", "menu.cell.notification")
      /// 公式Twitter
      internal static let openGooTwitter = L10n.tr("Localizable", "menu.cell.openGooTwitter")
      /// オープンライセンス
      internal static let openLicense = L10n.tr("Localizable", "menu.cell.openLicense")
      /// 個人情報の取り扱い
      internal static let personalInformation = L10n.tr("Localizable", "menu.cell.personalInformation")
      /// プライバシーポリシー
      internal static let privacyPolicy = L10n.tr("Localizable", "menu.cell.privacyPolicy")
      /// プレミアムプランのご紹介
      internal static let requestPremium = L10n.tr("Localizable", "menu.cell.requestPremium")
      /// 環境設定
      internal static let setting = L10n.tr("Localizable", "menu.cell.setting")
      /// 友達に紹介する
      internal static let share = L10n.tr("Localizable", "menu.cell.share")
      /// PC版のURLを送る
      internal static let shareChargePC = L10n.tr("Localizable", "menu.cell.shareChargePC")
      /// サービス利用規約
      internal static let terms = L10n.tr("Localizable", "menu.cell.terms")
      /// ゴミ箱
      internal static let trash = L10n.tr("Localizable", "menu.cell.trash")
      internal enum Item {
        /// 詳細検索
        internal static let detailedSearch = L10n.tr("Localizable", "menu.cell.item.detailedSearch")
        /// 広告なし
        internal static let noAds = L10n.tr("Localizable", "menu.cell.item.noAds")
        /// 初回なら1ヶ月無料
        internal static let oneMonthFreeFirstTime = L10n.tr("Localizable", "menu.cell.item.oneMonthFreeFirstTime")
        /// PC版
        internal static let pc = L10n.tr("Localizable", "menu.cell.item.pc")
        /// プレミアム限定
        internal static let premiumLimited = L10n.tr("Localizable", "menu.cell.item.premiumLimited")
        /// 置換機能
        internal static let replaceFunction = L10n.tr("Localizable", "menu.cell.item.replaceFunction")
      }
    }
    internal enum Error {
      internal enum DeviceStatus {
        /// メンテナンス中のため、端末登録状態を取得できません。
        internal static let maintenance = L10n.tr("Localizable", "menu.error.deviceStatus.maintenance")
      }
      internal enum Login {
        /// メンテナンス中のため、クラウドが利用できません。しばらく経ってから再度お試しください。
        internal static let maintenance = L10n.tr("Localizable", "menu.error.login.maintenance")
        /// メンテナンス中のため、クラウドを利用できません。
        /// 【端末登録済の方】
        ///  ログインすると、クラウドの下書きを閲覧できます。下書きを端末に保存すれば、更新できます。
        internal static let maintenanceCannotUpdate = L10n.tr("Localizable", "menu.error.login.maintenanceCannotUpdate")
      }
      internal enum RegisterDevice {
        /// メンテナンス中のため、端末登録ができません。しばらく経ってから再度お試しください。
        internal static let maintenance = L10n.tr("Localizable", "menu.error.registerDevice.maintenance")
      }
    }
    internal enum Note {
      /// PC版は、PCより下記にアクセスして「ログイン」からご利用ください。
      /// 
      internal static let premium = L10n.tr("Localizable", "menu.note.premium")
      internal enum Premium {
        /// https://dictionary.goo.ne.jp/info/app/
        internal static let link = L10n.tr("Localizable", "menu.note.premium.link")
      }
    }
    internal enum Share {
      internal enum Charge {
        /// PC版（有料）は、PCより下記にアクセスして「ログイン」からご利用ください。
        /// https://dictionary.goo.ne.jp/info/app/
        internal static let pc = L10n.tr("Localizable", "menu.share.charge.PC")
      }
    }
  }

  internal enum Premium {
    /// Google Play
    internal static let android = L10n.tr("Localizable", "premium.android")
    /// iTunes Store
    internal static let apple = L10n.tr("Localizable", "premium.apple")
    /// ログインしてプレミアムに登録
    internal static let login = L10n.tr("Localizable", "premium.login")
    /// ・プレミアムプランの登録には、gooIDログイン（登録無料）が必要です。gooIDとは、gooで提供する各種サービスをご利用いただくためのIDです。
    /// ・プレミアムプランは、1ヶ月単位のサブスクリプションサービスです。更新日の24時間前までに解約されなかった場合、登録が自動更新され、月額料金480円（税込）が発生いたします。
    /// ・初めてプレミアムプランに登録する場合、決済は登録後すぐには行われず、無料体験期間が終了すると自動的に行われます。
    /// ・登録はいつでも解除できます。端末の「設定」→「Apple ID」→「サブスクリプション」から手続きしてください。料金や更新日も「サブスクリプション」で確認できます。
    /// ・PC版は、PCより
    ///「https://dictionary.goo.ne.jp/info/app/」にアクセスし、「ログイン」からご利用ください。
    /// 
    internal static let note = L10n.tr("Localizable", "premium.note")
    /// ・PC版の動作保証環境は、下記となります。
    /// 　【OS】Windows10、Windows11、macOS Big Sur、macOS Monterey
    /// 　【ブラウザ】Google Chrome 最新版、Safari 最新版（macOSのみ）
    internal static let note2 = L10n.tr("Localizable", "premium.note2")
    /// 登録する
    internal static let register = L10n.tr("Localizable", "premium.register")
    internal enum Cancel {
      /// プレミアム登録の解除
      internal static let subcription = L10n.tr("Localizable", "premium.cancel.subcription")
    }
    internal enum Message {
      /// プレミアムプランの登録には、gooIDログインが必要です。gooIDは無料で作成できます。
      internal static let alertLoginScreen = L10n.tr("Localizable", "premium.message.alertLoginScreen")
      /// %@決済でプレミアム登録済です。アプリを再起動し、プレミアムをご利用ください。
      internal static func alreadyRegistered(_ p1: Any) -> String {
        return L10n.tr("Localizable", "premium.message.alreadyRegistered", String(describing: p1))
      }
      /// プレミアム登録が完了しました。他の端末でもご利用いただいている場合は、アプリを再起動すると、その端末でもプレミアムをご利用いただけるようになります。
      internal static let success = L10n.tr("Localizable", "premium.message.success")
    }
    internal enum Receipt {
      /// 処理を完了できませんでした。再度お試しください。
      internal static let invalid = L10n.tr("Localizable", "premium.receipt.invalid")
      internal enum Err {
        internal enum _400 {
          /// 課金情報の登録処理中にエラーが発生しました。「以前の購入を復元」を選択し、再度登録してください。
          internal static let message = L10n.tr("Localizable", "premium.receipt.err.400.message")
        }
        internal enum _409 {
          /// プレミアム登録済です。登録時のgooIDでログインし、「以前の購入を復元」を再度お試しください。
          internal static let message = L10n.tr("Localizable", "premium.receipt.err.409.message")
        }
        internal enum _410 {
          /// 別のApple IDでプレミアム登録済の可能性があります。登録時のApple IDでログインし、プレミアムがご利用いただけるかお試しください。
          internal static let message = L10n.tr("Localizable", "premium.receipt.err.410.message")
        }
        internal enum _500 {
          /// システムエラーが発生しました
          internal static let message = L10n.tr("Localizable", "premium.receipt.err.500.message")
        }
      }
    }
  }

  internal enum Reference {
    /// すべてコピー
    internal static let copyAll = L10n.tr("Localizable", "reference.copyAll")
    internal enum Placeholder {
      /// 内容なし
      internal static let content = L10n.tr("Localizable", "reference.placeholder.content")
      /// タイトルなし
      internal static let title = L10n.tr("Localizable", "reference.placeholder.title")
    }
  }

  internal enum RegisterDevices {
    /// クラウドを利用する端末を登録します。最大2台の端末で利用できます。
    internal static let limitDevices = L10n.tr("Localizable", "registerDevices.limitDevices")
    /// 登録済の端末が3台以上あります。この端末を登録するには、合計2台になるまで解除してください。
    internal static let registergreaterthantwodevice = L10n.tr("Localizable", "registerDevices.registergreaterthantwodevice")
    /// 登録済の端末が2台あります。この端末を登録するには、1台を解除してください。
    internal static let registertwodevice = L10n.tr("Localizable", "registerDevices.registertwodevice")
    /// クラウドを利用する端末を登録します。端末台数は無制限でご利用いただけます。
    internal static let subscribed = L10n.tr("Localizable", "registerDevices.subscribed")
    internal enum Alert {
      /// は解除されました。
      internal static let releaseDevice = L10n.tr("Localizable", "registerDevices.alert.releaseDevice")
    }
  }

  internal enum RenameFolder {
    internal enum Error {
      /// メンテナンス中のため、フォルダ名の変更ができません。しばらく経ってからお試しください。
      internal static let maintenance = L10n.tr("Localizable", "renameFolder.error.maintenance")
    }
  }

  internal enum ScreenName {
    /// 移動先選択画面
    internal static let screenCloudFolderSelection = L10n.tr("Localizable", "screenName.screenCloudFolderSelection")
    /// 下書き画面
    internal static let screenDraft = L10n.tr("Localizable", "screenName.screenDraft")
    /// フォルダ画面
    internal static let screenFolder = L10n.tr("Localizable", "screenName.screenFolder")
    /// 強制ログアウト画面
    internal static let screenForceLogout = L10n.tr("Localizable", "screenName.screenForceLogout")
    /// ログイン選択画面
    internal static let screenLogin = L10n.tr("Localizable", "screenName.screenLogin")
    /// メニュー画面
    internal static let screenMenu = L10n.tr("Localizable", "screenName.screenMenu")
    /// 端末登録画面
    internal static let screenRegister = L10n.tr("Localizable", "screenName.screenRegister")
  }

  internal enum Sdk {
    internal enum Error {
      internal enum Refresh {
        /// 認証情報を更新できませんでした。再度ログインしてください。
        internal static let session = L10n.tr("Localizable", "sdk.error.refresh.session")
      }
    }
  }

  internal enum Server {
    internal enum Error {
      /// 通信状況を確認するか、しばらく経ってから再度お試しください。
      internal static let timeOut = L10n.tr("Localizable", "server.error.timeOut")
      /// 端末の登録を解除しました。クラウドを利用する場合は再度端末登録を行ってください。
      internal static let unregisteredDevice = L10n.tr("Localizable", "server.error.unregisteredDevice")
      internal enum Other {
        /// お問い合わせ
        internal static let hyperlink = L10n.tr("Localizable", "server.error.other.hyperlink")
        /// しばらく経ってから再度お試しください。解消しない場合は、エラーコードを添えてお問い合わせください。
        internal static let message = L10n.tr("Localizable", "server.error.other.message")
        /// エラー：%@
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "server.error.other.title", String(describing: p1))
        }
      }
      internal enum Title {
        /// 認証エラー
        internal static let authenticationError = L10n.tr("Localizable", "server.error.title.authenticationError")
        /// バックアップが存在しない
        internal static let backupNotFound = L10n.tr("Localizable", "server.error.title.backupNotFound")
        /// 下書きが存在しない
        internal static let draftNotFound = L10n.tr("Localizable", "server.error.title.draftNotFound")
        /// フォルダ名重複エラー
        internal static let duplicateFolder = L10n.tr("Localizable", "server.error.title.duplicateFolder")
        /// 下書き登録排他エラー
        internal static let executionError = L10n.tr("Localizable", "server.error.title.executionError")
        /// フォルダが存在しない
        internal static let folderNotFound = L10n.tr("Localizable", "server.error.title.folderNotFound")
        /// 下書き登録数上限エラー
        internal static let limitDraftRegistrtion = L10n.tr("Localizable", "server.error.title.limitDraftRegistrtion")
        /// メンテナンス中（参照、更新共に不可
        internal static let maintenance = L10n.tr("Localizable", "server.error.title.maintenance")
        /// メンテナンス中（参照、更新共に不可
        internal static let maintenanceCannotUpdate = L10n.tr("Localizable", "server.error.title.maintenanceCannotUpdate")
        /// その他エラー
        internal static let otherError = L10n.tr("Localizable", "server.error.title.otherError")
        /// セッションタイムアウトエラー
        internal static let sessionTimeOut = L10n.tr("Localizable", "server.error.title.sessionTimeOut")
        /// 端末登録エラー（自端末が登録されていない)
        internal static let terminalRegistration = L10n.tr("Localizable", "server.error.title.terminalRegistration")
      }
    }
  }

  internal enum Suggestion {
    /// 言い換え候補は ありません
    internal static let empty = L10n.tr("Localizable", "suggestion.empty")
    /// 候補はありません。
    /// 誤りやすい言葉・言い回しを
    /// 検索しました。
    internal static let idiomEmpty = L10n.tr("Localizable", "suggestion.idiomEmpty")
    /// 候補はありません。
    /// よく使われる言い換え・類語を
    /// 検索しました。
    internal static let thesaurus = L10n.tr("Localizable", "suggestion.thesaurus")
    internal enum Detail {
      /// goo辞書
      internal static let title = L10n.tr("Localizable", "suggestion.detail.title")
    }
    internal enum Feedback {
      /// フィードバック
      internal static let title = L10n.tr("Localizable", "suggestion.feedback.title")
    }
  }

  internal enum Tracking {
    internal enum DisplayMode {
      /// ダーク
      internal static let dark = L10n.tr("Localizable", "tracking.displayMode.dark")
      /// ライト
      internal static let light = L10n.tr("Localizable", "tracking.displayMode.light")
    }
  }

  internal enum Trash {
    /// ゴミ箱は空です。
    internal static let noData = L10n.tr("Localizable", "trash.noData")
    /// ゴミ箱
    internal static let title = L10n.tr("Localizable", "trash.title")
    internal enum Action {
      /// 戻す
      internal static let pushBack = L10n.tr("Localizable", "trash.action.pushBack")
    }
    internal enum Deletion {
      /// 下書きを削除しますか？
      /// 下書きは完全に削除され、復元はできません。
      internal static let message = L10n.tr("Localizable", "trash.deletion.message")
    }
    internal enum DeletionAll {
      /// キャンセル
      internal static let cancel = L10n.tr("Localizable", "trash.deletionAll.cancel")
      /// ゴミ箱を空にします。よろしいですか？
      internal static let message = L10n.tr("Localizable", "trash.deletionAll.message")
      /// OK
      internal static let ok = L10n.tr("Localizable", "trash.deletionAll.ok")
    }
  }

  internal enum Tutorial {
    /// 次へ
    internal static let next = L10n.tr("Localizable", "tutorial.next")
    /// スキップ
    internal static let skip = L10n.tr("Localizable", "tutorial.skip")
    /// はじめる
    internal static let start = L10n.tr("Localizable", "tutorial.start")
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
