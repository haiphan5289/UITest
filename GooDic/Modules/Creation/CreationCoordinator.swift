//
//  CreationCoordinator.swift
//  GooDic
//
//  Created by ttvu on 5/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

typealias CreationAlertNaviProtocol = CreationNavigateProtocol & AlertNavigatorProtocol

protocol CreationNavigateProtocol: ErrorMessageProtocol, AppManagerProtocol {
    func dismiss()
    func dismissSuggestionView()
    func toSuggestionView(title: String, titleData: GDData, contentData: GDData, sceneType: GATracking.Scene) -> Driver<SuggestionDelegate>
    func toDictionaryView()
    func toAdvancedDictionaryView()
    func toResultWebView(url: URL)
    func toShareView(title: String, content: String)
    func updateShareView(rect: CGRect?)
    func toSettingView(onCloud: Bool)
    func callBackSetting() -> Observable<SettingFont>
    func actionShare() -> Observable<Void>
    func dismissSettingFontView()
    func triggerDismissSettingFontView() -> Observable<Bool>
    func toSettingSearch()
    func callBackSettingSearch() -> Observable<SettingSearch>
    func triggerDismissSettingSearchView() -> Observable<Bool>
    func dismissSettingSearchView()
    func toForceLogout()
    func reloadCloudDrafts()
    func toBackUpSetting(drafts: [Document])
    func dismissBackUp()
    func saveDraftType(type: SavingType)
}

protocol CreationCoordinatorProtocol {
    func reloadCloudDrafts()
    func saveDraftType(type: SavingType)
}

class CreationCoordinator: CoordinateProtocol, AlertNavigatorProtocol {
    var parentCoord: CoordinateProtocol?

    var delegate: CreationCoordinatorProtocol?
    var suggestionCoord: SuggestionCoordinator?
    var settingCoord: SettingCoordinator?
    var backUpCoord: BackUpSettingCoordinator?
    var updateSettingFont: PublishSubject<SettingFont> = PublishSubject.init()
    var actionShareObser: PublishSubject<Void> = PublishSubject.init()
    var triggerDismissSetting: PublishSubject<Bool> = PublishSubject.init()
    
    var settingSearchCoord: SettingSearchCoordinator?
    var updateSettingSearch: PublishSubject<SettingSearch> = PublishSubject.init()
    var triggerDismissSettingSearch: PublishSubject<Bool> = PublishSubject.init()
    
    
    weak var viewController: UIViewController!

    private var activityViewController: UIActivityViewController?
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = CreationViewController.instantiate(storyboard: .creation)
        }
    }
    
    func prepare(document: Document, folder: Folder?) -> CreationCoordinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? CreationViewController else { return self }
        
        vc.sceneType = .create
        let useCase = CreationUseCase()
        let viewModel = CreationViewModel(document: document,
                                          navigator: self,
                                          useCase: useCase,
                                          folder: folder)
        vc.bindViewModel(viewModel)
        
        return self
    }
    
    func prepare(attachTo folderId: FolderId, folder: Folder?) -> CreationCoordinator {
        var document = Document()
        document.folderId = folderId
        
        return prepare(document: document, folder: folder)
    }
    
    func presentWithNavigationController() {
        let nc = BaseNavigationController(rootViewController: viewController)
        nc.modalPresentationStyle = .fullScreen
        
        parentCoord?.viewController.present(nc, animated: true, completion: nil)
    }
}

extension CreationCoordinator: CreationNavigateProtocol {
    func saveDraftType(type: SavingType) {
        self.delegate?.saveDraftType(type: type)
    }
    
    func triggerDismissSettingSearchView() -> Observable<Bool> {
        return self.triggerDismissSettingSearch.asObservable()
    }
    
    func callBackSettingSearch() -> Observable<SettingSearch> {
        return self.updateSettingSearch.asObservable()
    }
    
    func triggerDismissSettingFontView() -> Observable<Bool> {
        return self.triggerDismissSetting.asObservable()
    }
    
    
    func actionShare() -> Observable<Void> {
        return self.actionShareObser.asObservable()
    }
    
    func callBackSetting() -> Observable<SettingFont> {
        return self.updateSettingFont.asObserver()
    }
    
    
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    func dismissSuggestionView() {
        self.suggestionCoord?.dismiss()
    }
    
    func toSuggestionView(title: String, titleData: GDData, contentData: GDData, sceneType: GATracking.Scene) -> Driver<SuggestionDelegate> {
        self.suggestionCoord = SuggestionCoordinator(parentCoord: self)
        self.suggestionCoord!
            .prepare(title: title, titleData: titleData, contentData: contentData, sceneType: sceneType)
            .presentInNavigationController()
        
        return self.suggestionCoord!.delegate.asDriverOnErrorJustComplete()
    }
    
    func toDictionaryView() {
        DictionaryCoordinator(parentCoord: self)
            .prepareInDraft()
            .presentInNavigationController()
    }
    
    func toAdvancedDictionaryView() {
        AdvancedDictionaryCoordinator(parentCoord: self)
            .prepareInDraft()
            .presentInNavigationController()
    }
    
    func toResultWebView(url: URL) {
        guard let currentSceneType = (viewController as? BaseViewController)?.sceneType else { return }
        let sceneType: GATracking.Scene = currentSceneType == .search ? .searchResults : .searchResultslnDraft
        
        WebCoordinator(parentCoord: self)
            .prepareNaviWebView(title: L10n.Dictionary.Result.title, url: url, sceneType: sceneType, openFrom: .draft)
            .presentInNavigationController(orientationMask: .all)
    }
    
    func toShareView(title: String, content: String) {
        let newContent = title.isEmpty ? content : "\(title)\n\(content)"
        
        let item = GooActivityTypeSource(content: newContent, placeholderImage: Asset.iTunesArtwork.image)
        
        activityViewController = UIActivityViewController(activityItems: [item], applicationActivities: nil)
        
        // avoiding to crash on iPad
        guard let vc = viewController as? CreationViewController else { return }
        self.updateShareView(rect: vc.view.frame)
        
        guard let activityViewController = self.activityViewController else {
            return
        }
        
        viewController.present(activityViewController, animated: true)
    }
    
    func updateShareView(rect: CGRect?) {
        // avoiding to crash on iPad
        if let popoverController = activityViewController?.popoverPresentationController {
            if let sourceRect = rect {
                popoverController.sourceRect = CGRect(x: sourceRect.width - popoverController.sourceRect.width,
                                                      y: 0,
                                                      width: 0,
                                                      height: 0)
                popoverController.sourceView = viewController.view
            } else {
                popoverController.sourceRect = viewController.navigationController?.navigationBar.frame ?? .zero
                popoverController.sourceView = viewController.navigationController?.navigationBar
            }
            
            popoverController.permittedArrowDirections = .up
        }
    }
    
    func toSettingView(onCloud: Bool) {
        self.settingCoord = SettingCoordinator(parentCoord: self)
        self.settingCoord?.delegate = self
        self.settingCoord!
            .prepare(onCloud: onCloud)
            .presentInNavigationController(onCloud: onCloud)
    }
    
    func toBackUpSetting(drafts: [Document]) {
        self.backUpCoord = BackUpSettingCoordinator(parentCoord: self)
        self.backUpCoord?.delegate = self
        self.backUpCoord!
            .prepare(drafts: drafts)
            .presentInNavigationController()
    }
    
    func toSettingSearch() {
        self.settingSearchCoord = SettingSearchCoordinator(parentCoord: self)
        self.settingSearchCoord?.delegate = self
        self.settingSearchCoord!
            .prepare()
            .presentInNavigationController()
    }
    
    func toForceLogout() {
        RegistrationLogoutCoordinator(parentCoord: self)
            .prepare()
            .start()
    }
    
    func reloadCloudDrafts() {
        self.delegate?.reloadCloudDrafts()
    }
}
extension CreationCoordinator: SettingDelegateCallBack {
    func dismissSettingFontView() {
        self.settingCoord?.dismiss()
        self.triggerDismissSetting.onNext(false)
    }
    
    func actionShare() {
        self.actionShareObser.onNext(())
    }
    
    func callBackSetting(settingFont: SettingFont) {
        self.updateSettingFont.onNext(settingFont)
    }
}
extension CreationCoordinator: SettingSearchDelegate {
    func callBackSetting(settingSearch: SettingSearch) {
        self.updateSettingSearch.onNext(settingSearch)
    }
    
    func dismissSettingSearchView() {
        self.settingSearchCoord?.dismiss()
        self.triggerDismissSettingSearch.onNext(false)
    }
    
    func actionPremium() {
        
    }
}
extension CreationCoordinator: BackUpSettingDelegate {
    
    func actionShareBackUp() {
        self.actionShareObser.onNext(())
    }
    
    func dismissBackUp() {
        self.backUpCoord?.dismiss()
        self.triggerDismissSetting.onNext(false)
    }
}
