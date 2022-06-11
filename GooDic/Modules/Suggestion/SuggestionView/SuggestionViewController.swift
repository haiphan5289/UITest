//
//  SuggestionViewController.swift
//  GooDic
//
//  Created by ttvu on 5/19/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol SuggestionVCNavigationDelegate: class {
    func dismiss(vc: SuggestionViewController)
}

class SuggestionViewController: BaseViewController, ViewBindableProtocol {
    
    // MARK: - UI & Data
    @IBOutlet weak var dismissButton: UIBarButtonItem!
    @IBOutlet weak var feedbackButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    
    weak var delegate: SuggestionVCNavigationDelegate?
    
    // MARK: - Rx
    let disposeBag = DisposeBag()
    var viewModel: SuggestionViewModel!// = SuggestionViewModel(data: [], navigator: nil)
    var showInfoTrigger = PublishSubject<String>()
    private var updateHeight: BehaviorSubject<Bool> = BehaviorSubject.init(value: false)
    private var cell: SuggestionTVC?
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setupUI()
        bindUI()
        tracking()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupNavigationTitle(type: .suggestion)
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { _ in
            self.updateHeight.onNext(true)
        }
    }
    
    private func setupUI() {
        let cellName = String(describing: SuggestionTVC.self)
        let nib = UINib(nibName: cellName, bundle: Bundle.main)
        tableView.register(nib, forCellReuseIdentifier: SuggestionTVC.reuseIdentifier)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.hideEmptyCells()
        
        let text = self.sceneType == GATracking.Scene.proofread ? L10n.Suggestion.idiomEmpty : L10n.Suggestion.thesaurus
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = GlobalConstant.spacingParagraphStyle
        paragraphStyle.maximumLineHeight = 21
        paragraphStyle.minimumLineHeight = 21
        paragraphStyle.alignment = .center
        
        let attr = NSAttributedString(string: text, attributes: [
            NSAttributedString.Key.foregroundColor: Asset.textPrimary.color,
            NSAttributedString.Key.font: UIFont.hiraginoSansW4(size: 16),
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ])
        
        emptyLabel.attributedText = attr
        
        self.view.addSeparator(at: .top, color: Asset.modelCellSeparator.color)
    }
    
    private func tracking() {
        GATracking.scene(self.sceneType)
    }
    
    private func bindUI() {
        showInfoTrigger
            .map({ [weak self] _ -> GATracking.Tap? in
                guard let self = self else { return nil }
                if self.sceneType == .paraphrase {
                    return .tapSearchWordToParaphrase
                } else {
                    return .tapSearchWordToProofread
                }
            })
            .compactMap({ $0 })
            .subscribe(onNext: GATracking.tap)
            .disposed(by: self.disposeBag)
    }
    
    func bindViewModel() {
        tableView.dataSource = self
        tableView.reloadData()
        
        let input = SuggestionViewModel.Input(
            loadTrigger: Driver.just(()),
            dismissTrigger: dismissButton.rx.tap.asDriver(),
            feedbackTrigger: feedbackButton.rx.tap.asDriver(),
            showInfoTrigger: showInfoTrigger.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        output.dismiss
            .drive()
            .disposed(by: self.disposeBag)
        
        output.hasData
            .map({ !$0 })
            .drive(onNext: { [weak self] (isHidden) in
                guard let self = self else { return  }
                UIView.animate(withDuration: 0.3) {
                    self.tableView.alpha = isHidden ? 0 : 1
                }
            })
            .disposed(by: self.disposeBag)
        
        output.hasData
            .filter({ $0 })
            .drive(onNext: { [weak self] (_) in
                self?.tableView.reloadData()
            })
            .disposed(by: self.disposeBag)
        
        output.feedback
            .drive()
            .disposed(by: self.disposeBag)
        
        output.showInfo
            .drive()
            .disposed(by: self.disposeBag)
        
        self.updateHeight
            .asObservable()
            .bind { [weak self] (isRotate) in
                guard isRotate , let self = self else {
                    return
                }
                self.viewModel.refreshHeightCell()
                self.tableView.reloadData()
            }.disposed(by: disposeBag)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}

extension SuggestionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(at: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SuggestionTVC.reuseIdentifier, for: indexPath) as! SuggestionTVC
        
        if let item = viewModel.item(atIndexPath: indexPath) {
            cell.bind(data: item)
            
            if self.viewModel.cellHeight(atIndexPath: indexPath) == 0 {
                let height = cell.tagView.expectedHeight(withWidth: SuggestionTVC.tagViewWidth(withTableViewWidth: tableView.bounds.width))
                self.viewModel.updateCellHeight(atIndexPath: indexPath, newValue: height)
                self.cell = cell
            }
            
            cell.tappedOnInfoBlock = { [weak self] (path) in
                if let path = path {
                    self?.showInfoTrigger.onNext(path)
                }
            }
            
            cell.tappedOnTagBlock = { [weak self] (tagType) in
                guard let self = self else { return }
                self.viewModel.tapOn(tag: tagType, section: indexPath.section, gdDataitemMain: item)
                if self.sceneType == .paraphrase {
                    GATracking.tap(.tapParaphraseWord)
                } else {
                    GATracking.tap(.tapProofreadWord)
                }
                
                if let reloadIndexPath = self.tableView.indexPath(for: cell) {
                    self.tableView.reloadRows(at: [reloadIndexPath], with: .none)
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.titleForHeader(inSection: section)
    }
}

extension SuggestionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = viewModel.cellHeight(atIndexPath: indexPath)
        return height
    }
    
//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        DispatchQueue.global(qos: .background).async {
//            if self.viewModel.cellHeight(atIndexPath: indexPath) == 0, let data = self.viewModel.item(atIndexPath: indexPath) {
//                let maxWidth = SuggestionTVC.tagViewWidth(withTableViewWidth: UIScreen.main.bounds.width)
//                let height = TagView.expectedHeight(withWidth: maxWidth, tags: data.tags())
//                self.viewModel.updateCellHeight(atIndexPath: indexPath, newValue: height)
//            }
//        }
//
//        return 64
//    }
}
