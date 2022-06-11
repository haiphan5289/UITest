//
//  NamingViewController.swift
//  GooDic
//
//  Created by ttvu on 10/6/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class NamingViewController: UIViewController, ViewBindableProtocol {
    
    struct Constant {
        static let heightWithoutWarning: CGFloat = 14.0
        static let heightWithWarning: CGFloat = 34.0
        static let checkBoxVisible: CGFloat = 16.0
        static let checkBoxInvisible: CGFloat = -24.0
    }
    
    // MARK: - UI
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var cloudButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var warningConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var checkBoxBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Rx + Data
    let disposeBag = DisposeBag()
    var viewModel: NamingViewModel!
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupUI()
        tracking()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        textField.becomeFirstResponder()
    }
    
    // MARK: - Funcs
    func setupUI() {
        popupView.layer.cornerRadius = 10
        cancelButton.superview?.addSeparator(at: .top, color: Asset.separator.color)
        cancelButton.addSeparator(at: .right, color: Asset.separator.color)
        
        textField.attributedPlaceholder = NSAttributedString(string: L10n.Folder.placeholder, attributes: [
            NSAttributedString.Key.foregroundColor: Asset.namingPlaceholder.color
        ]) 
        textField.tintColor = Asset.highlight.color
        textField.delegate = self
        
        textField.markedTextStyle = [
            NSAttributedString.Key.backgroundColor: Asset.searchBarMarkedText.color,
            NSAttributedString.Key.foregroundColor: UIColor.black
        ]
    }
    
    func bindViewModel() {
        let input = NamingViewModel.Input(
            loadTrigger: Driver.just(()),
            nameTrigger: textField.rx.text.orEmpty.asDriver(),
            isCloudTrigger: cloudButton.rx.tap.asDriver(),
            cancelTrigger: cancelButton.rx.tap.asDriver(),
            okTrigger: okButton.rx.tap.asDriver(),
            userInfo: AppManager.shared.userInfo.asDriver())
        
        let output = viewModel.transform(input)
        
        output.title
            .drive(self.titleLabel.rx.text)
            .disposed(by: self.disposeBag)
        
        output.message
            .drive(self.messageLabel.rx.text)
            .disposed(by: self.disposeBag)
        
        output.warningMessage
            .drive(onNext: { [weak self] text in
                guard let self = self else { return }
                UIView.transition(with: self.warningLabel,
                                  duration: 0.3,
                                  options: .transitionCrossDissolve) {
                    self.warningLabel.text = text
                }
            })
            .disposed(by: self.disposeBag)
        
        output.warningMessage
            .map({ $0.isEmpty ? Constant.heightWithoutWarning : Constant.heightWithWarning })
            .drive(onNext: { [weak self] value in
                self?.warningConstraint.constant = value
                UIView.animate(withDuration: 0.3) {
                    self?.view.layoutIfNeeded()
                }
            })
            .disposed(by: self.disposeBag)
        
        output.confirmButtonName
            .drive(onNext: { [weak self] name in
                self?.okButton.setTitle(name, for: .normal)
            })
            .disposed(by: self.disposeBag)
        
        output.startWithName
            .drive(self.textField.rx.text)
            .disposed(by: self.disposeBag)
        
        output.keyboardHeight
            .filter({ !($0.duration == 0 && $0.height < 100) })
            .drive(onNext: { [weak self] anim in
                guard let self = self else { return }
                
                let duration = anim.duration > 0 ? anim.duration : 0.3
                
                let hasAnim = self.view.bounds.height - anim.height > self.popupView.bounds.height ? true : false

                if hasAnim {
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        UIView.animate(withDuration: duration) {
                            self.bottomConstraint.priority = .defaultLow
                            self.bottomConstraint.constant = anim.height
                            self.view.layoutIfNeeded()
                        }
                    }
                } else {
                    self.bottomConstraint.priority = .defaultHigh
                    self.bottomConstraint.constant = anim.height
                    self.view.layoutIfNeeded()
                }
                
            })
            .disposed(by: self.disposeBag)
        
        output.isCloud
            .map({ $0 ? Asset.icRadioBlueOn.image : Asset.icRadioBlueOff.image })
            .drive(self.cloudButton.rx.image(for: .normal))
            .disposed(by: self.disposeBag)
        
        output.showCloudCheckbox
            .drive(onNext: { [weak self] canCreate in
                self?.checkBoxBottomConstraint.constant = canCreate ? Constant.checkBoxVisible : Constant.checkBoxInvisible
                self?.cloudButton.isHidden = !canCreate
            })
            .disposed(by: self.disposeBag)
        
        output.dismiss
            .drive()
            .disposed(by: self.disposeBag)
        
        output.loading
            .drive(onNext: { show in
                if show {
                    GooLoadingViewController.shared.show()
                } else {
                    GooLoadingViewController.shared.hide()
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    private func tracking() {
        cloudButton.rx.tap
            .bind(onNext: { _ in
                GATracking.tap(.tapCheckboxUpToCloud)
            })
            .disposed(by: self.disposeBag)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { (context) in
            self.bottomConstraint.priority = .defaultLow
        }
    }
}

extension NamingViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let textRange = self.textField.textRange(from: self.textField.beginningOfDocument, to: self.textField.endOfDocument)
            self.textField.selectedTextRange = textRange
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        if let validText = viewModel.validate(content: textField.text ?? "", shouldChangeTextIn: range, replacementText: string) {
//            if textField.text != validText, let endToEnd = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument) {
//                textField.replace(endToEnd, withText: validText)
//            }
//            return false
//        }
//        return true
        guard let textFieldText = textField.text,
                let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                    return false
            }
            let substringToReplace = textFieldText[rangeOfTextToReplace]
            let count = textFieldText.count - substringToReplace.count + string.count
        return count <= NamingUseCase.Constant.maxContent
        }
}
