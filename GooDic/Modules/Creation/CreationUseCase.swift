//
//  CreationUseCase.swift
//  GooDic
//
//  Created by ttvu on 5/25/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import RxSwift
import RxCocoa

enum FetchDataResult {
    case success(GDData, GDData) // suggestionTitle, suggestionContent
    case connectionError(NSError)
    case error(Error)
}

protocol CreationUseCaseProtocol: AuthenticationUseCaseProtocol {
    func checkIdiom(title:String, content: String) -> Observable<FetchDataResult>
    func checkIdiom(title: String, content: String, selectedRangeTitle: Range<String.Index>) -> Observable<FetchDataResult>
    func checkIdiom(title: String, content: String, selectedRangeContent: Range<String.Index>) -> Observable<FetchDataResult>
    func checkThesaurus(title: String, content: String) -> Observable<FetchDataResult>
    func checkThesaurus(title: String, content: String, selectedRangeTitle: Range<String.Index>) -> Observable<FetchDataResult>
    func checkThesaurus(title: String, content: String, selectedRangeContent: Range<String.Index>) -> Observable<FetchDataResult>
    func update(document: Document, updateDate: Bool) -> Observable<Void>
    func saveToTrash(document: Document) -> Observable<Void>
    func autoSavingTrigger() -> Observable<Void>
    func showCheckAPITooltip() -> Bool
    func learnedTooltip() -> Observable<Void>
    func search(text: String) -> Observable<URL?>
    
    func getCurrentFontStyleLevel() -> Int
    func getTotalFontStyleLevel() -> Int
    func getCurrentFontStyle() -> FontStyleData
    func setFontStyleLevel(level: Int)
    
    func updateCloudDocument(_ document: Document, overwrite: Bool, reuseLastUpdate: Bool) -> Observable<Date>
    func deleteCloudDocument(_ id: String) -> Observable<Void>
    func highlight(source: inout NSMutableAttributedString, searchText: String, textAttribute: CreationViewModel.TextAttributeString)
    func listPositionSearch(source: NSMutableAttributedString, searchText: String) -> [NSRange]
    func getSettingFont() -> SettingFont?
    func getSettingSearch() -> SettingSearch?
    func replaceText(source: inout NSMutableAttributedString,
                     ranges: [NSRange],
                     textAttribute: CreationViewModel.TextAttributeString,
                     textReplace: String?)
    func replaceAllText(source: NSMutableAttributedString,
                        textSearch: String,
                        textAttribute: CreationViewModel.TextAttributeString,
                        textReplace: String) -> NSMutableAttributedString
    func disableAutoSaveCloud(autoSaveCount: Disposable?)
    func enableAutoSaveCloud(autoSaveCount: inout Disposable?, autoSave: @escaping ( () -> Void ))
    
    func fetchDraftDetail(draft: Document) -> Observable<Document>
    func checkIsDocument(document: Document) -> Bool
    func addBackUp(document: Document) -> Observable<Void>
    func autoSavingBackUpTrigger(value: Int) -> Observable<Void>
    func getSettingBackUp(settingKey: String) -> Observable<SettingBackupModel?>
    
}

struct CreationUseCase: CreationUseCaseProtocol {

    private let disposebag = DisposeBag()
    struct Constant {
        static let maxTitle: Int = 2_000
        static let maxContent: Int = 50_000
        static let autoSavingTick: Int = 30 // seconds
    }
    
    @GooInject var dbService: DatabaseService
    @GooInject var cloudService: CloudService
    @GooInject var idiomService: IdiomService
    @GooInject var thesaurusService: ThesaurusService
    @GooInject var dictionaryService: DictionaryService
    
    func disableAutoSaveCloud(autoSaveCount: Disposable?) {
        autoSaveCount?.dispose()
    }
    
    func enableAutoSaveCloud(autoSaveCount: inout Disposable?, autoSave: @escaping ( () -> Void )) {
        autoSaveCount?.dispose()
        autoSaveCount = Observable<Int>.interval(.seconds(Constant.autoSavingTick), scheduler: MainScheduler.instance).bind(onNext: { (time) in
            autoSave()
        })
            
    }
    
    func autoSavingBackUpTrigger(value: Int) -> Observable<Void> {
        return Observable<Int>.interval(.seconds(value), scheduler: MainScheduler.instance)
            .mapToVoid().debug("auto-saving")
    }
    
    func autoSavingTrigger() -> Observable<Void> {
        return Observable<Int>.interval(.seconds(Constant.autoSavingTick), scheduler: MainScheduler.instance)
            .mapToVoid().debug("auto-saving")
    }
    
    func checkIdiom(title: String, content: String) -> Observable<FetchDataResult> {
        let txt = title + "\n" + content
        
        return checkIdiom(text: txt, successBlock: { list -> FetchDataResult in
            let seek = (title + "\n").utf16.count
            var titleResult: [IdiomData] = []
            var contentResult: [IdiomData] = []
            
            for i in 0..<list.count {
                var item = list[i]
                if item.offset < title.utf16.count {
                    titleResult.append(item)
                } else {
                    item.offset -= seek
                    contentResult.append(item)
                }
            }
            
            let titleItems = titleResult.map({ GDDataItem.from(data: $0) })
            let contentItems = contentResult.map({ GDDataItem.from(data: $0) })
            
            return FetchDataResult.success(GDData(text: title, items: titleItems), GDData(text: content, items: contentItems))
        })
    }

    func checkIdiom(title: String, content: String, selectedRangeTitle: Range<String.Index>) -> Observable<FetchDataResult> {
        let txt = String(title[selectedRangeTitle])
        
        let seek = title.utf16.distance(from: title.startIndex, to: selectedRangeTitle.lowerBound)
        
        return checkIdiom(text: txt, successBlock: { list -> FetchDataResult in
            let titleItems = list.map({ (data) -> GDDataItem in
                var item = GDDataItem.from(data: data)
                item.offset += seek
                return item
            })

            return FetchDataResult.success(GDData(text: title, items: titleItems),
                                           GDData(text: content, items: []))
        })
    }
        
    func checkIdiom(title: String, content: String, selectedRangeContent: Range<String.Index>) -> Observable<FetchDataResult> {
        let txt = String(content[selectedRangeContent])
        
        let seek = content.utf16.distance(from: content.startIndex, to: selectedRangeContent.lowerBound)
        
        return checkIdiom(text: txt, successBlock: { list -> FetchDataResult in
            let contentItems = list.map({ data -> GDDataItem in
                var item = GDDataItem.from(data: data)
                item.offset += seek
                return item
            })
            
            return FetchDataResult.success(GDData(text: title, items: []),
                                           GDData(text: content, items:contentItems))
        })
    }
    
    private func checkIdiom(text: String, successBlock: @escaping ([IdiomData]) -> FetchDataResult) -> Observable<FetchDataResult> {
        return self.idiomService.gateway.fetch(text: text)
            .map({ txtResponse -> FetchDataResult in
                switch txtResponse.result {
                case let .error(error):
                    return FetchDataResult.error(error)
                case .empty:
                    return successBlock([])
                case let .normal(list):
                    var arrangedList = list
                    
                    var lastStringIndex: String.Index = text.startIndex
                    for i in 0..<arrangedList.count {
                        if let range = text.range(of: arrangedList[i].target, range: lastStringIndex..<text.endIndex) {
                            arrangedList[i].offset = range.lowerBound.utf16Offset(in: text)
                            lastStringIndex = range.upperBound
                        } else {
                            arrangedList[i].offset = 0
                        }
                    }
                
                    return successBlock(arrangedList)
                }
            })
            .retry(3)
            .catchError({ (error) -> Observable<FetchDataResult> in
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain {
                    return Observable.just(FetchDataResult.connectionError(nsError))
                } else {
                    return Observable.just(FetchDataResult.error(error))
                }
            })
    }
    
    func checkThesaurus(title: String, content: String) -> Observable<FetchDataResult> {
        let txt = title + "\n" + content
        
        return checkThesaurus(text: txt) { (list) -> FetchDataResult in
            let seek = (title + "\n").utf16.count
            var titleResult: [ThesaurusData] = []
            var contentResult: [ThesaurusData] = []
            
            for i in 0..<list.count {
                var item = list[i]
                if item.offset < title.utf16.count {
                    titleResult.append(item)
                } else {
                    item.offset -= seek
                    contentResult.append(item)
                }
            }
            
            let titleItems = titleResult.map({ GDDataItem.from(data: $0) })
            let contentItems = contentResult.map({ GDDataItem.from(data: $0) })
            
            return FetchDataResult.success(GDData(text: title, items: titleItems), GDData(text: content, items: contentItems))
        }
    }

    func checkThesaurus(title: String, content: String, selectedRangeTitle: Range<String.Index>) -> Observable<FetchDataResult> {
        let txt = String(title[selectedRangeTitle])
        
        let seek = title.utf16.distance(from: title.startIndex, to: selectedRangeTitle.lowerBound)
        
        return checkThesaurus(text: txt, successBlock: { list -> FetchDataResult in
            let titleItems = list.map({ (data) -> GDDataItem in
                var item = GDDataItem.from(data: data)
                item.offset += seek
                return item
            })

            return FetchDataResult.success(GDData(text: title, items: titleItems),
                                           GDData(text: content, items: []))
        })
    }
    
    func checkThesaurus(title: String, content: String, selectedRangeContent: Range<String.Index>) -> Observable<FetchDataResult> {
        let txt = String(content[selectedRangeContent])
        
        let seek = content.utf16.distance(from: content.startIndex, to: selectedRangeContent.lowerBound)
        
        return checkThesaurus(text: txt, successBlock: { list -> FetchDataResult in
            let contentItems = list.map({ (data) -> GDDataItem in
                var item = GDDataItem.from(data: data)
                item.offset += seek
                return item
            })

            return FetchDataResult.success(GDData(text: title, items: []),
                                           GDData(text: content, items: contentItems))
        })
    }
    
    private func buildURLComponents() -> URLComponents? {
        guard let urlComponents = URLComponents(string: "\(Environment.apiScheme + Environment.apiHost + Environment.apiThsrsPath)") else { return nil }
    
        return urlComponents
    }
    private func normalize(text: String) -> String {
        var result = text
        
        result = result.replacingOccurrences(of: "/", with: "%2f")
        result = result.replacingOccurrences(of: "+", with: "%2f")
        result = result.replacingOccurrences(of: "&", with: "%2f")
        result = result.replacingOccurrences(of: "?", with: "%2f")
        
        return result
    }
    
    private func checkThesaurus(text: String, successBlock: @escaping ([ThesaurusData]) -> FetchDataResult) -> Observable<FetchDataResult> {
        return self.thesaurusService.gateway.fetch(text: text)
            .map({ txtResponse -> FetchDataResult in
                switch txtResponse.result {
                case let .error(error):
                    return FetchDataResult.error(error)
                case .empty:
                    return successBlock([])
                case let .normal(list):
                    var arrangedList = list
                    
                    for i in 0..<arrangedList.count {
                        arrangedList[i].offset = text.findIndex(key: arrangedList[i].target,
                            order: arrangedList[i].order)?.lowerBound.utf16Offset(in: text) ?? 0
                    }
                    
                    return successBlock(arrangedList)
                }
            })
            .timeout(.seconds(15), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry)
            .catchError({ (error) -> Observable<FetchDataResult> in
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain {
                    return Observable.just(FetchDataResult.connectionError(nsError))
                } else {
                    return Observable.just(FetchDataResult.error(error))
                }
            })
    }
    
    func checkIsDocument(document: Document) -> Bool {
        return self.dbService.gateway.checkIsDocument(document: document)
    }
    
    func update(document: Document, updateDate: Bool) -> Observable<Void> {
        return self.dbService.gateway.update(document: document, updateDate: updateDate)
    }
    
    func saveToTrash(document: Document) -> Observable<Void> {
        var newDocument = document.duplicate()
        newDocument.status = .deleted
        
        return self.dbService.gateway.update(document: newDocument, updateDate: true)
    }
    
    func showCheckAPITooltip() -> Bool {
        return AppSettings.guideUserToCheckAPITutorial == false
    }
    
    func learnedTooltip() -> Observable<Void> {
        return Observable.create { (observer) -> Disposable in
            AppSettings.guideUserToCheckAPITutorial = true
            
            observer.onNext(())
            
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func search(text: String) -> Observable<URL?> {
        if let url = dictionaryService.gateway.fetch(text: text, mode: .prefix) {
            return Observable.just(url)
        } else {
            return Observable.just(nil)
        }
    }
    
    func getCurrentFontStyleLevel() -> Int {
        return FontManager.shared.currentLevel
    }
    
    func getTotalFontStyleLevel() -> Int {
        return FontManager.shared.numOfLevels
    }
    
    func getCurrentFontStyle() -> FontStyleData {
        return FontManager.shared.currentFontStyle
    }
    
    func setFontStyleLevel(level: Int) {
        if FontManager.shared.currentLevel != level {
            AppSettings.fontStyleLevel = level
        }
    }
    
    func getSettingBackUp(settingKey: String) -> Observable<SettingBackupModel?> {
        return cloudService.gateway
            .getBackupSettings(settingKey: settingKey)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
    }
    
    func addBackUp(document: Document) -> Observable<Void> {
        return cloudService.gateway
            .addBackUp(draft: document)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
    
    func updateCloudDocument(_ document: Document, overwrite: Bool, reuseLastUpdate: Bool) -> Observable<Date> {
        guard case let .cloud(folderIdValue) = document.folderId else { return Observable.empty() }
        
        let cloudDocument = CloudDocument(id: document.id,
                                          title: document.title,
                                          content: document.content,
                                          updatedAt: document.updatedAt,
                                          folderId: folderIdValue,
                                          folderName: document.folderName,
                                          cursorPosition: document.cursorPosition,
                                          manualIndex: nil)
        
        return cloudService.gateway
            .updateDraft(cloudDocument, overwrite: overwrite, reuseLastUpdate: reuseLastUpdate)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
    
    func deleteCloudDocument(_ id: String) -> Observable<Void> {
        return cloudService.gateway
            .deleteDrafts(draftIds: [id])
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
    
    func highlight(source: inout NSMutableAttributedString,
                   searchText: String,
                   textAttribute: CreationViewModel.TextAttributeString) {
        do {
            let regEx = try NSRegularExpression(pattern: searchText, options: NSRegularExpression.Options.ignoreMetacharacters)
            
            let matchesRanges = regEx.matches(in: source.string, options: [], range: NSMakeRange(0, source.length))
            
            matchesRanges.enumerated().forEach { (checkingResult) in
                //hightlight first word
                if checkingResult.offset == 0 {
                    source.replaceCharacters(
                        in: checkingResult.element.range,
                        with: NSAttributedString(
                            string: searchText,
                            attributes: textAttribute.getContentAttsSearch(statusHighlight: .replace) ))
                } else {
                    source.replaceCharacters(
                        in: checkingResult.element.range,
                        with: NSAttributedString(
                            string: searchText,
                            attributes: textAttribute.getContentAttsSearch(statusHighlight: .search)
                            ))
                }
            }
        } catch {
            print(error)
        }
    }
    
    func listPositionSearch(source: NSMutableAttributedString, searchText: String) -> [NSRange] {
        do {
            let regEx = try NSRegularExpression(pattern: searchText, options: NSRegularExpression.Options.ignoreMetacharacters)
            
            let matchesRanges = regEx.matches(in: source.string, options: [], range: NSMakeRange(0, source.length))
            
            return matchesRanges.map { item -> NSRange in
                return item.range
            }
            
        } catch {
            print(error)
        }
        return []
    }
    
    func replaceText(source: inout NSMutableAttributedString,
                     ranges: [NSRange],
                     textAttribute: CreationViewModel.TextAttributeString,
                     textReplace: String?)  {
        guard let text = textReplace else { return }
        ranges.forEach { r in
            source.replaceCharacters(
                    in: r,
                    with: NSAttributedString(
                        string: text,
                        attributes: textAttribute.getContentAttsSearch(statusHighlight: .other)
                        ))
        }
    }
    
    func replaceAllText(source: NSMutableAttributedString,
                        textSearch: String,
                        textAttribute: CreationViewModel.TextAttributeString,
                        textReplace: String) -> NSMutableAttributedString {
        let t = source.string.replacingOccurrences(of: textSearch, with: textReplace)
            .getAttributedStringALL(attributes: textAttribute.getContentAttsSearch(statusHighlight: .other))
        
        return t
    }
    
    func getSettingFont() -> SettingFont? {
        return AppSettings.settingFont
    }
    
    func getSettingSearch() -> SettingSearch? {
        return AppSettings.settingSearch
    }
    
    func fetchDraftDetail(draft: Document) -> Observable<Document> {
        guard let cloudDraft = CloudDocument(document: draft) else {
            return Observable.error(NSError())
        }
        
        return cloudService.gateway
            .getDraftDetail(cloudDraft)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
            .map({ $0.document })
    }
}
