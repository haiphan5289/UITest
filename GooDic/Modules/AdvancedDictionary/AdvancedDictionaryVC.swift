//
//  AdvancedDictionaryVC.swift
//  GooDic
//
//  Created by haiphan on 10/11/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AdvancedDictionaryVC: BaseViewController, ViewBindableProtocol {
    
    struct Constant {
        static let bottomContraint: CGFloat = 16
        static let matchIncludTagView: Int = 10
        static let ratioPositionLastView: CGFloat = 5
        static let ratioWidthLastView: CGFloat = 10
        static let spacingPortraint: CGFloat = 24
        static let widthView: CGFloat = 60
        static let totalSpacing: CGFloat = 4
        static let totalView: CGFloat = 4
        static let distanceToLeft: CGFloat = 16
        static let widthIPad: CGFloat = 800
        static let widthLastView: CGFloat = 90
        static let paddingIIpadLandscape: CGFloat = 128
        static let spaceLeftTextField: CGFloat = 3
    }
    
    enum Action {
        case pop, dismiss
    }
    
    public enum StatusStackView: Int, CaseIterable {
        case prefix, exact, backward, matchInHeading, matchIncludeDescription
        
        var model: DictionaryMode {
            switch self {
            case .prefix: return .prefix
            case .exact: return .exact
            case .backward: return .backward
            case .matchInHeading: return .matchInHeading
            case .matchIncludeDescription: return .matchIncludeDescription
            }
        }
        
        var searchCondition: GATracking.SearchCondition {
            switch self {
            case .prefix: return .prefixMatch
            case .exact: return .perfectMatch
            case .backward: return .backwardMatch
            case .matchInHeading: return .partialMatch
            case .matchIncludeDescription: return .explanatoryText
            }
        }
    }
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBarBg: UIView!
    @IBOutlet weak var btCancel: UIButton!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var bts: [UIButton]!
    @IBOutlet var views: [UIView]!
    @IBOutlet var lbs: [UILabel]!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomStackView: NSLayoutConstraint!
    @IBOutlet weak var contentTableView: UIView!
    @IBOutlet weak var contentToastMsg: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var rightContraint: NSLayoutConstraint!
    @IBOutlet weak var leftContraint: NSLayoutConstraint!
    
    var viewModel: AdvancedDictionaryVM!
    var rightSafeArea: CGFloat = 0
    var leftSafeArea: CGFloat = 0
    
    var dismissButton: UIBarButtonItem?
    private var selectView: UIView = UIView(frame: .zero)
    
    private let eventDismiss: PublishSubject<Action> = PublishSubject.init()
    private let eventFinishScroll: BehaviorRelay<Void> = BehaviorRelay(value: ())
    private let eventChangeRect: PublishSubject<UIView> = PublishSubject.init()
    private let toastMessageFix = ToastMessageFixView.loadXib()
    private let eventTapToastView: PublishSubject<ToastMessageFixView.TapAction> = PublishSubject.init()
    private let eventStatusSearch: BehaviorRelay<StatusStackView> = BehaviorRelay(value: .prefix)
    private let eventDetectLandscape: BehaviorRelay<(CGSize, Bool)> = BehaviorRelay.init(value: (UIScreen.main.bounds.size, true))
    private let didTyping = PublishSubject<Void>()
    private let eventLoadNotifyDictionary: PublishSubject<Void> = PublishSubject.init()
    
    private let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupRX()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        switch self.sceneType {
        case .searchInDraft:
            self.navigationController?.isNavigationBarHidden = false
            self.btCancel.isHidden = true
        default:
            self.navigationController?.isNavigationBarHidden = true
            self.view.backgroundColor = Asset.ffffff121212.color
        }
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // We can use a 1px image with the color we want for the shadow image
        // Set color for botom line navigation
        self.navigationController?.navigationBar.shadowImage = Asset.clean464646.color.as1ptImage()
        searchBarBg.backgroundColor = Asset.searchBarBg.color
        searchBarBg.layer.borderColor = Asset.cecece666666206.color.cgColor
        self.eventDetectLandscape.accept((UIScreen.main.bounds.size, false))
        self.eventChangeRect.onNext(self.selectView)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.toastMessageFix.updatTextContent(size: size)
        self.eventDetectLandscape.accept((size, false))
        self.eventChangeRect.onNext(self.selectView)
    }

}
extension AdvancedDictionaryVC {
    
    private func setupUI() {
        // remove the 2 lines on top and on bottom of search Bar
        let searchIcon = Asset.icSearchAdvancedictionary.image
        searchBar.setImage(searchIcon, for: .search, state: .normal)
        
        let clearIcon = Asset.icDeleteAdvancedictionary.image
        searchBar.setImage(clearIcon, for: .clear, state: .normal)
        
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextPositionAdjustment = UIOffset(horizontal: Constant.spaceLeftTextField, vertical: 0)
        searchBar.delegate = self
        
        if let textField = searchBar.getTextField() {
            textField.font = UIFont.hiraginoSansW4(size: 16)
            textField.backgroundColor = UIColor.clear
            textField.textColor = Asset._111111Ffffff.color
        }
        updateAttributeSearchTextIfNeed()
        searchBar.becomeFirstResponder()
        // update search bar bg
        searchBarBg.backgroundColor = Asset.searchBarBg.color
        searchBarBg.layer.borderColor = Asset.cecece666666206.color.cgColor
        searchBarBg.layer.borderWidth = 1
        searchBarBg.layer.cornerRadius = 5
        
        // setup dismiss button if needed
        if dismissButton != nil {
            self.navigationItem.leftBarButtonItem = dismissButton
            dismissButton?.target = self
            dismissButton?.action = #selector(dismissButtonPressed(_:))
            self.navigationItem.leftBarButtonItem?.tintColor = Asset.textPrimary.color
            self.view.backgroundColor = Asset.modelBackground.color
        }
        
        self.view.addSeparator(at: .top, color: Asset.clean464646.color)
        
        self.scrollView.delegate = self
        
        self.tableView.estimatedRowHeight = 48
        self.tableView.delegate = self
        let cellName = String(describing: DropDownTVC.self)
        let nib = UINib(nibName: cellName, bundle: Bundle.main)
        self.tableView.register(nib, forCellReuseIdentifier: DropDownTVC.reuseIdentifier)
        self.contentTableView.addSeparator(at: .top, color: Asset.e3E3E3666666E3.color)
        
        self.toastMessageFix.delegate = self
        
        self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        self.selectView = self.views[StatusStackView.prefix.rawValue]
    }
    
    func bindViewModel() {
        let pop = self.btCancel.rx.tap.map { Action.pop }
        
        let action = Observable.merge(pop, self.eventDismiss.asObservable()).asDriverOnErrorJustComplete()
        
        let clearTrigger = self.searchBar.rx
            .text
            .orEmpty
            .filter({ $0.isEmpty })
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        
        let textTrigger = Driver
            .merge(
                didTyping.asDriverOnErrorJustComplete(),
                clearTrigger)
            .map({ [weak self] in
                self?.searchBar.text ?? ""
            })
        
        let eventLoadNotifyDictionary = Driver.merge(self.eventLoadNotifyDictionary.asDriverOnErrorJustComplete(), Driver.just(()))
        
        let input = AdvancedDictionaryVM
            .Input(
                action: action,
                getNotifyDictionaryTrigger: eventLoadNotifyDictionary,
                eventTapToastView: self.eventTapToastView.asDriverOnErrorJustComplete(),
                textTrigger: textTrigger,
                statusSearchTrigger: self.eventStatusSearch.distinctUntilChanged().asDriverOnErrorJustComplete(),
                searchInputTrigger: searchBar.rx.searchButtonClicked.asDriver(),
                selectedItem: tableView.rx.itemSelected.asDriver().map({ $0.row })
            )
        
        let output = viewModel.transform(input)
        
        output.keyboardHeight
            .do(onNext: { [weak self] keyboard in
                guard let wSelf = self else { return }
                let h = keyboard.height
                let d = keyboard.duration
                UIView.animate(withDuration: d) {
                    wSelf.bottomStackView.constant =  h
                }
            })
            .drive()
            .disposed(by: self.disposeBag)
        
        output.showSuggestion
            .drive(tableView.rx.items(cellIdentifier: DropDownTVC.reuseIdentifier, cellType: DropDownTVC.self)) {(row, element, cell) in
                cell.bind(data: element)
                cell.showLineView()
            }.disposed(by: disposeBag)
        
        output.action.drive().disposed(by: disposeBag)
        
        Driver.combineLatest(output.getBillingInfo, output.getNotifyDictionary)
            .drive(onNext: { [weak self] (billingInfo, notify) in
                guard let wSelf = self else { return }
                
                switch billingInfo.billingStatus {
                case .free:
                    wSelf.lbs.forEach { lb in
                        if lb == wSelf.lbs[StatusStackView.prefix.rawValue] || lb == wSelf.lbs[StatusStackView.exact.rawValue] {
                            lb.textColor = Asset._111111Ffffff.color
                        } else {
                            lb.textColor = Asset.cecece717171.color
                        }
                    }
                    if let notify = notify {
                        wSelf.toastMessageFix.updateValue(notifyWeb: notify, size: wSelf.view.bounds.size)
                        if AppSettings.showToastMgsDictionary.isShowView(version: notify.version ?? 0, spanDays: notify.spanDays ?? 0, isNotifWebView: false) {
    
                            wSelf.toastMessageFix.addToParentAdvanceDictionaryView(view: wSelf.contentToastMsg)
                            wSelf.toastMessageFix.showView()
                            wSelf.toastMessageFix.applyShadow()
                            wSelf.showToastMsg()
                            GATracking.scene(.billingAppeal2)
                        } else {
                            wSelf.hideToastMsg()
                        }
                    }
                case .paid:
                    wSelf.lbs.forEach { lb in
                        lb.textColor = Asset._111111Ffffff.color
                    }
                    wSelf.hideToastMsg()
                }
                
            }).disposed(by: disposeBag)
        
        StatusStackView.allCases.forEach { [weak self] type in
            guard let wSelf = self else { return }
            let bt = wSelf.bts[type.rawValue]
            let v = wSelf.views[type.rawValue]
            bt.rx.tap
                .withLatestFrom(output.getBillingInfo, resultSelector: { $1 })
                .bind { [weak self] billingInfo in
                    guard let wSelf = self else { return }
                    if billingInfo.billingStatus == .paid {
                        wSelf.selectView = v
                        wSelf.eventChangeRect.onNext(v)
                        wSelf.eventStatusSearch.accept(type)
                    } else {
                        switch type {
                        case .prefix, .exact:
                            wSelf.selectView = v
                            wSelf.scrollView.scrollRectToVisible(v.frame, animated: true)
                            wSelf.eventChangeRect.onNext(v)
                            wSelf.eventStatusSearch.accept(type)
                        default:
                            wSelf.eventTapToastView.onNext(.showRequestPrenium)
                        }
                    }
                }.disposed(by: disposeBag)
        }
        
        output.eventTapToastView.drive(onNext: { [weak self] tap in
            guard let wSelf = self else { return }
            
            switch tap {
            case .close:
                wSelf.hideToastMsg()
            case .showRequestPrenium: break
            }
            
        }).disposed(by: disposeBag)
        
        output.showNetworkAction
            .drive()
            .disposed(by: self.disposeBag)
        
        output.showResult
            .drive()
            .disposed(by: self.disposeBag)
        
        output.trackingExecSearchData
            .drive(onNext: { [weak self] (trackingExecSearchData) in
            guard let self = self else { return }
            let trackingTap: GATracking.Tap = self.sceneType == .searchInDraft
            ? GATracking.Tap.execSearchInDraft
            : GATracking.Tap.execSearch
            GATracking.tap(trackingTap,
                           params: [
                            .word(trackingExecSearchData.word),
                            .searchKind(trackingExecSearchData.kind),
                            .searchCondition(self.eventStatusSearch.value.searchCondition)
                           ]
            )
        })
        .disposed(by: self.disposeBag)
        
        output.eventDismiss.drive { [weak self] _ in
            guard let wSelf = self else { return }
            wSelf.searchBar.becomeFirstResponder()
        }.disposed(by: self.disposeBag)
        
        output.showPremium
            .drive()
            .disposed(by: self.disposeBag)

    }
    
    private func setupRX() {
        
       let _ = NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .bind(onNext: { _ in self.eventLoadNotifyDictionary.onNext(()) })
            .disposed(by: self.disposeBag)
        
        Observable.combineLatest(self.eventChangeRect.asObservable(), self.eventFinishScroll.asObservable()).bind { [weak self] view, _ in
            guard let wSelf = self else { return }
            wSelf.view.layoutIfNeeded()
            let isLastView = (view.tag == Constant.matchIncludTagView) ? true : false
            wSelf.animateLineView(rect: view.frame, isLastView: isLastView)
            wSelf.scrollView.scrollRectToVisible(view.frame, animated: true)
        }.disposed(by: disposeBag)
        
        Observable.combineLatest(self.rx.viewWillAppear, self.eventDetectLandscape.asObservable())
            .bind { [weak self] (_, item) in
                guard let wSelf = self else { return }
                let size = item.0
                let isFirstLoad = item.1
                wSelf.view.layoutIfNeeded()
            switch DetectDevice.share.currentDevice {
            case .pad:
                if DetectDevice.share.detectLandscape(size: size) {
                    wSelf.rightContraint.constant = Constant.paddingIIpadLandscape
                    wSelf.leftContraint.constant = Constant.paddingIIpadLandscape
                    wSelf.contentTableView.layoutIfNeeded()
                    wSelf.stackView.layoutIfNeeded()
                    let widthStackView = size.width - (Constant.paddingIIpadLandscape * 2) - (Constant.distanceToLeft * 2)
                    let spacing = wSelf.calculateSpacing(widthStackView: widthStackView)
                    wSelf.stackView.spacing = spacing
                } else {
                    wSelf.rightContraint.constant = 0
                    wSelf.leftContraint.constant = 0
                    wSelf.contentTableView.layoutIfNeeded()
                    let widthStackView = size.width - (Constant.distanceToLeft * 2)
                    let spacing = wSelf.calculateSpacing(widthStackView: widthStackView)
                    wSelf.stackView.spacing = spacing
                }
            case .phone:
                if DetectDevice.share.detectLandscape(size: size) {
                    let rightSafeArea = wSelf.view.safeAreaInsets.right
                    let leftSafeArea = wSelf.view.safeAreaInsets.left
                    var widthStackView: CGFloat = size.width - (Constant.distanceToLeft * 2) - rightSafeArea - leftSafeArea
                    if isFirstLoad {
                        widthStackView = size.width - (Constant.distanceToLeft * 2) - wSelf.rightSafeArea - wSelf.leftSafeArea
                    }
                    let spacing = wSelf.calculateSpacing(widthStackView: widthStackView)
                    wSelf.stackView.spacing = spacing
                } else {
                    wSelf.stackView.spacing = Constant.spacingPortraint
                }
                
            default: break
            }
        }.disposed(by: disposeBag)
    }
    
    private func showToastMsg() {
        self.contentToastMsg.isHidden = false
        self.toastMessageFix.showView()
    }
    
    private func hideToastMsg() {
        self.contentToastMsg.isHidden = true
        self.toastMessageFix.hideView()
    }
    
    private func calculateSpacing(widthStackView: CGFloat) -> CGFloat {
        let totalWidthView = Constant.totalView * Constant.widthView + Constant.widthLastView
        return (widthStackView - totalWidthView) / Constant.totalSpacing
    }
    
    private func animateLineView(rect: CGRect, isLastView: Bool) {
        var f = self.lineView.frame
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            f.origin.x = rect.origin.x
            f.size.width = rect.size.width
            self.lineView.frame = f
        }, completion: nil)
    }
    
    @objc func dismissButtonPressed(_ sender: Any) {
        self.eventDismiss.onNext(.dismiss)
    }
    
    private func updateAttributeSearchTextIfNeed() {
        if let textField = searchBar.getTextField() {
            var defaultTextAttributeColor = Asset.searchBarText.color
            if textField.text?.isEmpty ?? true {
                textField.textColor = .black
                defaultTextAttributeColor = .black
            }
            
            textField.defaultTextAttributes = [
                NSAttributedString.Key.font: UIFont.hiraginoSansW4(size: 16),
                NSAttributedString.Key.foregroundColor: defaultTextAttributeColor,
            ]
            
            textField.markedTextStyle = [
                NSAttributedString.Key.font: UIFont.hiraginoSansW4(size: 16),
                NSAttributedString.Key.backgroundColor: Asset.searchBarMarkedText.color,
                NSAttributedString.Key.foregroundColor: UIColor.black,
            ]
            
            textField.typingAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.black
            ]
        }
    }
    
}
extension AdvancedDictionaryVC: UIScrollViewDelegate {
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.eventFinishScroll.accept(())
    }
}
extension AdvancedDictionaryVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
}
extension AdvancedDictionaryVC: ToastMessageFixViewDelegate {
    func tapAction(tap: ToastMessageFixView.TapAction) {
        let trackingTap: GATracking.Tap = self.sceneType == .searchInDraft
        ? (tap == .close ? GATracking.Tap.searchConditionsInPremiumInfoDraftClose : GATracking.Tap.searchConditionsInPremiumInfoDraft)
        : (tap == .close ? GATracking.Tap.searchConditionsInPremiumInfoClose : GATracking.Tap.searchConditionsInPremiumInfo)
        GATracking.tap(trackingTap)
        self.eventTapToastView.onNext(tap)
    }
}
extension AdvancedDictionaryVC: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        updateAttributeSearchTextIfNeed()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateAttributeSearchTextIfNeed()
    }
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // we need a delay time to the search bar updating current text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.didTyping.onNext(())
        }
        
        return true
    }
    
}
