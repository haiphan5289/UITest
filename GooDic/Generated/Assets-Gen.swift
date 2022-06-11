// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal static let icLogin = ImageAsset(name: "ic_login")
  internal static let icLogout = ImageAsset(name: "ic_logout")
  internal static let icMobilePlus = ImageAsset(name: "ic_mobile_plus")
  internal static let icDeleteAdvancedictionary = ImageAsset(name: "ic_delete_advancedictionary")
  internal static let icSearchAdvancedictionary = ImageAsset(name: "ic_search_advancedictionary")
  internal static let _007AffA7Ccf5 = ColorAsset(name: "007AFF&A7CCF5")
  internal static let _111111Ffffff = ColorAsset(name: "111111&FFFFFF")
  internal static let _1979Ff = ColorAsset(name: "1979FF")
  internal static let _4C4C4C = ColorAsset(name: "4C4C4C")
  internal static let _6666669B9B9B = ColorAsset(name: "666666&&9B9B9B")
  internal static let _666666Cfcfcf = ColorAsset(name: "666666&CFCFCF")
  internal static let _717171 = ColorAsset(name: "717171")
  internal static let _9B9B9BAdadad = ColorAsset(name: "9B9B9B&ADADAD")
  internal static let accountBg = ColorAsset(name: "AccountBg")
  internal static let background = ColorAsset(name: "Background")
  internal static let backgroundRegisterPremium = ColorAsset(name: "BackgroundRegisterPremium")
  internal static let bannerBg = ColorAsset(name: "BannerBg")
  internal static let bannerText = ColorAsset(name: "BannerText")
  internal static let bgGooDID = ColorAsset(name: "BgGooDID")
  internal static let blueBanner = ColorAsset(name: "BlueBanner")
  internal static let blueHighlight = ColorAsset(name: "BlueHighlight")
  internal static let blueLink = ColorAsset(name: "BlueLink")
  internal static let borderButtonDoNotRegister = ColorAsset(name: "BorderButtonDoNotRegister")
  internal static let borderButtonListDevice = ColorAsset(name: "BorderButtonListDevice")
  internal static let buttonDonotSelect = ColorAsset(name: "ButtonDonotSelect")
  internal static let buttonNotRegister = ColorAsset(name: "ButtonNotRegister")
  internal static let c555555 = ColorAsset(name: "C555555")
  internal static let cc3333 = ColorAsset(name: "CC3333")
  internal static let cecece111111 = ColorAsset(name: "CECECE&111111")
  internal static let cecece464646 = ColorAsset(name: "CECECE&464646")
  internal static let cecece555555 = ColorAsset(name: "CECECE&555555")
  internal static let cecece666666206 = ColorAsset(name: "CECECE&666666-206")
  internal static let cecece666666 = ColorAsset(name: "CECECE&666666")
  internal static let cecece717171 = ColorAsset(name: "CECECE&717171")
  internal static let cececeCc3333 = ColorAsset(name: "CECECE&CC3333")
  internal static let cececeCfcfcf = ColorAsset(name: "CECECE&CFCFCF")
  internal static let cececeClear = ColorAsset(name: "CECECE&Clear")
  internal static let cececeFfffff = ColorAsset(name: "CECECE&FFFFFF")
  internal static let cecece = ColorAsset(name: "CECECE")
  internal static let cancel = ColorAsset(name: "Cancel")
  internal static let cellBackground = ColorAsset(name: "CellBackground")
  internal static let cellPayBG = ColorAsset(name: "CellPayBG")
  internal static let cellSeparator = ColorAsset(name: "CellSeparator")
  internal static let clean464646 = ColorAsset(name: "Clean&464646")
  internal static let d6D6D6555555 = ColorAsset(name: "D6D6D6&555555")
  internal static let deletionAction = ColorAsset(name: "DeletionAction")
  internal static let dictCellSeparator = ColorAsset(name: "DictCellSeparator")
  internal static let disableSort = ColorAsset(name: "DisableSort")
  internal static let e0E0E0111111 = ColorAsset(name: "E0E0E0&111111")
  internal static let e3E3E3111111 = ColorAsset(name: "E3E3E3&111111")
  internal static let e3E3E3464646 = ColorAsset(name: "E3E3E3&464646")
  internal static let e3E3E3666666E3 = ColorAsset(name: "E3E3E3&666666-E3")
  internal static let e3E3E3666666 = ColorAsset(name: "E3E3E3&666666")
  internal static let e3E3E3Clear = ColorAsset(name: "E3E3E3&Clear")
  internal static let ec8383 = ColorAsset(name: "EC8383")
  internal static let eeeeee717171 = ColorAsset(name: "EEEEEE&717171")
  internal static let eeeeee7171712 = ColorAsset(name: "EEEEEE&7171712")
  internal static let eeeeee = ColorAsset(name: "EEEEEE")
  internal static let f2F2F2121212 = ColorAsset(name: "F2F2F2&121212")
  internal static let f2F2F2464646 = ColorAsset(name: "F2F2F2&464646")
  internal static let f5F5F52E2E2E = ColorAsset(name: "F5F5F5&2E2E2E")
  internal static let f6Eceb = ColorAsset(name: "F6ECEB")
  internal static let ffffff121212 = ColorAsset(name: "FFFFFF&121212")
  internal static let ffffff333333 = ColorAsset(name: "FFFFFF&333333")
  internal static let ffffff464646 = ColorAsset(name: "FFFFFF&464646")
  internal static let ffffff555555 = ColorAsset(name: "FFFFFF&555555")
  internal static let fontSlider = ColorAsset(name: "FontSlider")
  internal static let fontSliderText = ColorAsset(name: "FontSliderText")
  internal static let highlight = ColorAsset(name: "Highlight")
  internal static let indicatorShadow = ColorAsset(name: "IndicatorShadow")
  internal static let lineListDevice = ColorAsset(name: "LineListDevice")
  internal static let menuBg = ColorAsset(name: "MenuBg")
  internal static let modelBackground = ColorAsset(name: "ModelBackground")
  internal static let modelCellSeparator = ColorAsset(name: "ModelCellSeparator")
  internal static let namingPlaceholder = ColorAsset(name: "NamingPlaceholder")
  internal static let namingTextFieldBg = ColorAsset(name: "NamingTextFieldBg")
  internal static let naviBarBgModel = ColorAsset(name: "NaviBarBgModel")
  internal static let naviBarShadow = ColorAsset(name: "NaviBarShadow")
  internal static let noData = ColorAsset(name: "NoData")
  internal static let normalRow = ColorAsset(name: "NormalRow")
  internal static let progressSuccessText = ColorAsset(name: "ProgressSuccessText")
  internal static let pushBackAction = ColorAsset(name: "PushBackAction")
  internal static let searchBarBg = ColorAsset(name: "SearchBarBg")
  internal static let searchBarBorder = ColorAsset(name: "SearchBarBorder")
  internal static let searchBarMarkedText = ColorAsset(name: "SearchBarMarkedText")
  internal static let searchBarText = ColorAsset(name: "SearchBarText")
  internal static let searchViewBackground = ColorAsset(name: "SearchViewBackground")
  internal static let segmentedColor = ColorAsset(name: "SegmentedColor")
  internal static let selectionDevice = ColorAsset(name: "SelectionDevice")
  internal static let selectionSecondary = ColorAsset(name: "SelectionSecondary")
  internal static let seletedRow = ColorAsset(name: "SeletedRow")
  internal static let separator = ColorAsset(name: "Separator")
  internal static let shadow = ColorAsset(name: "Shadow")
  internal static let suggestionBg = ColorAsset(name: "SuggestionBg")
  internal static let suggestionButtonBg = ColorAsset(name: "SuggestionButtonBg")
  internal static let suggestionButtonText = ColorAsset(name: "SuggestionButtonText")
  internal static let suggestionTagBg = ColorAsset(name: "SuggestionTagBg")
  internal static let suggestionTagBorder = ColorAsset(name: "SuggestionTagBorder")
  internal static let tag = ColorAsset(name: "Tag")
  internal static let textBillingFree = ColorAsset(name: "TextBillingFree")
  internal static let textButtonDoNotRegister = ColorAsset(name: "TextButtonDoNotRegister")
  internal static let textButtonNotRegister = ColorAsset(name: "TextButtonNotRegister")
  internal static let textColorButtonRemoveSelection = ColorAsset(name: "TextColorButtonRemoveSelection")
  internal static let textColorTime = ColorAsset(name: "TextColorTime")
  internal static let textFontSelect = ColorAsset(name: "TextFontSelect")
  internal static let textFontUnselect = ColorAsset(name: "TextFontUnselect")
  internal static let textGreyDisable = ColorAsset(name: "TextGreyDisable")
  internal static let textHighlight = ColorAsset(name: "TextHighlight")
  internal static let textHighlightRevert = ColorAsset(name: "TextHighlightRevert")
  internal static let textModelName = ColorAsset(name: "TextModelName")
  internal static let textNote = ColorAsset(name: "TextNote")
  internal static let textPlaceholder = ColorAsset(name: "TextPlaceholder")
  internal static let textPrimary = ColorAsset(name: "TextPrimary")
  internal static let textRegister = ColorAsset(name: "TextRegister")
  internal static let textRemove = ColorAsset(name: "TextRemove")
  internal static let textRemoveDevice = ColorAsset(name: "TextRemoveDevice")
  internal static let textRemoveDeviceUpdate = ColorAsset(name: "TextRemoveDeviceUpdate")
  internal static let textReplace = ColorAsset(name: "TextReplace")
  internal static let textSearch = ColorAsset(name: "TextSearch")
  internal static let textSecondary = ColorAsset(name: "TextSecondary")
  internal static let textTertiary = ColorAsset(name: "TextTertiary")
  internal static let titleListDevice = ColorAsset(name: "TitleListDevice")
  internal static let toastColor = ColorAsset(name: "ToastColor")
  internal static let trashFill = ColorAsset(name: "TrashFill")
  internal static let undoBgDisable = ColorAsset(name: "UndoBgDisable")
  internal static let undoBgEnable = ColorAsset(name: "UndoBgEnable")
  internal static let viewLineHeaderSettingFont = ColorAsset(name: "ViewLineHeaderSettingFont")
  internal static let viewLineSettingFont = ColorAsset(name: "ViewLineSettingFont")
  internal static let _000000Ffffff = ColorAsset(name: "_000000&FFFFFF")
  internal static let _111111 = ColorAsset(name: "_111111")
  internal static let white111111 = ColorAsset(name: "white&111111")
  internal static let icDeleteCreation = ImageAsset(name: "ic_delete_creation")
  internal static let icFilterCreation = ImageAsset(name: "ic_filter_creation")
  internal static let icNextSearchOff = ImageAsset(name: "ic_next_search_off")
  internal static let icNextSearchOn = ImageAsset(name: "ic_next_search_on")
  internal static let icPreviousSearchOff = ImageAsset(name: "ic_previous_search_off")
  internal static let icPreviousSearchOn = ImageAsset(name: "ic_previous_search_on")
  internal static let icReplacementCreation = ImageAsset(name: "ic_replacement_creation")
  internal static let icSearchCreation = ImageAsset(name: "ic_search_creation")
  internal static let icSearchHeader = ImageAsset(name: "ic_search_header")
  internal static let icSettingHeader = ImageAsset(name: "ic_setting_header")
  internal static let icInstepDialog = ImageAsset(name: "ic_instep_dialog")
  internal static let icSort = ImageAsset(name: "ic_sort")
  internal static let icSortCheckNew = ImageAsset(name: "ic_sort_check_new")
  internal static let icSortDone = ImageAsset(name: "ic_sort_done")
  internal static let imgBannerDraftSort = ImageAsset(name: "img_banner_draft_sort")
  internal static let imgSortManual = ImageAsset(name: "img_sort_manual")
  internal static let imgSortPaid = ImageAsset(name: "img_sort_paid")
  internal static let imgForceLogout = ImageAsset(name: "img_ForceLogout")
  internal static let imgCloudLogout = ImageAsset(name: "img_cloud_logout")
  internal static let icDeletionAction = ImageAsset(name: "ic_deletionAction")
  internal static let icLink = ImageAsset(name: "ic_link")
  internal static let icMoveAction = ImageAsset(name: "ic_moveAction")
  internal static let icRenameAction = ImageAsset(name: "ic_renameAction")
  internal static let icAddDraft = ImageAsset(name: "ic_addDraft")
  internal static let icAddFolder = ImageAsset(name: "ic_addFolder")
  internal static let cloud = ImageAsset(name: "cloud")
  internal static let icAddNewFolder = ImageAsset(name: "ic_addNewFolder")
  internal static let icCloudFolder = ImageAsset(name: "ic_cloudFolder")
  internal static let icLocalFolder = ImageAsset(name: "ic_localFolder")
  internal static let icOsCloudFolder = ImageAsset(name: "ic_osCloudFolder")
  internal static let icOsLocalFolder = ImageAsset(name: "ic_osLocalFolder")
  internal static let icBack = ImageAsset(name: "ic_back")
  internal static let icClose = ImageAsset(name: "ic_close")
  internal static let icDelete = ImageAsset(name: "ic_delete")
  internal static let icDismiss = ImageAsset(name: "ic_dismiss")
  internal static let icNextA = ImageAsset(name: "ic_next_A")
  internal static let icNextB = ImageAsset(name: "ic_next_B")
  internal static let icPreviousA = ImageAsset(name: "ic_previous_A")
  internal static let icPreviousB = ImageAsset(name: "ic_previous_B")
  internal static let icRedoA = ImageAsset(name: "ic_redo_A")
  internal static let icRedoB = ImageAsset(name: "ic_redo_B")
  internal static let icUndoA = ImageAsset(name: "ic_undo_A")
  internal static let icUndoB = ImageAsset(name: "ic_undo_B")
  internal static let icRadioBlueOff = ImageAsset(name: "ic_radio_blue_off")
  internal static let icRadioBlueOn = ImageAsset(name: "ic_radio_blue_on")
  internal static let icRadioRedOff = ImageAsset(name: "ic_radio_red_off")
  internal static let icRadioRedOn = ImageAsset(name: "ic_radio_red_on")
  internal static let icAA = ImageAsset(name: "ic_AA")
  internal static let icArrow = ImageAsset(name: "ic_arrow")
  internal static let icChanged = ImageAsset(name: "ic_changed")
  internal static let icCloseWhite = ImageAsset(name: "ic_close_white")
  internal static let icDictSearch = ImageAsset(name: "ic_dictSearch")
  internal static let icFeedback = ImageAsset(name: "ic_feedback")
  internal static let icInfo = ImageAsset(name: "ic_info")
  internal static let icKeyboardA = ImageAsset(name: "ic_keyboard_A")
  internal static let icKeyboardB = ImageAsset(name: "ic_keyboard_B")
  internal static let icSearch = ImageAsset(name: "ic_search")
  internal static let icDevice = ImageAsset(name: "ic_device")
  internal static let icDeviceNow = ImageAsset(name: "ic_device_now")
  internal static let icPc = ImageAsset(name: "ic_pc")
  internal static let icAppPrivacy = ImageAsset(name: "ic_appPrivacy")
  internal static let icArrowMenuCell = ImageAsset(name: "ic_arrow_menu_cell")
  internal static let icArrowPremium = ImageAsset(name: "ic_arrow_premium")
  internal static let icCloseToast = ImageAsset(name: "ic_close_toast")
  internal static let icCommercial = ImageAsset(name: "ic_commercial")
  internal static let icFriends = ImageAsset(name: "ic_friends")
  internal static let icHelp = ImageAsset(name: "ic_help")
  internal static let icLicense = ImageAsset(name: "ic_license")
  internal static let icMenuPremium = ImageAsset(name: "ic_menu_premium")
  internal static let icNotifi = ImageAsset(name: "ic_notifi")
  internal static let icPersonal = ImageAsset(name: "ic_personal")
  internal static let icPremium = ImageAsset(name: "ic_premium")
  internal static let icPremiumGrey = ImageAsset(name: "ic_premium_grey")
  internal static let icPrivacy = ImageAsset(name: "ic_privacy")
  internal static let icSetting = ImageAsset(name: "ic_setting")
  internal static let icSns = ImageAsset(name: "ic_sns")
  internal static let icTerm = ImageAsset(name: "ic_term")
  internal static let icTrash = ImageAsset(name: "ic_trash")
  internal static let imgAd = ImageAsset(name: "img_ad")
  internal static let imgDictionary = ImageAsset(name: "img_dictionary")
  internal static let imgPc = ImageAsset(name: "img_pc")
  internal static let imgReplace = ImageAsset(name: "img_replace")
  internal static let icArrowBackFont = ImageAsset(name: "ic_arrow_back_font")
  internal static let icArrowBackup = ImageAsset(name: "ic_arrow_backup")
  internal static let icMinusActive = ImageAsset(name: "ic_minus_active")
  internal static let icMinusInactive = ImageAsset(name: "ic_minus_inactive")
  internal static let icPlusActive = ImageAsset(name: "ic_plus_active")
  internal static let icPlusInactive = ImageAsset(name: "ic_plus_inactive")
  internal static let icShare = ImageAsset(name: "ic_share")
  internal static let icShareCreation = ImageAsset(name: "ic_share_creation")
  internal static let icCheckSearch = ImageAsset(name: "ic_check_search")
  internal static let icPremiumGraySearch = ImageAsset(name: "ic_premium_gray_search")
  internal static let icPremiumSearch = ImageAsset(name: "ic_premium_search")
  internal static let icArrowAscending = ImageAsset(name: "ic_arrow_ascending")
  internal static let icArrowDescending = ImageAsset(name: "ic_arrow_descending")
  internal static let imgCreatedateAscending = ImageAsset(name: "img_createdate_ascending")
  internal static let imgCreatedateDescending = ImageAsset(name: "img_createdate_descending")
  internal static let imgTittleAscending = ImageAsset(name: "img_tittle_ascending")
  internal static let imgTittleDescending = ImageAsset(name: "img_tittle_descending")
  internal static let imgUpdatedateAscending = ImageAsset(name: "img_updatedate_ascending")
  internal static let imgUpdatedateDescending = ImageAsset(name: "img_updatedate_descending")
  internal static let tabBarBg = ImageAsset(name: "TabBarBg")
  internal static let icTab01A = ImageAsset(name: "ic_tab_01A")
  internal static let icTab01B = ImageAsset(name: "ic_tab_01B")
  internal static let icTab02A = ImageAsset(name: "ic_tab_02A")
  internal static let icTab02B = ImageAsset(name: "ic_tab_02B")
  internal static let icTab03A = ImageAsset(name: "ic_tab_03A")
  internal static let icTab03B = ImageAsset(name: "ic_tab_03B")
  internal static let icTabFolder = ImageAsset(name: "ic_tab_folder")
  internal static let icTabSelectedFolder = ImageAsset(name: "ic_tab_selectedFolder")
  internal static let imgLogo = ImageAsset(name: "img_logo")
  internal static let imgLogoNew = ImageAsset(name: "img_logo_new")
  internal static let imgTutoCheck = ImageAsset(name: "img_tutoCheck")
  internal static let imgTutoCreation = ImageAsset(name: "img_tutoCreation")
  internal static let imgTutoDraft = ImageAsset(name: "img_tutoDraft")
  internal static let imgTutoEdit = ImageAsset(name: "img_tutoEdit")
  internal static let imgTutoFolder = ImageAsset(name: "img_tutoFolder")
  internal static let imgTutoTrash = ImageAsset(name: "img_tutoTrash")
  internal static let tutoIllus = ImageAsset(name: "tuto_illus")
  internal static let tutoIllusNew = ImageAsset(name: "tuto_illus_new")
  internal static let iTunesArtwork = ImageAsset(name: "iTunesArtwork")
  internal static let icArrowRed = ImageAsset(name: "ic_arrow_red")
  internal static let icCheck = ImageAsset(name: "ic_check")
  internal static let imgChecked = ImageAsset(name: "img_checked")
  internal static let imgCloudEmpty = ImageAsset(name: "img_cloud_empty")
  internal static let imgCloudEmptyFolder = ImageAsset(name: "img_cloud_empty_folder")
  internal static let imgDictSearch = ImageAsset(name: "img_dictSearch")
  internal static let imgEmpty01 = ImageAsset(name: "img_empty_01")
  internal static let imgEmpty02 = ImageAsset(name: "img_empty_02")
  internal static let imgEmptyInFolder = ImageAsset(name: "img_empty_in_folder")
  internal static let imgEmptyInUncategory = ImageAsset(name: "img_empty_in_uncategory")
  internal static let imgGooLogo = ImageAsset(name: "img_gooLogo")
  internal static let imgPremium = ImageAsset(name: "img_premium")
  internal static let imgProgress = ImageAsset(name: "img_progress")
  internal static let imgShouldBe = ImageAsset(name: "img_shouldBe")
  internal static let imgSplash1 = ImageAsset(name: "img_splash_1")
  internal static let imgSplash2 = ImageAsset(name: "img_splash_2")
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal final class ColorAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  internal private(set) lazy var color: Color = Color(asset: self)

  #if os(iOS) || os(tvOS)
  @available(iOS 11.0, tvOS 11.0, *)
  internal func color(compatibleWith traitCollection: UITraitCollection) -> Color {
    let bundle = BundleToken.bundle
    guard let color = Color(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

internal extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init!(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if os(iOS) || os(tvOS)
  @available(iOS 8.0, tvOS 9.0, *)
  internal func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif
}

internal extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init!(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
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
