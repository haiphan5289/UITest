//
//  BackupDetailViewController.swift
//  GooDic
//
//  Created by Vinh Nguyen on 26/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class BackupDetailViewController: BaseViewController, ViewBindableProtocol {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var containerStackView: UIStackView!
    @IBOutlet weak var backupView: BackupView!
    @IBOutlet weak var creationView: BackupView!
    
    @IBOutlet weak var restoreBackupBarButtonItem: UIBarButtonItem!
    
    private let disposeBag = DisposeBag()
    var viewModel: BackupDetailViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupRX()
    }

}
extension BackupDetailViewController {
    
    private func setupUI() {
        
    }
    
    private func updateUI(backupDocument: CloudBackupDocument, document: Document) {
        self.backupView.updateUIWith(backupDocument: backupDocument, document: document, viewType: .backup)
        self.creationView.updateUIWith(backupDocument: backupDocument, document: document, viewType: .created)
    }
    
    func bindViewModel() {
        
        let input = BackupDetailViewModel
            .Input(loadDataTrigger: Driver.just(()),
                   restoreBackupDraftTrigger: restoreBackupBarButtonItem.rx.tap.asDriverOnErrorJustComplete()
                   )
        
        let output = viewModel.transform(input)
        
        output.loadData
            .drive(onNext: {[weak self] data in
                guard let wSelf = self else {
                    return
                }
                
                wSelf.updateUI(backupDocument: data.1, document: data.0)
            })
            .disposed(by: self.disposeBag)
        
        output.loadData.drive().disposed(by: disposeBag)
        
        output.showAlertRestoreBackupDraft.drive().disposed(by: disposeBag)
        output.restoreBackupDraft.drive().disposed(by: disposeBag)
        output.error.drive().disposed(by: disposeBag)
    
        
        tracking(output: output)
    }
    
    private func setupRX() {

    }
    
    private func tracking(output: BackupDetailViewModel.Output) {
        // track scene
        GATracking.scene(self.sceneType)
        
        // track tap events

    }
}

