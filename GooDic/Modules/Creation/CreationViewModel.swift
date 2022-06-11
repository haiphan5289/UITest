//
//  CreationViewModel.swift
//  GooDic
//
//  Created by ttvu on 5/18/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

/// saving a document
/// - after `x` seconds (auto-saving)
/// - changes to another apps (enter background)
/// - exits the creation screen.
/// - save trigger (user interaction)
enum SavingType {
    case auto
    case close
    case required // press the X button
}

struct CreationViewModel {
    let navigator: CreationAlertNaviProtocol
    let useCase: CreationUseCaseProtocol
    let document: Document
    let folder: Folder?
    
    private let disposeBag = DisposeBag()
    
    init(document: Document, navigator: CreationAlertNaviProtocol, useCase: CreationUseCaseProtocol, folder: Folder?) {
        self.document = document
        self.navigator = navigator
        self.useCase = useCase
        self.folder = folder
    }
}

extension CreationViewModel: ViewModelProtocol {
    
    enum StatusReplace {
        case replace, highlight
    }
    
    struct ApplyTextReplace {
        let tap: CreationViewController.TapHeader
        let listRange: [NSRange]
        let statusReplace: StatusReplace
        init(tap: CreationViewController.TapHeader, listRange: [NSRange], statusReplace: StatusReplace) {
            self.tap = tap
            self.listRange = listRange
            self.statusReplace = statusReplace
        }
    }
    
    struct TextInput: Equatable {
        let text: String
        let markedTextRange: NSRange?
        
        static let empty = TextInput(text: "", markedTextRange: nil)
        
        init(text: String, markedTextRange: NSRange? = nil) {
            self.text = text
            self.markedTextRange = markedTextRange
        }
    }
    
    
    
    struct TextAttributeString {
        let textSearch: String
        let attributedString: NSMutableAttributedString
        let textFont: UIFont
        let contentText: String
        let baseOnAttrs: [NSAttributedString.Key : Any]?
        let settingFont: SettingFont?

        
        static let empty = TextAttributeString(textSearch: "",
                                               attributedString: NSMutableAttributedString(),
                                               textFont: UIFont.init(),
                                               contentText: "",
                                               baseOnAttrs: [NSAttributedString.Key : Any](),
                                               settingFont: AppSettings.settingFont ?? SettingFont(size: SizeFont(rawValue: Double(FontManager.shared.currentFontStyle.contentFontSize)) ?? SizeFont.onehundred, name: NameFont.hiraginoSansW4, isEnableButton: true, autoSave: false)
                                               )

        init(textSearch: String,
             attributedString: NSMutableAttributedString,
             textFont: UIFont,
             contentText: String,
             baseOnAttrs: [NSAttributedString.Key : Any]?,
            settingFont: SettingFont?) {
            self.textSearch = textSearch
            self.attributedString = attributedString
            self.textFont = textFont
            self.contentText = contentText
            self.baseOnAttrs = baseOnAttrs
            self.settingFont = settingFont
        }
        func getContentAttsSearch(statusHighlight: SettingFont.StatusHighlight) -> [NSAttributedString.Key : Any] {
            guard let s = self.settingFont else { return [NSAttributedString.Key : Any]()}
            let newAttrs = s.getContentAttsSearch(baseOn: self.baseOnAttrs, statusHighlight: statusHighlight)
            return newAttrs
        }

    }
    
    struct CurrentIndex {
        let currentIndex: NSRange?
        let isScroll: Bool
        let times: Int
        init(currentIndex: NSRange?, isScroll: Bool, times: Int) {
            self.currentIndex = currentIndex
            self.isScroll = isScroll
            self.times = times
        }
    }
    
    enum CheckInput {
        case title(Range<String.Index>)
        case content(Range<String.Index>)
        case all
    }
    
    enum AutoSaveStatus {
        case change, otherChange, donotChange
        static func getStatus(title: String, content: String, cursorPosition: Int, lastDoc: Document, otherCode: Bool) -> Self {
            if otherCode && (title != lastDoc.title || content != lastDoc.content || cursorPosition != lastDoc.cursorPosition) {
                return .otherChange
            }
            if title != lastDoc.title || content != lastDoc.content || cursorPosition != lastDoc.cursorPosition {
                return .change
            }
            return .donotChange
        }
    }
    
    struct Input {
        let loadTrigger: Driver<Void>
        let viewWillAppear: Driver<Void>
        let viewDidAppear: Driver<Void>
        let viewDidLayoutSubviews: Driver<Void>
        let titleInputTrigger: Driver<TextInput>
        let contentInputTrigger: Driver<TextInput>
        let cursorPosition: Driver<Int>
        let selectionTrigger: Driver<CheckInput>
        let updateRawTitleTrigger: Driver<String>
        let updateRawContentTrigger: Driver<String>
        let dismissTrigger: Driver<Void>
        let saveTrigger: Driver<Void>
        let shareTrigger: Driver<Void>
        let idiomTrigger: Driver<Void>
        let thesaurusTrigger: Driver<Void>
        let dictionaryTrigger: Driver<String?>
        let enterEditingMode: Driver<Void>
        let tapTooltipTrigger: Driver<Void>
        let tapFontViewTrigger: Driver<Bool>
        let tapContentViewTrigger: Driver<Void>
        let selectFontStyleTrigger: Driver<Int>
        let isRotation: Driver<Void>
        let selectFrameTrigger: Driver<CGRect?>
        let tapTriggerHeader: Driver<CreationViewController.TapHeader>
        let searchInputTrigger: Driver<TextAttributeString?>
        let tapTriggerSearch: Driver<CreationViewController.TapHeader>
        let tapReplace: Driver<CreationViewController.TextReplace?>
        let updateTextViewContent: Driver<CreationViewModel.TextAttributeString?>
        let eventTextOverMaxLenght: Driver<CreationViewController.HandleReplace>
        let eventShowAlertMaxLenght: Driver<CreationViewController.HandleReplace>
        let eventSettingSearch: Driver<Void>
        let tapViewCoverSettingSearch: Driver<Void>
        let getAttributeLoadFirst: Driver<TextAttributeString?>
        let updateListSearchWithEmpty: Driver<Void>
        let eventUpdateListRangeWhenReplace: Driver<CreationViewController.TextReplaceUpdate>
        let eventShowAlertTitleMaxLenght: Driver<UITextRange?>
        let eventAutoSaveCloud: Driver<Bool>
        let eventWillEnterForegroundTrigger: Driver<Void>
    }
    
    struct Output {
        let title: Driver<TextInput>
        let content: Driver<TextInput>
        let lastCursorPosition: Driver<Int>
        let hasData: Driver<Bool>
        let hasChanged: Driver<Bool>
        let numberOfCharacter: Driver<Int>
        let keyboardHeight: Driver<PresentAnim>
        let presentedViewHeight: Driver<PresentAnim>
        let share: Driver<Void>
        let showProgress: Driver<Bool>
        let showIdiom: Driver<Void>
        let showThesaurus: Driver<Void>
        let showDictionary: Driver<Void>
        let dismiss: Driver<Void>
        let dismissSuggestion: Driver<Void>
        let hideProgressBar: Driver<Void>
        let lastSaveDraft: Driver<Void>
        let showTooltip: Driver<Bool>
        let autoHideTooltips: Driver<Void>
        let error: Driver<Bool>
        let cancelRequestAPI: Driver<Void>
        let findTagOnTitle: Driver<SelectedTagData>
        let findTagOnContent: Driver<SelectedTagData>
        let loadFontData: Driver<(current: Int, total: Int)>
        let showOrHideFontStyleView: Driver<Bool>
        let changedFontStyle: Driver<FontStyleData>
        let isRotation: Driver<Void>
        let serverErrorHandler: Driver<Void>
        let loadingFullScreen: Driver<Bool>
        let showToast: Driver<Void>
        let deleteCloudDraft: Driver<Void>
        let showBanner: Driver<BannerType>
        let tapTriggerHeader: Driver<CreationViewController.TapHeader>
        let textSearchTrigger: Driver<NSMutableAttributedString>
        let listPositionSearch: Driver<[NSRange]>
        let tapTriggerSearch: Driver<NSMutableAttributedString>
        let currentIndex: Driver<CurrentIndex>
        let settingFont: Driver<SettingFont>
        let shareSettingFont: Driver<Void>
        let isShowSettingView: Driver<Bool>
        let dismissSettingView: Driver<Void>
        let settingSearch: Driver<SettingSearch>
        let isShowSettingSearch: Driver<Bool>
        let dismissSettingSearchView: Driver<Void>
        let textReplace: Driver<ApplyTextReplace?>
        let resetAttributedString: Driver<(NSMutableAttributedString, Bool)>
        let updateTextViewContent: Driver<Void>
        let actionUndoReplace: Driver<NSRange?>
        let eventTextOverMaxLenght: Driver<CreationViewController.HandleReplace>
        let eventShowAlertMaxLenght: Driver<CreationViewController.HandleReplace>
        let errorHandler: Driver<Void>
        let detectData: Driver<Bool>
        let getAttributeLoadFirst: Driver<TextAttributeString?>
        let updateListSearchWithEmpty: Driver<Void>
        let doEventResetScrollTapReplace: Driver<Void>
        let doEventLastIndex: Driver<Bool>
        let eventUpdateListRangeWhenReplace: Driver<Void>
        let updateTextViewReplaceAll: Driver<NSMutableAttributedString>
        let eventShowAlertTitleMaxLenght: Driver<UITextRange?>
        let eventHeightSettingFont: Driver<CGFloat>
        let autoSaveCloud: Driver<Void>
        let disableAutoSave: Driver<Void>
        let statusLoading: Driver<GooLoadingViewController.StatusLoading>
        let otherCodeTrigger: Driver<Void>
        let positionCursorAutoSave: Driver<Void>
        let showPremium: Driver<Void>
        let enableAutoSaveCloud: Driver<Void>
        let reloadContent: Driver<Document?>
        let errorReloadDraft: Driver<Void>
        let resetCursor: Driver<Void>
        let doBackUp: Driver<Void>
        let isCallAutoSave: Driver<Bool>
    }
    
    func transform(_ input: Input) -> Output {
        let cloudDraftId = Observable.deferred { () -> Observable<String?> in
            if case let .cloud(folderIdValue) = self.document.folderId {
                return Observable.just(folderIdValue)
            }
            
            return Observable.just(nil)
        }
        .startWith(nil)
        
        let onCloud = cloudDraftId
            .map({ $0 == nil ? false : true })
        let lastCursorPosition = input.loadTrigger
            .map({ document.cursorPosition })

        let updateRawTitle = input.updateRawTitleTrigger
            .startWith(document.title)
            .map({ TextInput(text: $0) })
            .asDriver()
        
        let updateRawContent = input.updateRawContentTrigger
            .startWith(document.content)
            .map({ TextInput(text: $0) })
            .asDriver()
        
        let updatedDocumentTrigger = BehaviorSubject<Document>(value: self.document)
        var lastDocument = self.document
        let loadDocument = Driver
            .merge(
                input.loadTrigger.map({ self.document }),
                updatedDocumentTrigger.asDriverOnErrorJustComplete())
            .do { doc in
                lastDocument = doc
            }

        
        let loadDocumentTitle = loadDocument
            .map({ TextInput(text: $0.title) })
            
        
        let loadDocumentContent = loadDocument
            .map({ TextInput(text: $0.content) })
        
        let title = Driver
            .merge(
                input.titleInputTrigger,
                loadDocumentTitle,
                updateRawTitle)
        
        let content = Driver
            .merge(
                input.contentInputTrigger,
                loadDocumentContent,
                updateRawContent)
            .asObservable()
            .share()
            .asDriverOnErrorJustComplete()
        
        let numberOfCharacters = content.asDriver()
            .map({ (textInput: TextInput) -> Int in
                if let range = textInput.markedTextRange {
                    return textInput.text.count - range.length
                } else {
                    return textInput.text.count
                }
            })
        
        let hasData = content
            .map({ $0.text.trimmingCharacters(in: .whitespacesAndNewlines) })
            .map({ $0.count > 0 })
        
        var contentTextView: String = ""
        var titleTextView: String = ""
        var positionCursorTextView: Int = 0
        
        let detectData = Driver.combineLatest(title, content)
            .map { (title, content) -> Bool in
                contentTextView = content.text
                titleTextView = title.text
                
                let isTitle = title.text.count <= 0
                let isContent = content.text.count <= 0
                if isTitle && isContent {
                    return false
                }
                return true
            }
        
        //Skip the default value
        let positionCursorAutoSave = input.cursorPosition
            .skip(1)
            .do { position in
                positionCursorTextView = position
            }
            .mapToVoid()

        
        let isRotation = input.isRotation
            .withLatestFrom(input.selectFrameTrigger)
            .do(onNext: self.navigator.updateShareView(rect:))
            .mapToVoid()

        let errorTrigger = PublishSubject<Bool>()
        let progressActivityIndicator = ActivityIndicator()
        
        let showProgress = progressActivityIndicator.asDriver()
        let showSuggestionView = BehaviorSubject(value: false)
        let error = errorTrigger.asDriver(onErrorJustReturn: true)
        let errorHandler = errorTrigger
            .flatMap({ (error) -> Driver<Void> in
                return self.navigator
                    .showMessage(L10n.Server.Error.timeOut)
                    .asDriverOnErrorJustComplete()
            })
            .asDriverOnErrorJustComplete()

        var cancelTrigger = PublishSubject<Void>()
        let dismissSuggestionViewTrigger = PublishSubject<Void>()
        let findTagOnContentTrigger = PublishSubject<SelectedTagData>()
        let findTagOnTitleTrigger = PublishSubject<SelectedTagData>()
        let eventResetScrollTapReplace = PublishSubject<Void>()
        let eventLastIndex = PublishSubject<Bool>()
        
        let share = input.shareTrigger
            .do(onNext: self.navigator.dismissSuggestionView)
            .withLatestFrom(Driver.combineLatest(title, content))
            .filter({ !$0.1.text.isEmpty })
            .do(onNext: { (title, content) in
                eventResetScrollTapReplace.onNext(())
                showSuggestionView.onNext(false)
                self.navigator.toShareView(title: title.text, content: content.text)
            })
            .mapToVoid()
        
        let showIdiomData = input.idiomTrigger
            .withLatestFrom(Driver.combineLatest(showProgress, showSuggestionView.asDriverOnErrorJustComplete(), title, content, input.selectionTrigger))
            .filter({ $0.0 == false && $0.1 == false}) // isn't waiting for a previous request and isn't showing Suggestion View
            .asObservable()
            .flatMapLatest({ (_, _, titleTI, contentTI, selection) -> Observable<FetchDataResult> in
                cancelTrigger = PublishSubject<Void>()
                
                let result: Observable<FetchDataResult>
                switch selection {
                case let .title(range):
                    result = self.useCase
                        .checkIdiom(title: titleTI.text,
                                    content: contentTI.text,
                                    selectedRangeTitle: range)
                case let .content(range):
                    result = self.useCase
                        .checkIdiom(title: titleTI.text,
                                    content: contentTI.text,
                                    selectedRangeContent: range)
                case .all:
                    result = self.useCase
                        .checkIdiom(title: titleTI.text,
                                    content: contentTI.text)
                }
                
                return result
                    .trackActivity(progressActivityIndicator)
                    .takeUntil(cancelTrigger)
            })
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: { (result) in
                switch result {
                case .error(let error):
                    print(error.localizedDescription)
                    errorTrigger.onNext(true)
                case let .connectionError(error):
                    errorTrigger.onNext(true)
                default:
                    break
                }
            })
            .asDriverOnErrorJustComplete()
            .flatMapLatest({ (result) -> Driver<SuggestionDelegate> in
                guard case let .success(titleData, contentData) = result else {
                    return Driver.empty()
                }
                eventResetScrollTapReplace.onNext(())
                showSuggestionView.onNext(true)
                
                return self.navigator
                    .toSuggestionView(title: L10n.Creation.proofreading,
                                      titleData: titleData,
                                      contentData: contentData,
                                      sceneType: .proofread)
                    .do(onNext: { (delegate) in
                        switch delegate {
                        case .dismiss:
                            dismissSuggestionViewTrigger.onNext(())
                        case let .findTagOnContent(data):
                            findTagOnContentTrigger.onNext(data)
                        case let .findTagOnTitle(data):
                            findTagOnTitleTrigger.onNext(data)
                        }
                    })
            })
            .mapToVoid()
        
        let showThesaurusData = input.thesaurusTrigger
            .withLatestFrom(Driver.combineLatest(showProgress, showSuggestionView.asDriverOnErrorJustComplete(), title, content, input.selectionTrigger))
            .filter({ $0.0 == false && $0.1 == false}) // isn't waiting for a previous request and isn't showing Suggestion View
            .asObservable()
            .flatMapLatest({ (_, _, titleTI, contentTI, selection) -> Observable<FetchDataResult> in
                cancelTrigger = PublishSubject<Void>()
                
                let result: Observable<FetchDataResult>
                
                switch selection {
                case let .title(range):
                    result = self.useCase
                        .checkThesaurus(title: titleTI.text,
                                        content: contentTI.text,
                                        selectedRangeTitle: range)
                case let .content(range):
                    result = self.useCase
                        .checkThesaurus(title: titleTI.text,
                                        content: contentTI.text,
                                        selectedRangeContent: range)
                case .all:
                    result = self.useCase
                        .checkThesaurus(title: titleTI.text,
                                        content: contentTI.text)
                }
                
                return result
                    .trackActivity(progressActivityIndicator)
                    .takeUntil(cancelTrigger)
            })
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: { (result) in
                switch result {
                case .error(let error):
                    print(error.localizedDescription)
                    errorTrigger.onNext(true)
                case let .connectionError(error):
                    errorTrigger.onNext(true)
                default:
                    break
                }
            })
            .asDriverOnErrorJustComplete()
            .flatMapLatest({ (result) -> Driver<SuggestionDelegate> in
                guard case let .success(titleData, contentData) = result else {
                    return Driver.empty()
                }
                eventResetScrollTapReplace.onNext(())
                showSuggestionView.onNext(true)
                
                return self.navigator
                    .toSuggestionView(title: L10n.Creation.paraphrase,
                                      titleData: titleData,
                                      contentData: contentData,
                                      sceneType: .paraphrase)
                    .do(onNext: { (delegate) in
                        switch delegate {
                        case .dismiss:
                            dismissSuggestionViewTrigger.onNext(())
                        case let .findTagOnContent(data):
                            findTagOnContentTrigger.onNext(data)
                        case let .findTagOnTitle(data):
                            findTagOnTitleTrigger.onNext(data)
                        }
                    })
            })
            .mapToVoid()
        
        let showDictionary = input.dictionaryTrigger
            .flatMapLatest({ (text: String?) -> Driver<URL?> in
                guard let text = text, text.count != 0 else { return Driver.just(nil) }
                
                return self.useCase.search(text: text).asDriver(onErrorJustReturn: nil)
            })
            .do(onNext: { (url) in
                eventResetScrollTapReplace.onNext(())
                if let url = url {
                    self.navigator.toResultWebView(url: url)
                } else {
                    self.navigator.toAdvancedDictionaryView()
                }
            })
            .mapToVoid()
        
        let discardSuggestionTrigger = Driver
            .merge(dismissSuggestionViewTrigger.asDriverOnErrorJustComplete(),
                   input.enterEditingMode)
            .withLatestFrom(showSuggestionView.asDriverOnErrorJustComplete())
            .filter({ $0 })
            .mapToVoid()
        
        // dismiss the suggestion bottom view.
        let dismissSuggestion = discardSuggestionTrigger
            .do(onNext: navigator.dismissSuggestionView)
            .do(onNext: {
                eventResetScrollTapReplace.onNext(())
                showSuggestionView.onNext(false)
            })
        
        let hideProgressBar = Driver.merge(discardSuggestionTrigger,
                                           input.dictionaryTrigger.mapToVoid(),
                                           input.shareTrigger)
        
        let cancelRequestAPI = Driver.merge(discardSuggestionTrigger,
                                            input.dictionaryTrigger.mapToVoid(),
                                            input.shareTrigger,
                                            input.dismissTrigger,
                                            title.mapToVoid(),
                                            content.mapToVoid())
            .do(onNext: { (_) in
                cancelTrigger.onNext(())
            })
        
        
        // save draft: both local and cloud
        let activityIndicator = ActivityIndicator()
        var autoSaveCount: Disposable?
        let eventAutoSave: PublishSubject<Void> = PublishSubject.init()
        var runningAutoSave: Bool = false
        var otherCode: Bool = false
                
        let willEnterForegroundTrigger = input.eventWillEnterForegroundTrigger
            .map({ _  -> Bool in
                self.useCase.disableAutoSaveCloud(autoSaveCount: autoSaveCount)
                runningAutoSave = false
                return true
            })
                
        let eventEnableAutoSave: PublishSubject<Bool> = PublishSubject.init()

        let autoSaveCloud = Driver.merge(willEnterForegroundTrigger, input.eventAutoSaveCloud)
            .withLatestFrom(eventEnableAutoSave.asDriverOnErrorJustComplete(), resultSelector: { (enableAutoSave: $1, autoSave: $0) })
                .withLatestFrom(onCloud.asDriverOnErrorJustComplete(), resultSelector: { (onCloud: $1, autoSave: $0.autoSave, enableAutoSave: $0.enableAutoSave) })
            .flatMap { (onCloud, autoSave, enableAutoSave) -> Driver<Void?> in
                guard onCloud else { return Driver.just(nil) }
                if !enableAutoSave {
                    if autoSave && !runningAutoSave {
                        runningAutoSave = true
                        self.useCase.enableAutoSaveCloud(autoSaveCount: &autoSaveCount) {
                            let statusAutoSave = AutoSaveStatus.getStatus(title: titleTextView,
                                                                          content: contentTextView,
                                                                          cursorPosition: positionCursorTextView,
                                                                          lastDoc: lastDocument,
                                                                          otherCode: otherCode)
                            switch statusAutoSave {
                            case .change, .otherChange:
                                eventAutoSave.onNext(())
                            case .donotChange:
                                self.useCase.disableAutoSaveCloud(autoSaveCount: autoSaveCount)
                                runningAutoSave = false
                            }
                        }
                    } else if !autoSave {
                        self.useCase.disableAutoSaveCloud(autoSaveCount: autoSaveCount)
                        runningAutoSave = false
                    }
                }
                return Driver.just(())
            }
            .compactMap { $0 }
        
        let statusLoading = Driver.merge(eventAutoSave.map { GooLoadingViewController.StatusLoading.hide }.asDriverOnErrorJustComplete(),
                                         input.eventAutoSaveCloud.filter{ $0 == false }.map { _ in GooLoadingViewController.StatusLoading.show },
                                         input.saveTrigger.map { GooLoadingViewController.StatusLoading.show },
                                         input.dismissTrigger.map { GooLoadingViewController.StatusLoading.show })

        let resetCursor: PublishSubject = PublishSubject<Void>.init()
        let savedDraft = saveDraft(saveTrigger: input.saveTrigger,
                                   title: title.map({ $0.text }),
                                   content: content.map({ $0.text }),
                                   cursorPosition: input.cursorPosition,
                                   oldDraft: updatedDocumentTrigger.asDriverOnErrorJustComplete(),
                                   dismissTrigger: input.dismissTrigger,
                                   activityIndicator: activityIndicator,
                                   autoSaveCloud: eventAutoSave.asDriverOnErrorJustComplete(),
                                   enableAutoSave: eventEnableAutoSave,
                                   autoSaveCount: autoSaveCount,
                                   resetCursor: resetCursor)
        
        let disableAutoSave = Driver.merge(input.dismissTrigger, savedDraft.dismiss)
            .do { _ in
                self.useCase.disableAutoSaveCloud(autoSaveCount: autoSaveCount)
            }
        let keyboardHeight = keyboardHandle()
            .takeUntil(savedDraft.dismiss.asObservable())
            .asDriverOnErrorJustComplete()
        
        let presentedViewHeight = presentationViewHandle()
            .takeUntil(savedDraft.dismiss.asObservable())
            .asDriverOnErrorJustComplete()
        
        let lastSaveDraft = savedDraft.lastSaveDraft
            .do(onNext: { updatedDocumentTrigger.onNext($0) })
            .mapToVoid()
        
        // Reload draft when save draft show error code 22
        var isReloadDocument = false
        let reloadDocumentTrigger = savedDraft.reloadDraft
            .do(onNext: {
                isReloadDocument = true
                updatedDocumentTrigger.onNext($0)
            })

        let reloadContent = reloadDocumentTrigger
            .flatMapLatest({ (document) -> Driver<Document?> in
                if isReloadDocument {
                    isReloadDocument = false
                    return Driver.just(document)
                }
                return Driver.just(nil)
            })
          
        // delete cloud draft
        let deleteTrigger = savedDraft.deleteDraft
            .withLatestFrom(updatedDocumentTrigger.asDriverOnErrorJustComplete())
        
        let deleteCloudDraft = deleteDraftFlow(deleteDraft: deleteTrigger,
                                               activityIndicator: activityIndicator)
        
        /// data has changed
        let hasChanged = Driver.combineLatest(title, content, loadDocument)
            .flatMapLatest({ (title, content, document) -> Driver<Bool> in
                let isSame = title.text == document.title && content.text == document.content
                return Driver.just(!isSame)
            })
                    
        /// tooltip popup
        /// Hide:
        /// - touches on popup
        /// - touches on idiom button or thesaurus button
        /// Show: if user has never done the above.
        let autoHideTooltipTrigger = PublishSubject<Void>()
        
        let learnedTooltip = Driver
            .merge(input.tapTooltipTrigger,
                   input.idiomTrigger,
                   input.thesaurusTrigger,
                   autoHideTooltipTrigger.asDriverOnErrorJustComplete())
            .asObservable()
            .take(1)
            .flatMapLatest(self.useCase.learnedTooltip)
            .asDriverOnErrorJustComplete()
        
        let showTooltip = Driver
            .merge(
                input.viewDidAppear,
                hasData.filter({ $0 }).mapToVoid(),
                learnedTooltip)
            .asObservable()
            .skipUntil(input.viewDidLayoutSubviews.asObservable())
            .asDriverOnErrorJustComplete()
            .flatMapLatest({ Driver.merge(hasData.filter({ $0 }).mapToVoid(), learnedTooltip) })
            .map({ _ in self.useCase.showCheckAPITooltip() })
            .distinctUntilChanged()
        
        let autoHideTooltips = showTooltip
            .filter({ $0 })
            .mapToVoid()
            .delay(.seconds(GlobalConstant.tooltipDuration))
            .do(onNext: { autoHideTooltipTrigger.onNext(()) })
        
        /// Font Style View
        let loadFontData = input.loadTrigger
            .map({ (_) -> (current: Int, total: Int) in
                return (current: self.useCase.getCurrentFontStyleLevel(),
                        total: self.useCase.getTotalFontStyleLevel())
            })
        
        let showOrHideFontStyleView = Driver
            .merge(
                input.tapFontViewTrigger,
                input.tapContentViewTrigger.map({ false }))
            
        let changedFontStyle = Driver
            .merge(
                input.selectFontStyleTrigger,
                input.loadTrigger.map( self.useCase.getCurrentFontStyleLevel ))
            .do(onNext: { self.useCase.setFontStyleLevel(level: $0) })
            .map({ _ in FontManager.shared.currentFontStyle })
        
        // dismiss the creation screen
        let dismiss = savedDraft.dismiss
            .do(onNext: navigator.dismiss)
        
        let showBanner = input.viewWillAppear
            .flatMap({ onCloud.asDriverOnErrorJustComplete() })
            .filter({ $0 })
            .map({ _ in BannerType.creation })
            .filter({ $0.isClosed == false })
            .asObservable()
            .take(1)
            .asDriverOnErrorJustComplete()
        
        let listUpdatePosition: PublishSubject<[NSRange]> = PublishSubject.init()
        
        let tapTrigger = input.tapTriggerHeader
            .map { tapState -> CreationViewController.TapHeader in
                
                switch tapState {
                case .cleanText, .editChanged:
                    eventResetScrollTapReplace.onNext(())
                    listUpdatePosition.onNext([])
                default: break
                }
                
                return tapState
            }
        
//        let hideSeachViewWhenTapContenView = input.tapContentViewTrigger
//            .map{ CreationViewController.TapHeader.unSearch }
        let tapTriggerHeader = Driver.merge(tapTrigger)
        
        //setup -10, to make sure, it wil beyoud it's range
        var currentPosition: NSRange = NSRange(location: -10, length: 0)
        var attributeCache: TextAttributeString = TextAttributeString.empty
        var doNotScrollWhenTap: Bool = true
        var detectLastIndexWhenTap: Bool?
        var detectFirstIndexWhenTap: Bool?
        let updateTextViewReplaceAll = PublishSubject<NSMutableAttributedString>.init()
        
        let textSearchTrigger = input.searchInputTrigger.asObservable()
            .map { textItem  -> NSMutableAttributedString in
                eventResetScrollTapReplace.onNext(())
                let att = textItem ?? TextAttributeString.empty
                
                //reset attributed
                let attributes = att.getContentAttsSearch(statusHighlight: .other)
                var attributedQuote = NSMutableAttributedString(string: att.contentText, attributes: attributes)
                
                var listTextSearch: [String] = []
                listTextSearch.append(att.textSearch)
                
                for item in listTextSearch {
                    self.useCase.highlight(source: &attributedQuote, searchText: String(item), textAttribute: att)
                }
                
                attributeCache = TextAttributeString(textSearch: att.textSearch,
                                                     attributedString: attributedQuote,
                                                     textFont: att.textFont,
                                                     contentText: attributedQuote.string,
                                                     baseOnAttrs: att.baseOnAttrs,
                                                     settingFont: att.settingFont
                                                     )
                
                return attributedQuote
            }
            .asDriverOnErrorJustComplete()
        
        let listSearch = input.searchInputTrigger.asObservable()
            .map { textItem  -> [NSRange] in
                let att = textItem ?? TextAttributeString.empty
                var l: [NSRange] = []
                
                var listTextSearch: [String] = []
                listTextSearch.append(att.textSearch)
                
                for item in listTextSearch {
                    l += self.useCase.listPositionSearch(source: att.attributedString, searchText: String(item))
                }
                
                currentPosition = l.first ?? NSRange(location: -10, length: 0)
                
                return l
            }
            .asDriverOnErrorJustComplete()
        
        let listPositionSearch = Driver.merge(listUpdatePosition.asDriverOnErrorJustComplete(), listSearch)
        
        let actionUndoReplace = input.tapReplace
            .map { tap -> NSRange? in
                guard let tap = tap else { return nil }
                switch tap.tap {
                case .replace: return currentPosition
                default: return nil
                }
            }
        let nextIndex = input.tapTriggerSearch
            .asObservable()
            .withLatestFrom(listPositionSearch.asObservable()) { (tap, list) -> CurrentIndex in
                    guard let index = list.firstIndex(of: currentPosition) else { return CurrentIndex(currentIndex: nil, isScroll: false, times: 2) }
                eventLastIndex.onNext(false)
                    var i: Int = index
                    switch tap {
                    case .next:
                        
                        if detectFirstIndexWhenTap ?? false {
                            if list.count > 0 {
                                i = 0
                            }
                            detectFirstIndexWhenTap = nil
                        } else if doNotScrollWhenTap == false {
                            i = index
                        } else {
                            i = index + 1
                            
                            if index + 1 >= list.count {
                                i = index
        //                        return list.first
                            }
                        }
                        
                        
                        
                    case .previous:
                        
                        if detectLastIndexWhenTap ?? false {
                            if list.count > 0 {
                                i = list.count - 1
                            }
                            detectLastIndexWhenTap = nil
                        } else {
                            i = index - 1
                            
                            if index <= 0 {
                                i = 0
                            }
                        }
                        
                        
                    default: break
                    }
                eventResetScrollTapReplace.onNext(())
                    return CurrentIndex(currentIndex: list[i], isScroll: true, times: 2)
    
            }
            .asDriverOnErrorJustComplete()
        let updateIndex: PublishSubject<CurrentIndex> = PublishSubject.init()
        let textReplace = input.tapReplace
            .asObservable()
            .withLatestFrom(listPositionSearch.asObservable(), resultSelector: { (item, list) -> ApplyTextReplace? in
                guard let item = item else { return nil }
                let att = attributeCache.attributedString
                    
                if doNotScrollWhenTap {
                    doNotScrollWhenTap = false
                    switch item.tap {
                    case .replace:
                        return ApplyTextReplace(tap: .replace, listRange: [currentPosition], statusReplace: .replace)
                    case .replaceAll:
                        let attributeAll = self.useCase.replaceAllText(source: att,
                                                                       textSearch: attributeCache.textSearch,
                                                                       textAttribute: attributeCache,
                                                                       textReplace: item.text)
                        listUpdatePosition.onNext([])
                        updateIndex.onNext(CurrentIndex(currentIndex: nil, isScroll: false, times: 1))
                        updateTextViewReplaceAll.onNext(attributeAll)
                        return nil
                    default: return nil
                    }
                } else {
                    doNotScrollWhenTap = true
                    switch item.tap {
                    case .replace:
                        
                        listUpdatePosition.onNext(list)
                        updateIndex.onNext(CurrentIndex(currentIndex: currentPosition, isScroll: true, times: 1))

                        if let index = list.firstIndex(of: currentPosition) {
                            if index == list.count - 1 {
                                eventLastIndex.onNext(true)
                            } else {
                                eventLastIndex.onNext(false)
                            }
                            
                            if index == 0 {
                                detectFirstIndexWhenTap = nil
                            }
                            
                            
                        } else {
                            eventLastIndex.onNext(false)
                        }

//                        return (.highlight, currentPosition)
                        return ApplyTextReplace(tap: .replace, listRange: [currentPosition], statusReplace: .highlight)
                    case .replaceAll:
                        let attributeAll = self.useCase.replaceAllText(source: att,
                                                                       textSearch: attributeCache.textSearch,
                                                                       textAttribute: attributeCache,
                                                                       textReplace: item.text)
                        
                        listUpdatePosition.onNext([])
                        updateIndex.onNext(CurrentIndex(currentIndex: nil, isScroll: false, times: 1))
                        updateTextViewReplaceAll.onNext(attributeAll)
                        return nil
                    default: return nil
                    }
                }
                    
                
            })
            .asDriverOnErrorJustComplete()
        
        let eventUpdateListRangeWhenReplace = input.eventUpdateListRangeWhenReplace
            .asObservable()
            .withLatestFrom(listPositionSearch.asObservable(), resultSelector: { (item, list) -> Void in
                
                var indexUpdate = self.currentIndex(list: list, currentPosition: currentPosition)
                let indexCurrent = list.firstIndex(of: currentPosition) ?? 0

                if indexCurrent == list.count - 1 {
                    detectLastIndexWhenTap = true
                } else {
                    detectLastIndexWhenTap = nil
                }

                if indexCurrent == 0 {
                    detectFirstIndexWhenTap = true
                } else {
                    detectFirstIndexWhenTap = nil
                }

                let l: [NSRange] = self.updateListRange(listRange: list,
                                                        currentPosition: currentPosition,
                                                        different: item.text.count - attributeCache.textSearch.count)

                if l.count <= 0 {
                    listUpdatePosition.onNext([])
                    updateIndex.onNext(CurrentIndex(currentIndex: nil, isScroll: false, times: 2))
                    indexUpdate = l.first ?? currentPosition
                } else {
                    listUpdatePosition.onNext(l)
                    if let index = list.firstIndex(of: currentPosition), list[index] == list.last {
                        currentPosition = l.first ?? currentPosition
                        indexUpdate = l.first ?? currentPosition
                    } else {
                        indexUpdate = l[indexCurrent]
                    }
                }
                
                
                if currentPosition != list.last {
                    currentPosition = indexUpdate
                } else if currentPosition == list.last && item.text != "" && list.count == 1 {
            
                    currentPosition = list.first ?? currentPosition

                } else if currentPosition == list.last && item.text != "" {
                    currentPosition = list.first ?? currentPosition
                }
                
                listUpdatePosition.onNext(l)
                updateIndex.onNext(CurrentIndex(currentIndex: item.range, isScroll: false, times: 1))

                if let isLastIndex = detectLastIndexWhenTap {
                    eventLastIndex.onNext(true)
                } else {
                    eventLastIndex.onNext(false)
                }
                
                return ()
            })
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        
        
//        let tapReplaceToDetectCurrent = input.tapReplace.asObservable()
//            .withLatestFrom(listPositionSearch.asObservable()) { (tap, list) -> CurrentIndex in
//                guard let index = list.firstIndex(of: currentPosition), let tap = tap?.tap else { return CurrentIndex(currentIndex: currentPosition, isScroll: false, times: 2) }
//                eventLastIndex.onNext(false)
//                var i: Int = index
//                switch tap {
//                case .replace:
//                    i = index + 1
//
//                    if index + 1 >= list.count {
//                        i = list.count - 1
//                    }
//                default: break
//                }
//                return CurrentIndex(currentIndex: list[i], isScroll: false, times: 2)
//            }
//            .asDriverOnErrorJustComplete()
        
        let getIndexWhenUpdateList = listPositionSearch
            .map { list -> CurrentIndex in
                guard let index = list.firstIndex(of: currentPosition) else { return CurrentIndex(currentIndex: nil, isScroll: false, times: 1) }
                eventLastIndex.onNext(false)
                return (doNotScrollWhenTap == false) ? CurrentIndex(currentIndex: list[index], isScroll: false, times: 2) : CurrentIndex(currentIndex: list[index], isScroll: true, times: 2)
        }
        
        
        
        let getCurrentIndex = Driver.merge(nextIndex,
//                                           tapReplaceToDetectCurrent,
                                           getIndexWhenUpdateList,
                                           updateIndex.asDriverOnErrorJustComplete())
        
        let tapTriggerSearch = nextIndex
            .asObservable()
            .withLatestFrom(listPositionSearch.asObservable()) { (range, list) -> NSMutableAttributedString in
                    guard let range = range.currentIndex,
                          let indexUpdate = list.firstIndex(of: range) else { return attributeCache.attributedString }
                    currentPosition = list[indexUpdate]

                return attributeCache.attributedString
                }
                
//            }
            .asDriverOnErrorJustComplete()
        
        
        
        let showSettingView = Driver.combineLatest(input.tapTriggerHeader.filter{ $0 == .setting || $0 == .search }, onCloud.asDriverOnErrorJustComplete())
            .flatMap { (tap, onCloud) -> Driver<Bool> in
                navigator.dismissSuggestionView()
                showSuggestionView.onNext(false)
                eventResetScrollTapReplace.onNext(())
                switch tap {
                case .setting:
                    if #available(iOS 13.0, *) {
                        if onCloud {
                            self.navigator.toBackUpSetting(drafts: [self.document])
                        } else {
                            self.navigator.toSettingView(onCloud: onCloud)
                        }
                        
                        
                    } else {
                        // I have to update the text with a short delay time to make the text view displayed on top. I tried to find the last event to be called to set up text view, but I hadn't found it out.
                        // view did layout subviews, text view did update the font, or text view did layout, all of them don't work
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if onCloud {
                                self.navigator.toBackUpSetting(drafts: [self.document])
                            } else {
                                self.navigator.toSettingView(onCloud: onCloud)
                            }
                        }
                    }
                    return Driver.just(true)
                    
                case .settingSearch:
                    return Driver.just(false)
                    
                default:
                    self.navigator.dismissSettingFontView()
                    return Driver.just(false)
                }
            }
        
        let eventSetting = self.navigator.triggerDismissSettingFontView().asDriverOnErrorJustComplete()
        let eventDismissSettingFont = input.tapTriggerHeader
            .filter{ $0 == .hideSettingFont }
            .map({ _ -> Bool in
                eventResetScrollTapReplace.onNext(())
                self.navigator.dismissSettingFontView()
                return false
            })

        let dismissSettingView = input.enterEditingMode
            .withLatestFrom(onCloud.asDriverOnErrorJustComplete())
            .do { onCloud in
                if onCloud {
                    self.navigator.dismissBackUp()
                } else {
                    self.navigator.dismissSettingFontView()
                }
            }
            .mapToVoid()

        
        let isShowSettingView = Driver.merge(showSettingView, eventSetting, eventDismissSettingFont)
    
        let getSettingFont = Driver.just(self.useCase.getSettingFont())
            .map { setting -> SettingFont in
                
                let size = SizeFont(rawValue: Double(FontManager.shared.currentFontStyle.contentFontSize))
                
                AppSettings.settingFont = setting ?? SettingFont(size: size ?? SizeFont.onehundred, name: NameFont.hiraginoSansW4, isEnableButton: true, autoSave: false)
                
                return AppSettings.settingFont ?? SettingFont(size: size ?? SizeFont.onehundred, name: NameFont.hiraginoSansW4, isEnableButton: true, autoSave: false)
            }
        
        let updateSettingFont = self.navigator.callBackSetting().asDriverOnErrorJustComplete()
        
        //Update setting font
        let settingFont = Driver.merge(getSettingFont, updateSettingFont)
            .do { setting in
                attributeCache = TextAttributeString(textSearch: attributeCache.textSearch,
                                                     attributedString: attributeCache.attributedString,
                                                     textFont: setting.getFont(),
                                                     contentText: attributeCache.contentText,
                                                     baseOnAttrs: attributeCache.baseOnAttrs,
                                                     settingFont: attributeCache.settingFont)
            }
        
        let shareSettingFont = self.navigator.actionShare()
            .do(onNext: self.navigator.dismissSettingFontView)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(Driver.combineLatest(title, content))
            .filter({ !$0.1.text.isEmpty })
            .do(onNext: { (title, content) in
                eventResetScrollTapReplace.onNext(())
                self.navigator.toShareView(title: title.text, content: content.text)
            })
            .mapToVoid()
        
        let getSettingSearch = Driver.just(self.useCase.getSettingSearch())
            .map { setting -> SettingSearch in
                AppSettings.settingSearch = setting ?? SettingSearch(isSearch: true,
                                                                     isReplace: false,
                                                                     billingStatus: .free)
                
                return AppSettings.settingSearch ?? SettingSearch(isSearch: true,
                                                                  isReplace: false,
                                                                  billingStatus: .free)
            }
        
        let updateSettingSearch = self.navigator.callBackSettingSearch().asDriverOnErrorJustComplete()
        let eventUpdateSearch = AppManager.shared.eventUpdateSearch
            .asDriverOnErrorJustComplete()
        
        
        let settingSearch = Driver.merge(getSettingSearch, updateSettingSearch, eventUpdateSearch)
        
        let showSettingSearch = input.tapTriggerHeader
            .filter{ $0 == .setting || $0 == .settingSearch }
            .flatMap { tap -> Driver<Bool> in
                eventResetScrollTapReplace.onNext(())
                switch tap {
                case .setting:
                    self.navigator.dismissSettingSearchView()
                    return Driver.just(false)
                    
                case .settingSearch:
                    self.navigator.toSettingSearch()
                    return Driver.just(true)
                    
                default:
                    return Driver.just(false)
                }
            }
        
        let eventDismissSettingSearch = self.navigator.triggerDismissSettingSearchView().asDriverOnErrorJustComplete()

        let dismissSettingSearchView = Driver.merge(input.enterEditingMode,
                                                    input.tapTriggerHeader.filter{ $0 == .unSearch }.mapToVoid(),
                                                    input.tapViewCoverSettingSearch
                                                    )
            .do(onNext: self.navigator.dismissSettingSearchView)
        
        
        let isShowSettingSearch = Driver.merge(showSettingSearch, eventDismissSettingSearch)
        
        
        
        
        let updateListSearchWithEmpty = input.updateListSearchWithEmpty
            .do { _ in
                listUpdatePosition.onNext([])
                updateIndex.onNext(CurrentIndex(currentIndex: nil, isScroll: false, times: 1))
                eventResetScrollTapReplace.onNext(())
            }
        
        
        let getAttributeLoadFirst = input.getAttributeLoadFirst
            .do { (item) in
                if let i = item {
                    attributeCache = i
                }
            }
        
        let resetAttributedString = Driver.merge(input.enterEditingMode.map { _ in false },
                                                 input.updateListSearchWithEmpty.map { _ in true })
            .map { keepStatusViewSearch -> (NSMutableAttributedString, Bool) in
                eventResetScrollTapReplace.onNext(())
                //reset attributed
                let attributes = attributeCache.getContentAttsSearch(statusHighlight: .other)
                let attributedQuote = NSMutableAttributedString(string: attributeCache.contentText, attributes: attributes)

                attributeCache = TextAttributeString(textSearch: attributeCache.textSearch,
                                                     attributedString: attributedQuote,
                                                     textFont: attributeCache.textFont,
                                                     contentText: attributeCache.contentText,
                                                     baseOnAttrs: attributeCache.baseOnAttrs,
                                                     settingFont: attributeCache.settingFont)
                return (attributedQuote, keepStatusViewSearch)
            }
        
        let updateTextViewContent = input.updateTextViewContent
            .do { item in
                if let i = item {
                    attributeCache = i
                }
            }
            .mapToVoid()
        
        let eventTextOverMaxLenght = input.eventTextOverMaxLenght
            .asObservable()
//            .flatMap{ _ in self.navigator.showMessage(L10n.Creation.overLenght).asDriverOnErrorJustComplete() }
            .withLatestFrom(input.eventTextOverMaxLenght, resultSelector: { $1 })
            .asDriverOnErrorJustComplete()
        
        let eventShowAlertMaxLenght = input.eventShowAlertMaxLenght
            .asObservable()
//            .flatMap{ _ in self.navigator.showMessage(L10n.Creation.overLenght).asDriverOnErrorJustComplete() }
            .flatMap({ handleReplace -> Driver<Void> in
                var msg: String
                updateIndex.onNext(CurrentIndex(currentIndex: currentPosition, isScroll: true, times: 1))
                
                switch handleReplace.pasteOverLength {
                case .paste:
                    msg = L10n.Creation.overLenght
                case .replace:
                    msg = L10n.Creation.overLenghtReplace
                case .inputText, .saveDraftOver, .dismissDraft:
                    msg = L10n.Creation.overLenghtInput
                }
               return self.navigator.showMessage(msg).asDriverOnErrorJustComplete()
            })
            .withLatestFrom(input.eventShowAlertMaxLenght, resultSelector: { $1 })
            .asDriverOnErrorJustComplete()
        
        let doEventResetScrollTapReplace = eventResetScrollTapReplace.asDriverOnErrorJustComplete()
            .do { _ in
                doNotScrollWhenTap = true
                detectLastIndexWhenTap = nil
                detectFirstIndexWhenTap = nil
            }

        let eventShowAlertTitleMaxLenght = input.eventShowAlertTitleMaxLenght
            .asObservable()
            .flatMap({ rangeSelect -> Driver<Void> in
               return self.navigator.showMessage(L10n.Creation.overTitleLenghtInput).asDriverOnErrorJustComplete()
            })
            .withLatestFrom(input.eventShowAlertTitleMaxLenght, resultSelector: { $1 })
            .asDriverOnErrorJustComplete()
        
        let eventHeightSettingFont = onCloud.map { ($0) ? SettingCoordinator.Constant.heightViewiCloud : SettingCoordinator.Constant.heightViewLocal }
        
        let otherCodeTrigger = savedDraft.otherCodeTrigger
            .do { value in
                otherCode = value
            }
            .mapToVoid()

        
        let showPremium = AppManager.shared.eventShouldAddStorePayment
            .do { isShow in

                if isShow && AppManager.shared.getCurrentScene() == .create {
                    self.navigator.moveToRegisterPremium()
                    AppManager.shared.eventShouldAddStorePayment.onNext(false)
                }
            }.asDriverOnErrorJustComplete().mapToVoid()
        
        let autoSaveBackUp = onCloud
            .filter { $0 }
            .flatMap { _ in self.useCase.getSettingBackUp(settingKey: SettingBackupModel.SettingKey.backupSettings.textParam) }
            .compactMap { $0 }
            .filter { ($0.isPeriodicBackup ?? false) }
            .asDriverOnErrorJustComplete()
            .flatMap { setting -> Driver<Void> in
                return self.saveAutoBackUp(title: title.map({ $0.text }),
                                                     content: content.map({ $0.text }),
                                                     cursorPosition: input.cursorPosition,
                                                     dismissTrigger: input.dismissTrigger,
                                                     oldDraft: updatedDocumentTrigger.asDriverOnErrorJustComplete(),
                                                     settingBackupModel: setting)
            }
        
                
        return Output(
            title: title,
            content: content,
            lastCursorPosition: lastCursorPosition,
            hasData: hasData,
            hasChanged: hasChanged,
            numberOfCharacter: numberOfCharacters,
            keyboardHeight: keyboardHeight,
            presentedViewHeight: presentedViewHeight,
            share: share,
            showProgress: showProgress,
            showIdiom: showIdiomData,
            showThesaurus: showThesaurusData,
            showDictionary: showDictionary,
            dismiss: dismiss,
            dismissSuggestion: dismissSuggestion,
            hideProgressBar: hideProgressBar,
            lastSaveDraft: lastSaveDraft,
            showTooltip: showTooltip,
            autoHideTooltips: autoHideTooltips,
            error: error,
            cancelRequestAPI: cancelRequestAPI,
            findTagOnTitle: findTagOnTitleTrigger.asDriverOnErrorJustComplete(),
            findTagOnContent: findTagOnContentTrigger.asDriverOnErrorJustComplete(),
            loadFontData: loadFontData,
            showOrHideFontStyleView: showOrHideFontStyleView,
            changedFontStyle: changedFontStyle,
            isRotation: isRotation,
            serverErrorHandler: savedDraft.error,
            loadingFullScreen: activityIndicator.asDriver(),
            showToast: savedDraft.showToast,
            deleteCloudDraft: deleteCloudDraft,
            showBanner: showBanner,
            tapTriggerHeader: tapTriggerHeader,
            textSearchTrigger: textSearchTrigger,
            listPositionSearch: listPositionSearch,
            tapTriggerSearch: tapTriggerSearch,
            currentIndex: getCurrentIndex,
            settingFont: settingFont,
            shareSettingFont: shareSettingFont,
            isShowSettingView: isShowSettingView,
            dismissSettingView: dismissSettingView,
            settingSearch: settingSearch,
            isShowSettingSearch: isShowSettingSearch,
            dismissSettingSearchView: dismissSettingSearchView,
            textReplace: textReplace,
            resetAttributedString: resetAttributedString,
            updateTextViewContent: updateTextViewContent,
            actionUndoReplace: actionUndoReplace,
            eventTextOverMaxLenght: eventTextOverMaxLenght,
            eventShowAlertMaxLenght: eventShowAlertMaxLenght,
            errorHandler: errorHandler,
            detectData: detectData,
            getAttributeLoadFirst: getAttributeLoadFirst,
            updateListSearchWithEmpty:  updateListSearchWithEmpty,
            doEventResetScrollTapReplace: doEventResetScrollTapReplace,
            doEventLastIndex: eventLastIndex.asDriverOnErrorJustComplete(),
            eventUpdateListRangeWhenReplace: eventUpdateListRangeWhenReplace,
            updateTextViewReplaceAll: updateTextViewReplaceAll.asDriverOnErrorJustComplete(),
            eventShowAlertTitleMaxLenght: eventShowAlertTitleMaxLenght,
            eventHeightSettingFont: eventHeightSettingFont.asDriverOnErrorJustComplete(),
            autoSaveCloud: autoSaveCloud,
            disableAutoSave: disableAutoSave,
            statusLoading: statusLoading,
            otherCodeTrigger: otherCodeTrigger,
            positionCursorAutoSave: positionCursorAutoSave,
            showPremium: showPremium,
            enableAutoSaveCloud: willEnterForegroundTrigger.mapToVoid(),
            reloadContent: reloadContent,
            errorReloadDraft: savedDraft.errorReloadDraft,
            resetCursor: resetCursor.asDriverOnErrorJustComplete(),
            doBackUp: autoSaveBackUp,
            isCallAutoSave: eventEnableAutoSave.asDriverOnErrorJustComplete()
        )
    }
    
    private func nextIndexAfterTapReplace(tap: CreationViewController.TapHeader, index: Int, list: [NSRange]) -> (NSRange, Bool) {
        var i: Int = index
        switch tap {
        case .next:
            i = index
            
            if index >= list.count {
                i = index
//                        return list.first
            }
            
        case .previous:
            i = index - 1
            
            if index <= 0 {
                i = 0
            }
            
        default: break
        }
        return (list[i], true)
    }
    
    private func highlightWhenTapReplace(item: CreationViewController.TextReplace,
                                         list: [NSRange],
                                         index: Int,
                                         updateIndex: PublishSubject<(NSRange?, Bool)>,
                                         indexCurrentReplace: inout Int?,
                                         attributeCache: inout TextAttributeString,
                                         currentPosition: inout NSRange
    ) -> (TextAttributeString?, NSRange?) {
        switch item.tap {
        case .replace:
             var i = index
            
            if index >= list.count {
                i = list.count - 1
//                        return list.first
            }
            updateIndex.onNext((list[i], true))
            indexCurrentReplace = nil
            
            let myMutableString = self.updateTextHighlightReplace(attributeCache: attributeCache,
                                                                  range: list[i])

            attributeCache = TextAttributeString(textSearch: attributeCache.textSearch,
                                                 attributedString: myMutableString,
                                                 textFont: attributeCache.textFont,
                                                 contentText: attributeCache.contentText,
                                                 baseOnAttrs: attributeCache.baseOnAttrs,
                                                 settingFont: attributeCache.settingFont
                                                 )

            currentPosition = list[i]
        default: break
        }
        
        return (attributeCache, nil)
    }
    
    private func updateTextHighlightReplace(attributeCache: TextAttributeString, range: NSRange) -> NSMutableAttributedString {
        var myMutableString = NSMutableAttributedString()

        let attributes2 = attributeCache.getContentAttsSearch(statusHighlight: .replace)
        
        myMutableString = NSMutableAttributedString(attributedString: attributeCache.attributedString)
        myMutableString.setAttributes(attributes2, range: range)
        return myMutableString
    }
    
    private func setAttributedString(background: UIColor,
                                     font: UIFont,
                                     foreground: UIColor,
                                     para: NSParagraphStyle
                                     ) -> [NSAttributedString.Key : NSObject] {
        return [NSAttributedString.Key.backgroundColor: background,
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: foreground,
                NSAttributedString.Key.paragraphStyle: para
        ]
    }
    
    private func updateListRange(listRange: [NSRange], currentPosition: NSRange, different: Int) -> [NSRange] {
        var updateList = listRange
        if let index = listRange.firstIndex(where: { $0.location == currentPosition.location }) {
            updateList.remove(at: index)
        }
        
        return updateList.map{ NSRange(location: ($0.location > currentPosition.location) ? ($0.location + different) : $0.location,
                                       length: $0.length) }
        
    }
    
    private func getListRange(textSearch: String, att: NSMutableAttributedString) ->[NSRange]  {
        var listTextSearch: [String] = []
        listTextSearch.append(textSearch)
        var l: [NSRange] = []
        for item in listTextSearch {
            l += self.useCase.listPositionSearch(source: att, searchText: String(item))
        }
        return l
    }
    
    func presentationViewHandle() -> Observable<PresentAnim> {
        let willShowTrigger = NotificationCenter.default.rx
            .notification(Notification.Name.willPresentSuggestion)
            .map({ Notification.Name.decodeBottomPresentation(notification: $0) })
        
        let willDismissTrigger = NotificationCenter.default.rx
            .notification(Notification.Name.willDismissSuggestion)
            .map({ Notification.Name.decodeBottomPresentation(notification: $0) })
        
        return Observable.from([willShowTrigger, willDismissTrigger])
            .merge()
            .map { PresentAnim(height: $0.height, duration: $0.duration) }
    }
    
    func createNewDocument(title: String, content: String, cursorPosition: Int, forcedSaving: Bool, oldDraft: Document, manualIndex:  Int?) -> Document? {
//        let newTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
//        let newContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
//
//        if newTitle.isEmpty && newContent.isEmpty {
//            return nil
//        }
        
        // saves in case users have changed either title or content
        let updatedDataCondition = title != oldDraft.title || content != oldDraft.content || cursorPosition != oldDraft.cursorPosition

        // saves in case users create a new ones or they remove both title and content, the reasion is it's going to create a removing animation on the draft screen
//        let isNewDraft = title == "" && content == ""

        if forcedSaving || updatedDataCondition {
            var newDocument = oldDraft
            newDocument.title = title
            newDocument.content = content
            newDocument.cursorPosition = cursorPosition
            if let manualIndex = manualIndex {
                newDocument.manualIndex = manualIndex
            }
            return newDocument
        }

        return nil
    }
    private func deleteDraftFlow(deleteDraft: Driver<Document>,
                                 activityIndicator: ActivityIndicator) -> Driver<Void> {
        let retry = BehaviorRelay<Int>(value: 0)
        let errorTracker = ErrorTracker()
        let errorHandler = errorTracker
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .terminalRegistration:
                        if var userInfo = AppManager.shared.userInfo.value, userInfo.deviceStatus != .unregistered {
                            userInfo.deviceStatus = .unregistered
                            AppManager.shared.userInfo.accept(userInfo)
                        }
                        
                        return self.navigator
                            .showMessage(L10n.Server.Error.unregisteredDevice)
                            .asDriverOnErrorJustComplete()
                            .do(onNext: {
                                self.navigator.dismiss()
                            })
                        
                    case .maintenance, .maintenanceCannotUpdate:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.Delete.maintenance)
                            .asDriverOnErrorJustComplete()
                            .do(onNext: {
                                self.navigator.dismiss()
                            })
                        
                    case .sessionTimeOut:
                        return self.useCase.refreshSession()
                            .catchError({ (error) -> Observable<Void> in
                                return self.navigator
                                    .showMessage(L10n.Sdk.Error.Refresh.session)
                                    .observeOn(MainScheduler.instance)
                                    .do(onNext: self.navigator.toForceLogout)
                                    .flatMap({ Observable.empty() })
                            })
                            .do(onNext: {
                                if retry.value == 0 {
                                    retry.accept(1)
                                }
                            })
                            .asDriverOnErrorJustComplete()
                        
                    case .otherError(let errorCode):
                        return self.navigator
                            .showMessage(errorCode: errorCode)
                            .asDriverOnErrorJustComplete()
                            .do(onNext: {
                                self.navigator.dismiss()
                            })
                        
                    default:
                        self.navigator.dismiss()
                        return Driver.empty()
                    }
                }
                
                return self.navigator
                    .showMessage(L10n.Server.Error.timeOut)
                    .asDriverOnErrorJustComplete()
                    .do(onNext: {
                        self.navigator.dismiss()
                    })
            })
            
        
        let userAction = deleteDraft
            .mapToVoid()
            .do(onNext: {
                retry.accept(0)
            })
        
        let retryAction = retry.asDriver()
            .filter({ $0 > 0 })
            .mapToVoid()
        
        let deleteDrafts = Driver.merge(userAction, retryAction)
            .withLatestFrom(deleteDraft)
            .flatMap({ (draft) -> Driver<Void> in
                // Delete drafts on Cloud
                return self.useCase.deleteCloudDocument(draft.id)
                    .trackActivity(activityIndicator)
                    .trackError(errorTracker)
                    .asDriverOnErrorJustComplete()
            })
            .do(onNext: {
                self.navigator.dismiss()
            })
        
        return Driver.merge(deleteDrafts, errorHandler)
    }
    
    private func saveAutoBackUp(title: Driver<String>,
                                content: Driver<String>,
                                cursorPosition: Driver<Int>,
                                dismissTrigger: Driver<Void>,
                                oldDraft: Driver<Document>,
                                settingBackupModel: SettingBackupModel) -> Driver<Void> {
        
        let newSavingData = Driver
            .combineLatest(
                title,
                content,
                cursorPosition,
                oldDraft,
                resultSelector: {(title: $0, content: $1, cursorPosition: $2, oldDraft: $3)})
        
        let retry = BehaviorRelay<Int>(value: 0)
        let retryAction = retry.asDriver()
            .filter({ $0 > 0 })
            .mapToVoid()
        let errorTracker = ErrorTracker()
        let autoSavingTrigger = useCase.autoSavingBackUpTrigger(value: settingBackupModel.interval ?? 600)
            .takeUntil(dismissTrigger.asObservable())

        let doAutoSaveBackUp = Observable.merge(retryAction.asObservable(), autoSavingTrigger)
            .withLatestFrom(newSavingData)
            .map({ (title: String, content: String, cursorPosition: Int, oldDraft: Document) -> Document in
                var new = oldDraft
                new.title = title
                new.content = content
                new.cursorPosition = cursorPosition
                return new
            })
            .flatMap { doc -> Observable<Void> in
                return self.useCase.addBackUp(document: doc).trackError(errorTracker)
            }
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        
        let errorTrackerAutoSaveBackUp = errorTracker
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .terminalRegistration:
                        if var userInfo = AppManager.shared.userInfo.value, userInfo.deviceStatus != .unregistered {
                            userInfo.deviceStatus = .unregistered
                            AppManager.shared.userInfo.accept(userInfo)
                        }
                        
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.unregisteredDevice)
                            .asDriverOnErrorJustComplete()
                        
                    case .draftNotFound:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.draftNotFound)
                            .asDriverOnErrorJustComplete()
                            .mapToVoid()
                        
                    case .maintenance, .maintenanceCannotUpdate:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.Delete.maintenance)
                            .asDriverOnErrorJustComplete()
                        
                    case .sessionTimeOut:
                        return self.useCase.refreshSession()
                            .catchError({ (error) -> Observable<Void> in
                                return self.navigator
                                    .showMessage(L10n.Sdk.Error.Refresh.session)
                                    .observeOn(MainScheduler.instance)
                                    .do(onNext: self.navigator.toForceLogout)
                                    .flatMap({ Observable.empty() })
                            })
                            .do(onNext: {
                                if retry.value == 0 {
                                    retry.accept(1)
                                }
                            })
                            .asDriverOnErrorJustComplete()
                                
                    case .authenticationError:
                        return self.useCase.logout()
                            .subscribeOn(MainScheduler.instance)
                            .do(onNext: self.navigator.toForceLogout)
                            .asDriverOnErrorJustComplete()
                        
                    case .otherError(let errorCode):
                        return self.navigator
                            .showMessage(errorCode: errorCode)
                            .asDriverOnErrorJustComplete()
                        
                    default:
                        return Driver.empty()
                    }
                }
                
                return self.navigator
                    .showMessage(L10n.Server.Error.timeOut)
                    .asDriverOnErrorJustComplete()
            })
        
        return Driver.merge(errorTrackerAutoSaveBackUp, doAutoSaveBackUp)
        
    }
    
    func saveDraft(saveTrigger: Driver<Void>,
                   title: Driver<String>,
                   content: Driver<String>,
                   cursorPosition: Driver<Int>,
                   oldDraft: Driver<Document>,
                   dismissTrigger: Driver<Void>,
                   activityIndicator: ActivityIndicator,
                   autoSaveCloud: Driver<Void>,
                   enableAutoSave: PublishSubject<Bool>,
                   autoSaveCount: Disposable?,
                   resetCursor: PublishSubject<Void>)
    -> (lastSaveDraft: Driver<Document>,
        deleteDraft: Driver<Void>,
        showToast: Driver<Void>,
        error: Driver<Void>,
        dismiss: Driver<Void>,
        otherCodeTrigger: Driver<Bool>,
        reloadDraft: Driver<Document>,
        errorReloadDraft: Driver<Void>) {
        
        let newSavingData = Driver
            .combineLatest(
                title,
                content,
                cursorPosition,
                oldDraft,
                resultSelector: {(title: $0, content: $1, cursorPosition: $2, oldDraft: $3)})
        
        // true: overwrite
        let retry = BehaviorRelay<Int>(value: 0)
        let overwriteCloudDraft = BehaviorSubject<Bool>(value: false) // true: overwrite
        let saveToLocal = PublishSubject<Void>()
        let deleteDraftTrigger = PublishSubject<Void>()
        let otherCodeTrigger = PublishSubject<Bool>()
        let reloadDraftTrigger = PublishSubject<Document>()
        let isDismissDraft =  BehaviorSubject<Bool>(value: false)
        var isCallAutoSave = false

        _ = dismissTrigger.asObservable().subscribe(onNext: { _ in
            isDismissDraft.onNext(true)
        })

        let dismiss = PublishSubject<Void>()
        
        let errorTracker = ErrorTracker()
        let errorReloadDraftHandler = errorTracker
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .terminalRegistration:
                        if var userInfo = AppManager.shared.userInfo.value, userInfo.deviceStatus != .unregistered {
                            userInfo.deviceStatus = .unregistered
                            AppManager.shared.userInfo.accept(userInfo)
                        }
                        
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.unregisteredDevice)
                            .asDriverOnErrorJustComplete()
                        
                    case .draftNotFound:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.draftNotFound)
                            .asDriverOnErrorJustComplete()
                            .do(onNext: { _ in                                
                                self.navigator.reloadCloudDrafts()
                                dismiss.onNext(())
                            })
                            .mapToVoid()
                        
                    case .maintenance, .maintenanceCannotUpdate:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.Delete.maintenance)
                            .asDriverOnErrorJustComplete()
                        
                    case .sessionTimeOut:
                        return self.useCase.refreshSession()
                            .catchError({ (error) -> Observable<Void> in
                                return self.navigator
                                    .showMessage(L10n.Sdk.Error.Refresh.session)
                                    .observeOn(MainScheduler.instance)
                                    .do(onNext: self.navigator.toForceLogout)
                                    .flatMap({ Observable.empty() })
                            })
                            .do(onNext: {
                                if retry.value == 0 {
                                    retry.accept(1)
                                }
                            })
                            .asDriverOnErrorJustComplete()
                                
                    case .authenticationError:
                        return self.useCase.logout()
                            .subscribeOn(MainScheduler.instance)
                            .do(onNext: self.navigator.toForceLogout)
                            .asDriverOnErrorJustComplete()
                        
                    case .otherError(let errorCode):
                        return self.navigator
                            .showMessage(errorCode: errorCode)
                            .asDriverOnErrorJustComplete()
                        
                    default:
                        return Driver.empty()
                    }
                }
                
                return self.navigator
                    .showMessage(L10n.Server.Error.timeOut)
                    .asDriverOnErrorJustComplete()
            })
        
        let serverError = ErrorTracker()
        let serverErrorHandler = serverError
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                isCallAutoSave = false
                enableAutoSave.onNext(false)
                if let error = error as? GooServiceError {
                    switch error {
                    case .terminalRegistration:
                        // have not registered device yet, save it on uncategorized folder
                        if var userInfo = AppManager.shared.userInfo.value, userInfo.deviceStatus != .unregistered {
                            userInfo.deviceStatus = .unregistered
                            AppManager.shared.userInfo.accept(userInfo)
                        }
                        
                        return self.showErrorFlow(message: L10n.Creation.Error.unregisteredDevice,
                                                  saveTrigger: saveToLocal,
                                                  dismissTrigger: dismiss,
                                                  otherCodeTrigger: otherCodeTrigger)
                        
                    case .executionError:
                        // draft has been updated, do you want to overwrite it?
                        return self.navigator
                            .showConfirmMessage(L10n.Creation.Error.execution,
                                                noSelection: L10n.Alert.thisDevices,
                                                yesSelection: L10n.Alert.otherDevices)
                            .flatMap({ selection -> Observable<Void> in
                                if !selection {
                                    overwriteCloudDraft.onNext(true)
                                    retry.accept(1)
                                    
                                    return Observable.empty()
                                } else {
                                    return isDismissDraft.asObservable().flatMapLatest({ isDismiss  -> Observable<Void> in
                                        if isDismiss {
                                            dismiss.onNext(())
                                            return Observable.empty()
                                        } else {
                                            return self.useCase.fetchDraftDetail(draft: document)
                                                .trackActivity(activityIndicator)
                                                .trackError(errorTracker)
                                                .flatMap { document -> Driver<Void> in
                                                    resetCursor.onNext(())
                                                    reloadDraftTrigger.onNext(document)
                                                    return Driver.just(())
                                            }
                                        }
                                    })

                                }
                            })
                            .asDriverOnErrorJustComplete()
                        
                    case .limitRegistrtion:
                        // reach to the limitation, save it on uncategorized folder
                        
                        var msg: String
                        if AppManager.shared.billingInfo.value.billingStatus == .paid {
                            msg = L10n.Creation.Error.limitationPaid
                        } else {
                            msg = L10n.Creation.Error.limitation
                        }
                        
                        
                        return showErrorFlow(message: msg,
                                             saveTrigger: saveToLocal,
                                             dismissTrigger: dismiss,
                                             otherCodeTrigger: otherCodeTrigger)
                        
                    case .folderNotFound:
                        // the folder has not existed, save the draft to the uncategorized folder (local)
                        return showErrorFlow(message: L10n.Creation.Error.folderNotFound,
                                             saveTrigger: saveToLocal,
                                             dismissTrigger: dismiss,
                                             otherCodeTrigger: otherCodeTrigger)
                        
                    case .maintenance, .maintenanceCannotUpdate, .authenticationError:
                        // save to an uncategorized folder on your device (local)
                        return showErrorFlow(message: L10n.Creation.Error.maintenance,
                                             saveTrigger: saveToLocal,
                                             dismissTrigger: dismiss,
                                             otherCodeTrigger: otherCodeTrigger)
                            
                    case .sessionTimeOut:
                        // refresh session and retry
                        return self.useCase.refreshSession()
                            .catchError({ (error) -> Observable<Void> in
                                return self.navigator
                                    .showMessage(L10n.Sdk.Error.Refresh.session)
                                    .observeOn(MainScheduler.instance)
                                    .do(onNext: self.navigator.toForceLogout)
                                    .flatMap({ Observable.empty() })
                            })
                            .asDriverOnErrorJustComplete()
                            .do(onNext: { _ in
                                if retry.value == 0 {
                                    retry.accept(1)
                                }
                            })
                        
                    case .otherError(let errorCode):
                        // save to an uncategorized folder on your device (local)
                        return showErrorFlow(message: L10n.Creation.Error.Other.message,
                                             errorCode: errorCode,
                                             saveTrigger: saveToLocal,
                                             dismissTrigger: dismiss,
                                             otherCodeTrigger: otherCodeTrigger)
                        
                    default:
                        return Driver.empty()
                    }
                }
                
                return self.navigator.showMessage(L10n.Creation.Error.timeOut)
                    .flatMap({ (_) in
                        return self.navigator
                        .showConfirmMessage(L10n.Creation.closeDraftWithoutSaving)
                        .do(onNext: { close in
                            if close {
                                dismiss.onNext(())
                            } else {
                                otherCodeTrigger.onNext(true)
                            }
                            
                        })
                        .mapToVoid()
                    })
                    .asDriverOnErrorJustComplete()
            })
    
        let updatedLocalDocument: Driver<Document>
        let updatedCloudDocument: Driver<Document>
        let showToast: Driver<Void>
        let didEnterBackgroundTrigger = NotificationCenter.default.rx
            .notification(UIApplication.didEnterBackgroundNotification)
            .filter{ _ in  return !isCallAutoSave}
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        if case .cloud(_) = document.folderId {
            let userAction = Driver
                .merge(
                    dismissTrigger.map({ SavingType.close }),
                    saveTrigger.map({ SavingType.required }),
                    didEnterBackgroundTrigger.map({ SavingType.required }),
                    autoSaveCloud.map{ SavingType.required }
                )
                .filter { type in
                    if type == .close && isCallAutoSave{
                        dismiss.onNext(())
                        return false
                    }
                    return true
                }
                .do(onNext: { _ in
                    overwriteCloudDraft.onNext(false)
                    retry.accept(0)
                })
                
            let retryAction = retry.asDriver()
                .filter({ $0 > 0 })
                .mapToVoid()
            
            let cloudSavingData = Driver
                .combineLatest(
                    userAction,
                    newSavingData,
                    overwriteCloudDraft.asDriverOnErrorJustComplete())
            
            updatedCloudDocument = Driver.merge(userAction.mapToVoid(), retryAction)
                .withLatestFrom(cloudSavingData)
                .map({ (type: $0.0, value: $0.1, overwrite: $0.2) })
                .flatMap({ data -> Driver<Document> in
                    let isForcedSaving = data.type == .required
                    
                    if data.value.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && data.value.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        if data.type == .close {
                            if !data.value.oldDraft.title.isEmpty || !data.value.oldDraft.content.isEmpty {
                                deleteDraftTrigger.onNext(())
                            } else {
                                dismiss.onNext(())
                            }
                        }
                        isCallAutoSave = false
                        enableAutoSave.onNext(false)
                        return Driver.empty()
                    }
                    if let document = self.createNewDocument(title: data.value.title,
                                                             content: data.value.content,
                                                             cursorPosition: data.value.cursorPosition,
                                                             forcedSaving: isForcedSaving,
                                                             oldDraft: data.value.oldDraft,
                                                             manualIndex: nil) {
                        let updateDate = data.value.title != data.value.oldDraft.title || data.value.content != data.value.oldDraft.content
                        enableAutoSave.onNext(true)
                        isCallAutoSave = true
                        self.useCase.disableAutoSaveCloud(autoSaveCount: autoSaveCount)
                        return self.useCase.updateCloudDocument(document, overwrite: data.overwrite, reuseLastUpdate: !updateDate)
                            .map({ (date) -> Document in
                                var newDocument = document
                                newDocument.updatedAt = date
                                return newDocument
                            })
                            .trackActivity(activityIndicator)
                            .trackError(serverError)
                            .do(onNext: { draft in
                                isCallAutoSave = false
                                otherCodeTrigger.onNext(false)
                                if data.type == .close {
                                    dismiss.onNext(())
                                } else {
                                    enableAutoSave.onNext(false)
                                }
                            })
                            .asDriverOnErrorJustComplete()
                    }

                    // make sure it's the close button pressed
                    isCallAutoSave = false
                    enableAutoSave.onNext(false)
                    dismiss.onNext(())
                    return Driver.empty()
                })
            
            updatedLocalDocument = saveToLocal
                .withLatestFrom(newSavingData)
                .asObservable()
                .flatMap({ (title: String, content: String, cursorPosition: Int, oldDraft: Document) -> Observable<Document> in
                    if let document = self.createNewDocument(title: title,
                                                             content: content,
                                                             cursorPosition: cursorPosition,
                                                             forcedSaving: true,
                                                             oldDraft: oldDraft,
                                                             manualIndex: nil) {
                        var newDocument = document.duplicate()
                        newDocument.folderId = FolderId.local("")
                        return self.useCase.update(document: newDocument, updateDate: true)
                            .catchError({ (error) -> Observable<Void> in
                                return self.navigator
                                    .showMessage(L10n.Error.otherErrorAtLocal)
                                    .flatMap({ Observable.empty() })
                            })
                            .map({ newDocument })
                            .do(onNext: { _ in
                                dismiss.onNext(())
                            })
                    }
                    
                    return Observable.empty()
                })
                .asDriverOnErrorJustComplete()
            
            showToast = updatedCloudDocument
                .mapToVoid()
        } else {
            /// saving a document
            /// - after `x` seconds (auto-saving)
            /// - changes to another apps (enter background)
            /// - exits the creation screen.
            /// - save trigger (user interaction)
            let autoSavingTrigger = useCase.autoSavingTrigger()
                .takeUntil(dismissTrigger.asObservable())
                .asDriverOnErrorJustComplete()
            
            updatedCloudDocument = Driver.empty()
            
            let saveLocalDocument = Driver.merge(dismissTrigger.map({ SavingType.close }),
                                                didEnterBackgroundTrigger.map({ SavingType.auto }),
                                                autoSavingTrigger.map({ SavingType.auto }),
                                                saveTrigger.map({ SavingType.required }))
                .withLatestFrom(newSavingData, resultSelector: { (type: $0, value: $1) })
                .flatMapLatest({ (data) -> Driver<(document: Document?, type: SavingType)> in
                    let isForcedSaving = data.type == SavingType.required
                    
                    if data.value.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && data.value.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        if (data.type != .close) || (data.value.oldDraft.title.isEmpty && data.value.oldDraft.content.isEmpty) {
                            return Driver.just((document: nil, type: data.type))
                        }
                    }
                    
                    let checkIsDocument = self.useCase.checkIsDocument(document: data.value.oldDraft)
                    let valueManualIndex = self.updateManualIndex(folder: self.folder, isCheckDoc: checkIsDocument, oldValueIndex: data.value.oldDraft.manualIndex)
                    self.navigator.saveDraftType(type: data.type)
                    if let document = self.createNewDocument(title: data.value.title,
                                                             content: data.value.content,
                                                             cursorPosition: data.value.cursorPosition,
                                                             forcedSaving: isForcedSaving,
                                                             oldDraft: data.value.oldDraft,
                                                             manualIndex: valueManualIndex) {
                        
                        let updateDate = data.value.title != data.value.oldDraft.title || data.value.content != data.value.oldDraft.content
                        
                        return self.useCase.update(document: document, updateDate: updateDate)
                            .map({ document })
//                            .map({ (document: $0, type: data.type) })
                            .map({ doc -> (Document, SavingType) in
                                self.addIndexToUncategorized(document: doc)
                                return (doc, data.type)
                            })
                            .asDriverOnErrorJustComplete()
                    }
                    
                    return Driver.just((document: nil, type: data.type))
                })
                .do(onNext: { _, type in
                    if type == .close {
                        dismiss.onNext(())
                    }
                })
                
            updatedLocalDocument = saveLocalDocument
                .map({ $0.document })
                .compactMap({ $0 })
            
            showToast = saveLocalDocument
                .filter({ (doc, type) -> Bool in
                    if type == .required, let doc = doc {
                        let newContent = doc.content.trimmingCharacters(in: .whitespacesAndNewlines)
                        let newTitle = doc.title.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        return !(newContent.isEmpty && newTitle.isEmpty)
                    }
                    
                    return false
                })
                .mapToVoid()
        }
        
        return (lastSaveDraft: Driver.merge(updatedLocalDocument, updatedCloudDocument),
                deleteDraft: deleteDraftTrigger.asDriverOnErrorJustComplete(),
                showToast: showToast,
                error: serverErrorHandler,
                dismiss: dismiss.asDriverOnErrorJustComplete(),
                otherCodeTrigger: otherCodeTrigger.asDriverOnErrorJustComplete(),
                reloadDraft: reloadDraftTrigger.asDriverOnErrorJustComplete(),
                errorReloadDraft: errorReloadDraftHandler)
    }
    
    private func addIndexToUncategorized(document: Document) {
        switch document.folderId {
        case .none: break
        case .local(let id):
            if id.isEmpty {
                let manualindex: FolderDataSourceProxy.ManualIndex = FolderDataSourceProxy.ManualIndex(id: document.id , index: 999)
                if (AppSettings.draftManualIndex.firstIndex(where: { $0.id == manualindex.id }) == nil) {
                    AppSettings.draftManualIndex.insert(manualindex, at: 0)
                }
                
                if (AppSettings.draftManualIndexUncategorized.firstIndex(where: { $0.id == manualindex.id }) == nil) {
                    AppSettings.draftManualIndexUncategorized.insert(manualindex, at: 0)
                }
            }
        case .cloud: break
        }
    }
    
    private func updateManualIndex(folder: Folder?, isCheckDoc: Bool, oldValueIndex: Int?) -> Int? {
        guard let folder = folder else {
            return nil
        }
        
        switch folder.id {
        case .none, .cloud: return nil
        case .local(let id):
            if id.isEmpty {
                return nil
            } else if isCheckDoc {
                return oldValueIndex
            } else {
                return (self.findMax(docs: folder.documents) ?? 0) + 1
            }
        }
    }
    
    private func findMax(docs: [Document] ) -> Int? {
        return docs.map{ $0.manualIndex }.compactMap { $0 }.max()
    }
    
    func showErrorFlow(message: String,
                       errorCode: String? = nil,
                       saveTrigger: PublishSubject<Void>,
                       dismissTrigger: PublishSubject<Void>,
                       otherCodeTrigger: PublishSubject<Bool>) -> Driver<Void> {
        let confirmMessage: Observable<Bool>
        if let errorCode = errorCode {
            confirmMessage = self.navigator.showConfirmMessage(errorCode: errorCode)
        } else {
            confirmMessage = self.navigator.showConfirmMessage(message)
        }
        
        return confirmMessage
            .asDriverOnErrorJustComplete()
            .flatMap({ save in
                if save {
                    saveTrigger.onNext(())
                    
                    return Driver.just(())
                }
                
                return self.navigator
                    .showConfirmMessage(L10n.Creation.closeDraftWithoutSaving)
                    .asDriverOnErrorJustComplete()
                    .do(onNext: { save in
                        if save {
                            dismissTrigger.onNext(())
                            otherCodeTrigger.onNext(false)
                        } else {
                            otherCodeTrigger.onNext(true)
                        }
                    })
                    .mapToVoid()
            })
    }
    
    
    func showExcutionErrorFlow(message: String,
                       errorCode: String? = nil,
                       saveTrigger: PublishSubject<Void>,
                       dismissTrigger: PublishSubject<Void>,
                       otherCodeTrigger: PublishSubject<Bool>) -> Driver<Void> {
        let confirmMessage: Observable<Bool>
        if let errorCode = errorCode {
            confirmMessage = self.navigator.showConfirmMessage(errorCode: errorCode)
        } else {
            confirmMessage = self.navigator.showConfirmMessage(message)
        }
        
        return confirmMessage
            .asDriverOnErrorJustComplete()
            .flatMap({ save in
                if save {
                    saveTrigger.onNext(())
                    
                    return Driver.just(())
                }
                
                return self.navigator
                    .showConfirmMessage(L10n.Creation.closeDraftWithoutSaving)
                    .asDriverOnErrorJustComplete()
                    .do(onNext: { save in
                        if save {
                            dismissTrigger.onNext(())
                            otherCodeTrigger.onNext(false)
                        } else {
                            otherCodeTrigger.onNext(true)
                        }
                    })
                    .mapToVoid()
            })
    }
    
    private func currentIndex(list: [NSRange], currentPosition: NSRange) -> NSRange {
        guard let index = list.firstIndex(of: currentPosition) else { return NSRange() }
        var i: Int = index
        i = index + 1
        
        if index + 1 >= list.count {
            i = list.count - 1
        }
        
        return list[i]
        
    }
}

// validate
extension CreationViewModel {
    // Return nil means it's ok, if not, it will return a valid text (which has beed cut off) to replace the whole text
    func validate(title: NSAttributedString) -> NSAttributedString? {
        if title.string.count > CreationUseCase.Constant.maxTitle {
            let newTitle = NSMutableAttributedString(attributedString: title)
            newTitle.deleteCharacters(in: NSMakeRange(CreationUseCase.Constant.maxTitle, title.string.count - CreationUseCase.Constant.maxTitle))
            
            return newTitle
        }
        
        return nil
    }
    
    // Return nil means it's ok, if not, it will return a valid text (which has beed cut off) to replace the whole text
    func validate(title: String, shouldChangeTextIn range: NSRange, replacementText text: String) -> String? {
        checkText(currentText: title, maxLen: CreationUseCase.Constant.maxTitle, shouldChangeTextIn: range, replacementText: text)
    }
    
    // Return nil means it's ok, if not, it will return a valid text (which has beed cut off) to replace the whole text
    func validate(content: String, shouldChangeTextIn range: NSRange, replacementText text: String) -> String? {
        checkText(currentText: content, maxLen: CreationUseCase.Constant.maxContent, shouldChangeTextIn: range, replacementText: text)
    }
    
    // Return nil means it's ok, if not, it will return a valid text (which has beed cut off) to replace the whole text
    private func checkText(currentText: String, maxLen: Int, shouldChangeTextIn range: NSRange, replacementText text: String) -> String? {
        var currentText = currentText
        let count = currentText.count - range.length + text.count
        if count > maxLen {
            if let start = currentText.utf16.index(currentText.startIndex, offsetBy: range.lowerBound, limitedBy: currentText.endIndex),
               let end = currentText.utf16.index(currentText.startIndex, offsetBy: range.upperBound, limitedBy: currentText.endIndex) {
                //The delacred will calculate the position that will be remove
                //And map elements String to String
                let countValid = text.count - (count - maxLen)
                let t = text.enumerated().filter{ $0.offset < countValid }.map{ $0.element }.map{ String($0) }.joined()
                currentText.replaceSubrange(start..<end, with: t)
                
                //the old handle
//                currentText.replaceSubrange(start..<end, with: text)

            }
            
            currentText = String(currentText.prefix(maxLen))
            return currentText
        }
        
        return nil
    }
    
    // Return nil means it's ok, if not, it will return a valid text (which has beed cut off) to replace the whole text
    func replaceText(content: String, shouldChangeTextIn range: NSRange, replacementText text: String) -> String? {
        checkTextReplace(currentText: content, maxLen: CreationUseCase.Constant.maxContent, shouldChangeTextIn: range, replacementText: text)
    }
    
    // Return nil means it's ok, if not, it will return a valid text (which has beed cut off) to replace the whole text
    private func checkTextReplace(currentText: String, maxLen: Int, shouldChangeTextIn range: NSRange, replacementText text: String) -> String? {
        var getText: String = ""
        let currentText = currentText
        let count = currentText.count - range.length + text.count
        if count >= maxLen {
            if let _ = currentText.utf16.index(currentText.startIndex, offsetBy: range.lowerBound, limitedBy: currentText.endIndex),
               let _ = currentText.utf16.index(currentText.startIndex, offsetBy: range.upperBound, limitedBy: currentText.endIndex) {
                //The delacred will calculate the position that will be remove
                //And map elements String to String
                let countValid = text.count - (count - maxLen)
                getText = text.enumerated().filter{ $0.offset < countValid }.map{ $0.element }.map{ String($0) }.joined()
//                currentText.replaceSubrange(start..<end, with: t)
                //the old handle
//                currentText.replaceSubrange(start..<end, with: text)

            }
            
//            currentText = String(currentText.prefix(maxLen))
            return getText
        }
        
        return nil
    }
    
    // Return nil means it's ok, if not, it will return a valid text (which has beed cut off) to replace the whole text
    func validateContent(content: String, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool? {
        checkTextContent(currentText: content, maxLen: CreationUseCase.Constant.maxContent, shouldChangeTextIn: range, replacementText: text)
    }
    
    // Return nil means it's ok, if not, it will return a valid text (which has beed cut off) to replace the whole text
    private func checkTextContent(currentText: String, maxLen: Int, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool? {
//        var currentText = currentText
        let count = currentText.count - range.length + text.count
        if count > maxLen {
            return true
        }
        
        return nil
    }
    
    // Return nil means it's ok, if not, it will return a valid text (which has beed cut off) to replace the whole text
    func getTextReplace(currentText: String, maxLen: Int, shouldChangeTextIn range: NSRange, replacementText text: String) -> String? {
        var getText: String = ""
        let currentText = currentText
        let count = currentText.count - range.length + text.count
        if count > maxLen {
            if let _ = currentText.utf16.index(currentText.startIndex, offsetBy: range.lowerBound, limitedBy: currentText.endIndex),
               let _ = currentText.utf16.index(currentText.startIndex, offsetBy: range.upperBound, limitedBy: currentText.endIndex) {
                //The delacred will calculate the position that will be remove
                //And map elements String to String
                let countValid = text.count - (count - maxLen)
                let t = text.enumerated().filter{ $0.offset < countValid }.map{ $0.element }.map{ String($0) }.joined()
                getText = t
                
//                self.updateCursorPosition.onNext(NSRange(location: range.location + t.count, length: 0))
                
                //the old handle
//                currentText.replaceSubrange(start..<end, with: text)

            }
            return getText
        }
        
        return nil
    }
    
}
extension CreationViewModel.TextAttributeString: Equatable {
    public static func ==(lhs: CreationViewModel.TextAttributeString, rhs: CreationViewModel.TextAttributeString) -> Bool {
        return lhs.attributedString == rhs.attributedString
    }
}
