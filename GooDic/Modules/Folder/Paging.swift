//
//  Paging.swift
//  GooDic
//
//  Created by ttvu on 12/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public struct PagingInfo<T> {
    var offset: Int
    var limit: Int
    var totalItems: Int
    var items: [T]
    var hasMorePages: Bool
    var name: String // name of paging
    var sortedAt: String
    
    init(offset: Int = 0, limit: Int = 0, totalItems: Int = 0, hasMorePages: Bool = false, items: [T] = [], name: String = "", sortedAt: String = "") {
        self.offset = offset
        self.limit = limit
        self.totalItems = totalItems
        self.hasMorePages = hasMorePages
        self.items = items
        self.name = name
        self.sortedAt = sortedAt
    }
}

enum ScreenLoadingType {
    case loading
    case reloading
    case loadMore
}

struct GetPageResult<T> {
    var page: Driver<PagingInfo<T>>
    var error: Driver<Error>
    var isLoading: Driver<Bool>
    var isReloading: Driver<Bool>
    var isLoadingMore: Driver<Bool>
    
    public var destructured: (Driver<PagingInfo<T>>, Driver<Error>, Driver<Bool>, Driver<Bool>, Driver<Bool>) {
        return (page, error, isLoading, isReloading, isLoadingMore)
    }
    
    public init(page: Driver<PagingInfo<T>>,
                error: Driver<Error>,
                isLoading: Driver<Bool>,
                isReloading: Driver<Bool>,
                isLoadingMore: Driver<Bool>) {
        self.page = page
        self.error = error
        self.isLoading = isLoading
        self.isReloading = isReloading
        self.isLoadingMore = isLoadingMore
    }
}

protocol PagingFeature {
}

extension PagingFeature {
    public func getPage<Item>(
        loadType: Driver<ScreenLoadingType>,
        retry: Driver<Void>,
        getItems: @escaping (Int) -> Observable<PagingInfo<Item>>) -> GetPageResult<Item> {
        
        let trigger = Driver.merge(loadType, retry.withLatestFrom(loadType))
        
        let loadTrigger = trigger.filter({ $0 == .loading }).mapToVoid()
        let reloadTrigger = trigger.filter({ $0 == .reloading }).mapToVoid()
        let loadMoreTrigger = trigger.filter({ $0 == .loadMore }).mapToVoid()
        
        return getPage(loadTrigger: loadTrigger,
                reloadTrigger: reloadTrigger,
                loadMoreTrigger: loadMoreTrigger,
                getItems: getItems)
    }
        
    public func getPage<Item>(
        loadTrigger: Driver<Void>,
        reloadTrigger: Driver<Void>,
        loadMoreTrigger: Driver<Void>,
        getItems: @escaping (Int) -> Observable<PagingInfo<Item>>) -> GetPageResult<Item> {
        
        let pageSubject = BehaviorRelay(value: PagingInfo<Item>())
        let errorTracker = ErrorTracker()
        let loadActivityIndicator = ActivityIndicator()
        let reloadActivityIndicator = ActivityIndicator()
        let loadMoreActivityIndicator = ActivityIndicator()
        
        
        let isLoading = loadActivityIndicator.asDriver()
        let isReloading = reloadActivityIndicator.asDriver()
        let isLoadingMore = loadMoreActivityIndicator.asDriver()
        
        let loadingMoreSubject = PublishSubject<Bool>()
        
        let isLoadingOrLoadingMore = Driver.merge(isLoading, isReloading, isLoadingMore)
            .startWith(false)
        
        let loadItems = Driver<ScreenLoadingType>
            .merge(
                loadTrigger.map { ScreenLoadingType.loading },
                reloadTrigger.map { ScreenLoadingType.reloading }
            )
            .withLatestFrom(isLoadingOrLoadingMore) {
                (triggerType: $0, loading: $1)
            }
            .filter { !$0.loading }
            .map { $0.triggerType }
            .flatMapLatest { triggerType -> Driver<PagingInfo<Item>> in
                switch triggerType {
                case .loading:
                    return getItems(0)
                        .trackError(errorTracker)
                        .trackActivity(loadActivityIndicator)
                        .asDriverOnErrorJustComplete()
                case .reloading:
                    return getItems(0)
                        .trackError(errorTracker)
                        .trackActivity(reloadActivityIndicator)
                        .asDriverOnErrorJustComplete()
                case .loadMore:
                    return Driver.empty()
                }
            }
            .do(onNext: { page in
                let newPage = PagingInfo<Item>(
                    offset: page.offset,
                    limit: page.limit,
                    totalItems: page.totalItems,
                    hasMorePages: page.items.count == page.limit,
                    items: page.items,
                    name: page.name)
                pageSubject.accept(newPage)
            })
        
        let loadMoreItems = loadMoreTrigger
            .withLatestFrom(isLoadingOrLoadingMore) {
                (input: $0, loading: $1)
            }
            .filter { !$0.loading }
            .map { $0.input }
            .do(onNext: { _ in
                if pageSubject.value.items.isEmpty {
                    loadingMoreSubject.onNext(false)
                }
            })
            .filter { _ in !pageSubject.value.items.isEmpty }
            .filter { _ in pageSubject.value.hasMorePages }
            .flatMapLatest { input -> Driver<PagingInfo<Item>> in
                let nextOffset = pageSubject.value.offset + pageSubject.value.limit
                
                return getItems(nextOffset)
                    .trackError(errorTracker)
                    .trackActivity(loadMoreActivityIndicator)
                    .asDriverOnErrorJustComplete()
            }
            .filter { !$0.items.isEmpty || !$0.hasMorePages }
            .do(onNext: { page in
                let currentPage = pageSubject.value
                let items = currentPage.items + page.items
                
                let newPage = PagingInfo<Item>(
                    offset: page.offset,
                    limit: page.limit,
                    totalItems: page.totalItems,
                    hasMorePages: page.items.count == page.limit,
                    items: items,
                    name: page.name)
                
                pageSubject.accept(newPage)
            })
        
        let page = Driver.merge(loadItems, loadMoreItems)
            .withLatestFrom(pageSubject.asDriver())
        
        return GetPageResult(
            page: page,
            error: errorTracker.asDriver(),
            isLoading: isLoading.asDriver(),
            isReloading: isReloading.asDriver(),
            isLoadingMore: isLoadingMore.asDriver())
    }
}
