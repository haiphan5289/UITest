//
//  DictionaryViewController.swift
//  GooDic
//
//  Created by ttvu on 5/18/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import WebKit

class DictionaryViewController: BaseViewController, ViewBindableProtocol {

    // MARK: - UI
    @IBOutlet weak var searchBarBg: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var dropDownView: UIView!
    @IBOutlet weak var illustrationScrollView: UIScrollView!
    @IBOutlet weak var dropDownViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var dropDownViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var btMovetoAdvance: UIButton!
    weak var dropDownViewController: DropDownViewController?
    
    var dismissButton: UIBarButtonItem?
    
    // MARK: - Rx + Data
    let disposeBag = DisposeBag()
    var viewModel: DictionaryViewModel!
    
    let didTyping = PublishSubject<Void>()
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        updateUI()
        bindUI()
        tracking()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        removeAllCookie()
    }
    
    private func removeAllCookie() {
        let websiteDataTypes: NSSet = [
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeOfflineWebApplicationCache,
            WKWebsiteDataTypeMemoryCache,
            WKWebsiteDataTypeLocalStorage,
            WKWebsiteDataTypeCookies,
            WKWebsiteDataTypeSessionStorage,
            WKWebsiteDataTypeIndexedDBDatabases,
            WKWebsiteDataTypeWebSQLDatabases
        ];
        let dateFrom: NSDate = NSDate(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: dateFrom as Date, completionHandler: {() -> Void in
            // Done
        })
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Funcs
    func updateUI() {
        let searchIcon = Asset.icSearch.image
        searchBar.setImage(searchIcon, for: .search, state: .normal)
        
        let clearIcon = Asset.icDelete.image
        searchBar.setImage(clearIcon, for: .clear, state: .normal)
        
        if let textField = searchBar.getTextField() {
            textField.font = UIFont.hiraginoSansW4(size: 16)
            textField.backgroundColor = UIColor.clear
        }
        updateAttributeSearchTextIfNeed()
        
        // remove the 2 lines on top and on bottom of search Bar
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 12, vertical: 0)
        
        // update search bar bg
        searchBarBg.backgroundColor = Asset.searchBarBg.color
        searchBarBg.layer.borderColor = Asset.searchBarBorder.color.cgColor
        searchBarBg.layer.borderWidth = 1
        searchBarBg.layer.cornerRadius = 5

        // add a gesture to dismiss the keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureHandle(_:)))
        tapGesture.delegate = self
        tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
        
        let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(tapGestureHandle(_:)))
        tapGesture2.delegate = self
        tapGesture2.numberOfTapsRequired = 1
        tapGesture2.cancelsTouchesInView = false
        illustrationScrollView.addGestureRecognizer(tapGesture2)

        // setup dismiss button if needed
        if dismissButton != nil {
            self.navigationItem.leftBarButtonItem = dismissButton
            dismissButton?.target = self
            dismissButton?.action = #selector(dismissButtonPressed(_:))
            self.navigationItem.leftBarButtonItem?.tintColor = Asset.textPrimary.color
            
            self.view.backgroundColor = Asset.modelBackground.color
        }
        
        // setup dropDown
        dropDownView.layer.borderColor = UIColor.gray.cgColor
        dropDownView.layer.borderWidth = 0.5
        dropDownView.layer.cornerRadius = 5
    }
    
    func bindUI() {
        guard let tableView = self.dropDownViewController?.tableView else { return }
        
        tableView.reloadDataEvent.asDriver()
            .drive(onNext: { [weak self] (_) in
                guard let self = self else { return }
                
                self.dropDownViewHeightConstraint.constant = self.dropDownViewController?.tableView.contentSize.height ?? 0
                self.view.layoutIfNeeded()
            })
            .disposed(by: self.disposeBag)
        
        // remove selection color
        tableView.rx
            .itemSelected
            .subscribe(onNext: { [weak tableView] (indexPath) in
                tableView?.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    func bindViewModel() {
        guard let dropDownViewController = self.dropDownViewController else { return }
        
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
        
        let input = DictionaryViewModel.Input(
            textTrigger: textTrigger,
            searchInputTrigger: searchBar.rx.searchButtonClicked.asDriver(),
            selectedItem: dropDownViewController.tableView.rx.itemSelected.asDriver().map({ $0.row }),
            moveToAdvanced: self.btMovetoAdvance.rx.tap.asDriverOnErrorJustComplete()
        )

        
        let output = viewModel.transform(input)
        
        output.showResult
            .drive()
            .disposed(by: self.disposeBag)
        
        output.showSuggestion
            .drive(onNext: { [weak self] (values) in
                guard let self = self else { return }
                
                self.dropDownView.isHidden = values.count == 0
                self.dropDownViewController?.data = values
            })
            .disposed(by: self.disposeBag)
        
       
            output.searchString
                .drive(onNext: { [weak self] (value) in
                    if #available(iOS 13.0, *) {
                        let newText = NSMutableAttributedString(string: value, attributes: [
                            NSAttributedString.Key.font: UIFont.hiraginoSansW4(size: 16),
                            NSAttributedString.Key.foregroundColor: Asset.searchBarText.color
                        ])
                        
                        self?.searchBar.searchTextField.attributedText = newText
                    } else {
                        self?.searchBar.text = value
                    }
                })
                .disposed(by: self.disposeBag)
        
        
        output.keyboardHeight
            .map({ $0.height })
            .do(onNext: { (height) in
                let paddingBottom: CGFloat = 10
                let dropDownBottomConstant = height > 0 ? height - self.view.safeAreaInsets.bottom : 0
                self.dropDownViewBottomConstraint.constant = (dropDownBottomConstant + paddingBottom)
                self.view.layoutIfNeeded()
            }, afterNext: { (_) in
                self.dropDownViewHeightConstraint.constant = self.dropDownViewController?.tableView.contentSize.height ?? 0
                self.view.layoutIfNeeded()
            })
            .drive()
            .disposed(by: self.disposeBag)
        
//        output.errorHandler
//            .drive()
//            .disposed(by: self.disposeBag)
        
        output.showNetworkAction
            .drive()
            .disposed(by: self.disposeBag)
        
        output.moveToAdvanced
            .drive()
            .disposed(by: self.disposeBag)
                
        output.showPremium
            .drive()
            .disposed(by: self.disposeBag)
    }
    
    private func tracking() {
        // track scene
        GATracking.scene(self.sceneType)
    }
    
    @objc func dismissButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? DropDownViewController {
            self.dropDownViewController = vc
        }
    }
    
    @objc func tapGestureHandle(_ gesture: UITapGestureRecognizer) {
        self.searchBar.resignFirstResponder()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            searchBarBg.layer.borderColor = Asset.searchBarBorder.color.cgColor
        }
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

extension DictionaryViewController: UISearchBarDelegate {
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

// MARK: - UIGestureRecognizerDelegate
extension DictionaryViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == view || touch.view == illustrationScrollView ? true : false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
