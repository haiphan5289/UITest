//
//  CreationViewController.swift
//  GooDic
//
//  Created by ttvu on 5/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CreationViewController: BaseViewController, ViewBindableProtocol {
    
    struct Constant {
        static let widthOfiPhoneSE1: CGFloat = 320.0
        static let expandedRange: Int = 0//10
        static let distanceBottomToMainView: CGFloat = 59
        static let widthLimit: CGFloat = 60
        static let widthButtonIdiomOniPhoneSE1: CGFloat = 48
        static let distanceBetweenRange: Int = 400
        static let lengthTextReplace: Int = 1
        
    }
    
    enum TapHeader {
        case search, setting, next, previous, cleanText, settingSearch, replace, replaceAll, updateContent, unSearch, cleanReplace, hideSettingFont, other, editChanged
    }
    
    struct TextReplace {
        let text: String
        let tap: TapHeader
        init(text: String, tap: TapHeader) {
            self.text = text
            self.tap = tap
        }
    }
    
    struct TextReplaceUpdate {
        let text: String
        let range: NSRange
        init(text: String, range: NSRange) {
            self.text = text
            self.range = range
        }
    }
    
    struct HandleReplace {
        let textView: UITextView
        let range: NSRange
        let replace: String
        let pasteOverLength: PasteOverLength
        init(textView: UITextView, range: NSRange, replace: String, pasteOverLength: PasteOverLength ) {
            self.textView = textView
            self.range = range
            self.replace = replace
            self.pasteOverLength = pasteOverLength
        }
    }
    
    enum PasteOverLength {
        case paste, replace, inputText, saveDraftOver, dismissDraft
    }
    
    // MARK: - UI
    @IBOutlet weak var dismissButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var shareButtonItem: UIBarButtonItem!
    @IBOutlet weak var stackView: UIStackView! // contains both progressView and MainView
    @IBOutlet weak var progressView: GDProgressView!
    
    // Font style
    @IBOutlet weak var fontButton: UIButton!
    @IBOutlet weak var fontStyleView: FontStyleView!
    @IBOutlet weak var fontStyleViewTopConstraint: NSLayoutConstraint!
    
    // MainView: [TopView, ContentTextView]
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var mainBottomConstraint: NSLayoutConstraint!
    
    
    // TopView (Title)
    @IBOutlet weak var topView: ScrollableTextField! // content textField
    @IBOutlet weak var topViewTopConstraint: NSLayoutConstraint!
    lazy var titleTextField: InnerTextField = {
        self.topView.textField!
    }()
    var contentTextView: PlaceholderTextView!
//    @IBOutlet weak var btSearch: UIBarButtonItem!
    @IBOutlet weak var btSetting: UIButton!
    @IBOutlet weak var btSearch: UIButton!
    @IBOutlet weak var viewSearch: UIView!
    @IBOutlet weak var tfSearch: UITextField!
    
    // Toolbar
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var idiomButton: UIButton!
    @IBOutlet weak var thesaurusButton: UIButton!
    @IBOutlet weak var dictionaryButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    @IBOutlet weak var keyboardStateButton: UIButton!
    @IBOutlet weak var fixedThesaurus: UIBarButtonItem!
    @IBOutlet weak var fixedKeyboardState: UIBarButtonItem!
    @IBOutlet weak var fontStyleRightSafe: NSLayoutConstraint!
    @IBOutlet weak var fontStyleLeftSafe: NSLayoutConstraint!
    @IBOutlet weak var stackViewRight: NSLayoutConstraint!
    @IBOutlet weak var stackViewLeft: NSLayoutConstraint!
    @IBOutlet weak var widthStackView: NSLayoutConstraint!
    @IBOutlet weak var widthFontStyleView: NSLayoutConstraint!
    @IBOutlet weak var searchBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var btNextSearch: UIButton!
    @IBOutlet weak var btPreviousSearch: UIButton!
    @IBOutlet weak var lbTotalSearch: UILabel!
    @IBOutlet weak var btClean: UIButton!
    @IBOutlet weak var btSettingSearch: UIButton!
    @IBOutlet weak var vReplace: UIView!
    @IBOutlet weak var vSearch: UIView!
    @IBOutlet weak var btReplace: UIButton!
    @IBOutlet weak var btReplaceAll: UIButton!
    @IBOutlet weak var tfReplace: UITextField!
    @IBOutlet weak var btCleanReplace: UIButton!
    @IBOutlet weak var hViewBottomSearch: NSLayoutConstraint!
    @IBOutlet var viewsSearch: [BorderView]!
    @IBOutlet weak var stackViewButtonNext: UIStackView!
    @IBOutlet weak var stackViewButtonDetail: UIStackView!
    @IBOutlet weak var wLabelTotalSearch: NSLayoutConstraint!
    @IBOutlet weak var trailingViewSearch: NSLayoutConstraint!
    @IBOutlet weak var stackViewReplace: UIStackView!
    @IBOutlet weak var viewCoverSettingSearch: UIView!
    @IBOutlet weak var stackViewButtonClean: UIStackView!
    @IBOutlet weak var trailingStackViewSearch: NSLayoutConstraint!
    @IBOutlet weak var trailingViewSearchiPhone: NSLayoutConstraint!
    private let tapViewCoverSettingSearch: UITapGestureRecognizer = UITapGestureRecognizer()
    @IBOutlet weak var leadingStackViewReplace: NSLayoutConstraint!
    @IBOutlet weak var leadingSearchBar: NSLayoutConstraint!
    @IBOutlet weak var leadingContainerSearchView: NSLayoutConstraint!
    @IBOutlet weak var trailingContainerSearchView: NSLayoutConstraint!
    private var wIdiomButton: CGFloat = 1
    private var wThesaurusButton: CGFloat = 1
    private var wDictionaryButton: CGFloat = 1
    
    // tooltip popup are going to add to bottomView instead of toolBar.
    // Because the popup's interaction will be lose, it you do that
    var tooltipPopup: UIImageView!
    
    // MARK: - Rx + Data
    var viewModel: CreationViewModel!
    var disposeBag = DisposeBag()
    var updateRawTitleTrigger = PublishSubject<String>()
    var updateRawContentTrigger = PublishSubject<String>()
    var tapTooltip = PublishSubject<Void>()
    var tapContentView = PublishSubject<Void>()
    private var updateTooltip: PublishSubject<Bool> = PublishSubject.init()
    private var isRotation: PublishSubject<Void> = PublishSubject.init()
    private var showTooltip: BehaviorSubject<Bool> = BehaviorSubject.init(value: false)
    private var displayViewButton: BehaviorSubject<Bool> = BehaviorSubject.init(value: false)
    private var displayViewDidLayout: PublishSubject<Bool> = PublishSubject.init()
    private var updateTextView: PublishSubject<Void> = PublishSubject.init()
    private var updateSpacingButtonIPad: PublishSubject<(Bool, CGSize)> = PublishSubject.init()
    private var updateSpacingButtonIPhone: PublishSubject<Bool> = PublishSubject.init()
    private var viewDidChangeRotate: PublishSubject<Void> = PublishSubject.init()
    private var eventTextOverMaxLenght: PublishSubject<HandleReplace> = PublishSubject.init()
    private var eventShowAlertMaxLenght: PublishSubject<HandleReplace> = PublishSubject.init()
    private var eventShowAlertTitleMaxLenght: PublishSubject<UITextRange?> = PublishSubject.init()
    private var eventSettingSearch: PublishSubject<Void> = PublishSubject.init()
    private var eventNumberOfCharacters: PublishSubject<Int> = PublishSubject.init()
    private var eventUpdateListRangeWhenReplace: PublishSubject<TextReplaceUpdate> = PublishSubject.init()
    private var eventSaveDraft: PublishSubject<Void> = PublishSubject.init()
    private var eventDismissDraft: PublishSubject<Void> = PublishSubject.init()
    private var eventAutoSaveCloud: PublishSubject<Bool> = PublishSubject.init()
    
    private var dictionaryMenuItemTrigger: PublishSubject<String?> = PublishSubject.init()
    private var spaceToolBar: CGFloat?
    private var currentPresent: (PresentAnim, PresentAnim)?
    private var settingFont: SettingFont?
    private var tapSearch: Bool = false
    private var maxTextViewBottomInset: CGFloat?
    private var listPosition: [NSRange] = []
    private var previouRangeLocation: Int = 0
    private var previousRangeSuggestion: Int = 0
    
    // Workaround: Mask ContentView to avoid UndoManager reset after set attribute string.
    // Should remove it after used Custom UndoManager
    /* Begin */
    var maskContentTextView: PlaceholderTextView!
    var shouldBindContentOffset = false
    private var cacheListRange: [NSRange] = []
    private var lastCurrentIndex: NSRange?
    /* End */

    // used on the Auto-Hiding Title feature. In case users touch on a suggestion item that belongs to the title, the title has to be displayed.
    var forceShowTitleTrigger = PublishSubject<Void>()
    
    lazy var paragraphStyle: NSMutableParagraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = GlobalConstant.spacingParagraphStyle
        paragraphStyle.maximumLineHeight = 21
        paragraphStyle.minimumLineHeight = 21
        return paragraphStyle
    }()
    
    private var lastCursorAPI: Int?
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupUI()
        
        updateUndoRedoState()
        
        bindUI()
        tracking()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.eventSettingSearch.onNext(())
        self.setupNavigationTitle(type: .draft)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        displayViewDidLayout.onNext(true)
        
        if self.view.bounds.size.width == Constant.widthOfiPhoneSE1 {
            self.dictionaryButton.bounds.size.width = Constant.widthButtonIdiomOniPhoneSE1
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        calucationSizeTooltipWithSmallDevice()
    }
    
    private func calucationSizeTooltipWithSmallDevice() {
        if let frameIdiom = self.idiomButton.superview?.frame {
            if frameIdiom.center.x < tooltipPopup.frame.size.width/2 {
                let ratio = tooltipPopup.frame.size.width / tooltipPopup.frame.size.height
                let newWidth = (frameIdiom.center.x - 5) * 2
                let newHeight = newWidth / ratio
                tooltipPopup.frame.size = CGSize(width: newWidth, height: newHeight)
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { [unowned self] _ in
            self.fontStyleView.setNeedsDisplay()
            self.updateUIToolBar(size: size, isFirst: false)
            self.updateTooltip.onNext(true)
            self.isRotation.onNext(())
            self.updateTextView.onNext(())
        }
    }
    
    // MARK: - Funcs
    private func setupUI() {
        // set font to the save button
        let saveBtnAtts = [NSAttributedString.Key.font: UIFont.hiraginoSansW4(size: 16)]
        saveButton.setTitleTextAttributes(saveBtnAtts, for: .normal)
        
        // place `progressView` in front of `topView`
        progressView.layer.zPosition = topView.superview!.layer.zPosition + 1
        
        // place `fontStyleView` in front of `progressView`
        fontStyleView.layer.zPosition = progressView.layer.zPosition + 1
        
        topView.addSeparator(at: .bottom, color: Asset.separator.color)
        
        // setup text field UI
        titleTextField.delegate = self
        titleTextField.pasteDelegate = self
        titleTextField.font = UIFont.textFieldFont
        titleTextField.textColor = Asset.textPrimary.color
        titleTextField.attributedPlaceholder = NSAttributedString(string: L10n.Creation.Placeholder.title, attributes: [
            NSAttributedString.Key.font: UIFont.textFieldFont,
            NSAttributedString.Key.foregroundColor: Asset.textPlaceholder.color
        ])
        
        stackView.distribution = .fill
        
        // setup text view UI
        createContentTextView()
        createMaskContentTextView()
        contentTextView.delegate = self
        contentTextView.pasteDelegate = self
        contentTextView.placeholder = L10n.Creation.Placeholder.content
        contentTextView.placeholderColor = Asset.textPlaceholder.color
        contentTextView.font = UIFont.textViewFont
        contentTextView.textColor = Asset.textPrimary.color
        contentTextView.textContainerInset = UIEdgeInsets(top: 16 + topView.bounds.height,
                                                          left: 16,
                                                          bottom: 16,
                                                          right: 16)
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.tintColor = Asset.highlight.color
        contentTextView.tintColorDidChange()
        
        var typingAttrs = contentTextView.typingAttributes
        typingAttrs[.paragraphStyle] = self.paragraphStyle
        contentTextView.typingAttributes = typingAttrs
        
        // non-contiguous layout is necessary with a large document, in this case, it's a long text or complex attribute text
        contentTextView.layoutManager.allowsNonContiguousLayout = true
        
        let tapOnContentGesture = UITapGestureRecognizer(target: self, action: #selector(tapOnContentGestureHandle(_:)))
        tapOnContentGesture.delegate = self
        tapOnContentGesture.numberOfTapsRequired = 1
        contentTextView.addGestureRecognizer(tapOnContentGesture)
        
        // setup tooltip popup
        let image = Asset.imgTutoCheck.image
        self.tooltipPopup = UIImageView(image: image)
        
        self.tooltipPopup.addTapGesture { [weak self] (gesture) in
            self?.tapTooltip.onNext(())
        }
        
        // scale buttons on toolbar
        
        self.wIdiomButton = self.idiomButton.bounds.width
        self.wThesaurusButton = self.thesaurusButton.bounds.width
        self.wDictionaryButton = self.dictionaryButton.bounds.width
        
        self.hViewBottomSearch.constant = self.view.safeAreaBottom
        
        self.tfSearch.attributedPlaceholder = NSAttributedString(string: L10n.Creation.Placeholder.search, attributes: [
            NSAttributedString.Key.font: UIFont.hiraginoSansW4(size: 14),
            NSAttributedString.Key.foregroundColor: Asset._9B9B9BAdadad.color
        ])
        
        self.tfReplace.attributedPlaceholder = NSAttributedString(string: L10n.Creation.Placeholder.replace,
                                                                  attributes: [
            NSAttributedString.Key.font: UIFont.hiraginoSansW4(size: 14),
            NSAttributedString.Key.foregroundColor: Asset._9B9B9BAdadad.color
        ])
        setupMenuItemDictionary()
        self.viewCoverSettingSearch.addGestureRecognizer(self.tapViewCoverSettingSearch)
    }
    
    private func setupMenuItemDictionary() {
        let itemDictionary = UIMenuItem(title: L10n.Creation.BarItem.dictionary , action: #selector(tapMenuItemDictionary))
        UIMenuController.shared.menuItems = [itemDictionary]

    }

    @objc func tapMenuItemDictionary() {
        if let rangeTextContent = contentTextView.selectedTextRange, let selectedText = contentTextView.text(in: rangeTextContent) {
           dictionaryMenuItemTrigger.onNext(selectedText)
        }
        
        if let rangeTextTitle = titleTextField.selectedTextRange, let selectedText = titleTextField.text(in: rangeTextTitle) {
            dictionaryMenuItemTrigger.onNext(selectedText)
        }
        
        GATracking.tap(.tapCharacterSelectionSearch)
    }
    
    private func createContentTextView() {
        let layoutManager = GooLayoutManager()
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        
        layoutManager.addTextContainer(textContainer)
        
        contentTextView = PlaceholderTextView(frame: mainView.bounds, textContainer: textContainer)
        mainView.insertSubview(contentTextView, at: 0)
        
        layoutManager.invalidateDisplay(forGlyphRange: NSRange(location: 0, length: contentTextView.attributedText.length))
        
        contentTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentTextView.topAnchor.constraint(equalTo: mainView.topAnchor),
            contentTextView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor),
            contentTextView.leftAnchor.constraint(equalTo: mainView.leftAnchor),
            contentTextView.rightAnchor.constraint(equalTo: mainView.rightAnchor),
        ])
    }
    
    private func createMaskContentTextView() {
        let layoutManager = GooLayoutManager()
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        
        layoutManager.addTextContainer(textContainer)
        
        maskContentTextView = PlaceholderTextView(frame: mainView.bounds, textContainer: textContainer)
        mainView.insertSubview(maskContentTextView, aboveSubview: contentTextView)
        
      
        maskContentTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            maskContentTextView.topAnchor.constraint(equalTo: mainView.topAnchor),
            maskContentTextView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor),
            maskContentTextView.leftAnchor.constraint(equalTo: mainView.leftAnchor),
            maskContentTextView.rightAnchor.constraint(equalTo: mainView.rightAnchor),
        ])
        maskContentTextView.isHidden = true
        mainView.layoutIfNeeded()
        
        maskContentTextView.placeholder = L10n.Creation.Placeholder.content
        maskContentTextView.placeholderColor = Asset.textPlaceholder.color
        maskContentTextView.font = UIFont.textViewFont
        maskContentTextView.textContainerInset = UIEdgeInsets(top: 16 + topView.bounds.height,
                                                          left: 16,
                                                          bottom: 16,
                                                          right: 16)
        maskContentTextView.textContainer.lineFragmentPadding = 0
        maskContentTextView.tintColor = Asset.highlight.color
        maskContentTextView.tintColorDidChange()
        maskContentTextView.backgroundColor = .clear
        maskContentTextView.isUserInteractionEnabled = false
        maskContentTextView.layoutManager.allowsNonContiguousLayout = true
    }
    
    private func bindUI() {
        autoHideTitle()
        
        // automatically remove the selected text range of `titleTextField` when editing ended
        // if not, it will be held even though users don't focus on `titleTextField`.
        titleTextField.rx
            .controlEvent(.editingDidEnd)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                
                /// In case, presented a new view controller, you have to keep the previous state of the `selectedTextRange` to be able to scroll the `contentTextView` back to the cursor position exactly after dismissing the view controller
                if self.presentedViewController == nil {
                    self.titleTextField.selectedTextRange = nil
                }
            })
            .disposed(by: self.disposeBag)
        
        // ^above
        contentTextView.rx
            .didEndEditing
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                
                /// In case, presented a new view controller, you have to keep the previous state of the `selectedTextRange` to be able to scroll the `contentTextView` back to the cursor position exactly after dismissing the view controller
                if self.presentedViewController == nil {
                    self.contentTextView.selectedTextRange = nil
                }
            })
            .disposed(by: self.disposeBag)
        
        if #available(iOS 14, *) {
            // in iOS 14, the textView's scrolling behaviour is strange, and it automatically scrolls down even though users have no interactive.
            // related bug: https://developer.apple.com/forums/thread/662056
            // the code below is going to remain its offset prevent scrolling to the bottom
            titleTextField.rx
                .text
                .bind(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    
                    let currentOffset = self.contentTextView.contentOffset
                    self.contentTextView.setContentOffset(currentOffset, animated: false)
                })
                .disposed(by: disposeBag)
        }
    }
    
    private func tracking() {
        // Tracking Scene
        GATracking.scene(self.sceneType)
        
        // Tracking Tap events
        let tapParaphrase = thesaurusButton.rx.tap
            .map({ GATracking.Tap.tapParaphrase })
        
        let tapProofread = idiomButton.rx.tap
            .map({ GATracking.Tap.tapProofread })
        
        let tapShareDraft = shareButtonItem.rx.tap
            .map({ GATracking.Tap.tapShareDraft })
        
        let tapRedo = redoButton.rx.tap
            .map({ GATracking.Tap.tapRedo })
        
        let tapUndo = redoButton.rx.tap
            .map({ GATracking.Tap.tapUndo })
        
        let tapSave = saveButton.rx.tap
            .map({ GATracking.Tap.tapSave })
        
        let tapFontSize = fontButton.rx.tap
            .map({ GATracking.Tap.tapChangeTextSize })
        
        let tapFind = self.tfSearch.rx.controlEvent(.editingDidEndOnExit).map({GATracking.Tap.tapFind})
        
        let tapSearch = btSearch.rx.tap.map({ GATracking.Tap.tapSearchIconInHeader })
        let tapSetting = btSetting.rx.tap.map({ GATracking.Tap.tapMenuIconInHeader })
        
        Observable.merge(tapParaphrase, tapProofread, tapShareDraft, tapRedo, tapUndo, tapSave, tapFontSize, tapSearch, tapSetting, tapFind)
            .subscribe(onNext: GATracking.tap )
            .disposed(by: self.disposeBag)
    }
    
    /// auto-hide the title TextField
    private func autoHideTitle() {
        // STREAM: get content offset y when scrolling the `contentTextView`
        let currentOffsetY = contentTextView.rx
            .contentOffset
            .map({ $0.y })
        
        // STREAM: get content offset y to reload and show the separator if necessary
        let reloadViewTrigger = progressView.rx.didChangeState
            .withLatestFrom(currentOffsetY)
        
        // Process
        Observable.merge(currentOffsetY, reloadViewTrigger)
            .map({ [weak self] value -> CGFloat in
                guard let self = self else { return 0 }
                if self.progressView.state == .hide {
                    return value > self.topView.frame.height ? self.topView.frame.height : value
                } else {
                    return value > self.topView.frame.height - 1 ? self.topView.frame.height - 1 : value
                }
            })
            .distinctUntilChanged()
            .bind(onNext: { [weak self] value in
                guard let self = self else { return }
                
                self.topViewTopConstraint.constant = -value
            })
            .disposed(by: self.disposeBag)
        
        // scroll to top
        forceShowTitleTrigger
            .bind(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.contentTextView.setContentOffset(.zero, animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    func bindViewModel() {
        let titleInputTrigger = titleTextField.rx
            .controlEvent(.editingChanged)
            .asObservable()
            .map({ [unowned self] (_) -> CreationViewModel.TextInput in
                let text = self.titleTextField.text ?? ""
                var range: NSRange? = nil
                if let textRange = self.titleTextField.markedTextRange {
                    let begin = self.titleTextField.beginningOfDocument
                    let location = self.titleTextField.offset(from: begin, to: textRange.start)
                    let length = self.titleTextField.offset(from: textRange.start, to: textRange.end)
                    range = NSRange(location: location, length: length)
                }
                
                //Flow AutoSave
                if let s = self.settingFont, s.autoSave ?? false {
                    self.eventAutoSaveCloud.onNext(s.autoSave ?? false)
                }
                
                return CreationViewModel.TextInput(text: text, markedTextRange: range)
            })
            .asDriverOnErrorJustComplete()
        
        let contentInputTrigger = contentTextView.rx
            .didChange
            .asObservable()
            .map({ [unowned self] (_) -> CreationViewModel.TextInput in
                let text = self.contentTextView.text ?? ""
                var range: NSRange? = nil
                if let textRange = self.contentTextView.markedTextRange {
                    let begin = self.contentTextView.beginningOfDocument
                    let location = self.contentTextView.offset(from: begin, to: textRange.start)
                    let length = self.contentTextView.offset(from: textRange.start, to: textRange.end)
                    range = NSRange(location: location, length: length)
                }
                
                //Flow AutoSave
                if let s = self.settingFont, s.autoSave ?? false {
                    self.eventAutoSaveCloud.onNext(s.autoSave ?? false)
                }
                
                return CreationViewModel.TextInput(text: text, markedTextRange: range)
            })
            .asDriverOnErrorJustComplete()
        
        let titleEditingDidBegin = titleTextField.rx
            .controlEvent(.editingDidBegin)
            .asDriverOnErrorJustComplete()
        
        let contentEditingDidBegin = contentTextView.rx
            .didBeginEditing
            .asDriverOnErrorJustComplete()
        
        let enterEditingMode = Driver.merge(titleEditingDidBegin, contentEditingDidBegin)
            .map { [weak self] () -> Void in
                guard let wSelf = self else { return () }
                wSelf.btSetting.isSelected = false
                return ()
            }
        
        let contentSelectionDidChange = contentTextView.rx
            .didChangeSelection
            .asDriverOnErrorJustComplete()
        
        let cursorPosition = Driver
            .merge(
                contentEditingDidBegin.asObservable().take(1).asDriverOnErrorJustComplete(),
                contentSelectionDidChange)
            .map({ [unowned self] (_) -> Int in
                if let s = self.settingFont {
                    self.eventAutoSaveCloud.onNext(s.autoSave ?? false)
                }
                
                return self.contentTextView.selectedRange.upperBound
            })
            .startWith(0)
        
        let dictionaryButtonTrigger = dictionaryButton.rx
            .tap
            .asDriver()
            .map({ [weak self] _ -> String? in
                guard let self = self else { return nil }
                
                if let selectedRange = self.titleTextField.selectedRangeStringIndex,
                   let text = self.titleTextField.text {
                    return String(text[selectedRange.lowerBound..<selectedRange.upperBound])
                } else if let selectedRange = self.contentTextView.selectedRangeStringIndex,
                          let text = self.contentTextView.text {
                    return String(text[selectedRange.lowerBound..<selectedRange.upperBound])
                }
                
                return nil
            })
        
        let dictionaryTrigger = Driver.merge(dictionaryButtonTrigger,self.dictionaryMenuItemTrigger.asDriverOnErrorJustComplete()).map({$0})
        
        let selectionTrigger = Driver
            .merge(
                idiomButton.rx.tap.asDriver(),
                thesaurusButton.rx.tap.asDriver())
            .map({ [weak self] _ -> CreationViewModel.CheckInput in
                guard let self = self else { return .all }
                
                if let range = self.titleTextField.selectedRangeStringIndex {
                    return .title(range)
                } else if let range = self.contentTextView.selectedRangeStringIndex {
                    return .content(range)
                }
                
                return .all
            })
        
        let tapFontViewTrigger = fontButton.rx
            .tap
            .asDriver()
            .map({ [unowned self] _ -> Bool in
                return self.fontStyleViewTopConstraint.constant == -self.fontStyleView.frame.height
            })
        
        let selectFontStyleTrigger = fontStyleView.slider.rx
            .controlEvent(.valueChanged)
            .map({ [unowned self] _ -> Int in
                return self.fontStyleView.slider.currentStep
            })
            .asDriverOnErrorJustComplete()
            .distinctUntilChanged()
        
        let selectFrameTrigger = Driver
            .merge(
                self.isRotation.asDriverOnErrorJustComplete()
            )
            .map { [weak self] (_) -> CGRect? in
                guard let self = self else { return nil }
                
                return self.view.frame
            }
            .asDriver()
        
        let searchTrigger = self.btSearch.rx.tap.map { [weak self] _ -> TapHeader in
            guard let wSelf = self else { return  TapHeader.unSearch}
            if wSelf.tapSearch {
                wSelf.tapSearch = false
                return TapHeader.unSearch
            } else {
                wSelf.tapSearch = true
                wSelf.btSetting.isSelected = false
                return TapHeader.search
            }
        }
        let settingTrigger = self.btSetting.rx.tap
            .map { [weak self] _ -> TapHeader in
                guard let wSelf = self, let s = wSelf.settingFont else { return TapHeader.setting }
                //let isText = wSelf.contentTextView.text.count >= 1
                AppSettings.settingFont = SettingFont(size: s.size,
                                                      name: s.name,
                                                      isEnableButton: true,
                                                      autoSave: s.autoSave ?? false)
                wSelf.view.endEditing(true)
                
                if wSelf.btSetting.isSelected {
                    wSelf.btSetting.isSelected = false
                    return TapHeader.hideSettingFont
                } else {
                    wSelf.btSetting.isSelected = true
                    return TapHeader.setting
                }
            }
        let cleanTrigger = self.btClean.rx.tap.map{ TapHeader.cleanText }
        let settingSearchTrigger = self.btSettingSearch.rx.tap.map{ TapHeader.settingSearch }
        let cleaReplace = self.btCleanReplace.rx.tap.map{ TapHeader.cleanReplace }
        let editingChanged = self.tfSearch.rx.controlEvent(.editingChanged).map { TapHeader.editChanged }
        
        let tapTriggerHeader = Observable.merge(searchTrigger, settingTrigger, cleanTrigger, settingSearchTrigger, cleaReplace, editingChanged)
            .asDriverOnErrorJustComplete()
        
        let updateTextViewContent = Observable.merge(self.btSearch.rx.tap.map { TapHeader.updateContent },
                                                     self.btSetting.rx.tap.map { TapHeader.updateContent },
                                                     self.undoButton.rx.tap.map { TapHeader.updateContent },
                                                     self.redoButton.rx.tap.map { TapHeader.updateContent },
                                                     self.thesaurusButton.rx.tap.map { TapHeader.updateContent },
                                                     self.idiomButton.rx.tap.map { TapHeader.updateContent },
                                                     self.dictionaryButton.rx.tap.map { TapHeader.updateContent },
                                                     self.saveButton.rx.tap.map { TapHeader.updateContent }
                                                     )
        .map { [weak self] (tap) -> CreationViewModel.TextAttributeString? in
            //Curently, We will borrow the struct TextReplace to update Content to TextAttributeString
            guard let wSelf = self, let value = wSelf.tfSearch.text, value != "" else { return nil }
            let font = wSelf.contentTextView.font ?? UIFont.init()

            var result: NSMutableAttributedString
            
            if let att = wSelf.contentTextView.attributedText {
                result = NSMutableAttributedString(attributedString: att)
            } else {
                result = NSMutableAttributedString(string: wSelf.contentTextView.text)
            }
            
            
            return CreationViewModel.TextAttributeString(textSearch: value,
                                                         attributedString: result,
                                                         textFont: font,
                                                         contentText: wSelf.contentTextView.text,
                                                         baseOnAttrs: wSelf.contentTextView.typingAttributes,
                                                         settingFont: wSelf.settingFont)
        }
        .asDriverOnErrorJustComplete()
        
        
        
        let pressButtonSearch = Observable.merge(self.tfSearch.rx.controlEvent(.editingDidEndOnExit).asObservable(),
                                                 self.tfReplace.rx.controlEvent(.editingDidEndOnExit).asObservable())
        
        let updateListSearchWithEmpty = self.tfSearch.rx.text
            .filter { ($0?.count ?? 0) <= 0 }
            .mapToVoid()
            .asDriverOnErrorJustComplete()
            
        
        let searchInputTrigger = pressButtonSearch
            .map { [weak self]  _ -> CreationViewModel.TextAttributeString? in
                guard let wSelf = self, let text = wSelf.tfSearch.text else { return nil }
                let font = wSelf.contentTextView.font ?? UIFont.init()

                var result: NSMutableAttributedString
                
                if let att = wSelf.contentTextView.attributedText {
                    result = NSMutableAttributedString(attributedString: att)
                } else {
                    result = NSMutableAttributedString(string: wSelf.contentTextView.text)
                }
                
                wSelf.clearContentHighlight()
                
                
                return CreationViewModel.TextAttributeString(textSearch: text,
                                                             attributedString: result,
                                                             textFont: font,
                                                             contentText: wSelf.contentTextView.text,
                                                             baseOnAttrs: wSelf.contentTextView.typingAttributes,
                                                             settingFont: wSelf.settingFont)
            }.asDriverOnErrorJustComplete()
        
        let getAttributeLoadFirst = self.rx.viewDidAppear.asObservable()
            .filter{ $0 }
            .map { [weak self]  _ -> CreationViewModel.TextAttributeString? in
                guard let wSelf = self, let text = wSelf.tfSearch.text else { return nil }
                let font = wSelf.contentTextView.font ?? UIFont.init()

                var result: NSMutableAttributedString
                
                if let att = wSelf.contentTextView.attributedText {
                    result = NSMutableAttributedString(attributedString: att)
                } else {
                    result = NSMutableAttributedString(string: wSelf.contentTextView.text)
                }
                
                
                return CreationViewModel.TextAttributeString(textSearch: text,
                                                             attributedString: result,
                                                             textFont: font,
                                                             contentText: wSelf.contentTextView.text,
                                                             baseOnAttrs: wSelf.contentTextView.typingAttributes,
                                                             settingFont: wSelf.settingFont)
            }
            .asDriverOnErrorJustComplete()
        
        let nextSearchTrigger = self.btNextSearch.rx.tap.map{ TapHeader.next }
        let previousSearchTrigger = self.btPreviousSearch.rx.tap.map{ TapHeader.previous }
        let tapTriggerSearch = Observable.merge(nextSearchTrigger, previousSearchTrigger)
            .asDriverOnErrorJustComplete()

        let tapReplace = self.btReplace.rx.tap.map{ TapHeader.replace }
        let tapReplaceAll = self.btReplaceAll.rx.tap.map{ TapHeader.replaceAll }
        let replace = Observable.merge(tapReplace, tapReplaceAll)
            .map { [weak self] tap -> TextReplace? in
                guard let wSelf = self,
                      let text = wSelf.tfReplace.text,
                      let textSearch = wSelf.tfSearch.text else { return nil }
                
                let lengthDifferent = (wSelf.tfReplace.text?.count ?? 0) - (wSelf.tfSearch.text?.count ?? 0)
                
                switch tap {
                case .replace:
                    let totalLength = lengthDifferent + wSelf.contentTextView.text.count
                    if totalLength > CreationUseCase.Constant.maxContent {
                        wSelf.eventShowAlertMaxLenght.onNext(HandleReplace(textView: wSelf.contentTextView,
                                                                          range: wSelf.contentTextView.selectedRange,
                                                                          replace: wSelf.tfReplace.text ?? "",
                                                                          pasteOverLength: .replace))
                        return nil
                    }
                case .replaceAll:
                    let totalLength = (abs(lengthDifferent) * wSelf.listPosition.count ) + wSelf.contentTextView.text.count
                    if lengthDifferent > 0 && totalLength > CreationUseCase.Constant.maxContent {
                        wSelf.eventShowAlertMaxLenght.onNext(HandleReplace(textView: wSelf.contentTextView,
                                                                          range: wSelf.contentTextView.selectedRange,
                                                                          replace: wSelf.tfReplace.text ?? "",
                                                                          pasteOverLength: .replace))
                        return nil
                    }
                    wSelf.contentTextView.undoManager?.removeAllActions()
                    wSelf.updateUndoRedoState()
                default: break
                    
                }
                
                return TextReplace(text: text,
                                   tap: tap
//                                   textSearch: textSearch
                )
            }
            .asDriverOnErrorJustComplete()
        
        self.tfSearch.rx.text.orEmpty.bind { [weak self] value in
            guard let wSelf = self else { return }
            wSelf.btClean.isHidden = (value.count <= 0) ? true : false
//            wSelf.lbTotalSearch.isHidden = true
        }.disposed(by: disposeBag)
        
        self.tfReplace.rx.text.orEmpty.bind { [weak self] value in
            guard let wSelf = self else { return }
            wSelf.btCleanReplace.isHidden = (value.count <= 0) ? true : false
        }.disposed(by: disposeBag)
        
        
        self.saveButton.rx.tap.bind { [weak self] _ in
            guard let wSelf = self else { return }
            
            if let selectedRange = wSelf.contentTextView.selectedTextRange {
                wSelf.lastCursorAPI = wSelf.contentTextView.offset(from: wSelf.contentTextView.beginningOfDocument, to: selectedRange.start)
            } else {
                wSelf.lastCursorAPI = nil
            }
            
        }.disposed(by: disposeBag)
        
        let tapSaveDraft = self.saveButton.rx.tap.map { PasteOverLength.saveDraftOver }
        let dismissDraft = self.dismissButton.rx.tap.map { PasteOverLength.dismissDraft }
        var isCallAutoSave = false
        Observable.merge(tapSaveDraft, dismissDraft)
            .bind { [weak self] type in
                guard let wSelf = self else { return }
                if type == .saveDraftOver {
                    if isCallAutoSave {
                        return
                    }
                }
                switch wSelf.contentTextView.text.count {
                case let x where x <= CreationUseCase.Constant.maxContent:
                    wSelf.hanleTextLessThanLimit(typePasteOverLength: type)
                default:
                    var range: NSRange? = nil
                    if let textRange = wSelf.contentTextView.markedTextRange {
                        let begin = wSelf.contentTextView.beginningOfDocument
                        let location = wSelf.contentTextView.offset(from: begin, to: textRange.start)
                        let length = wSelf.contentTextView.offset(from: textRange.start, to: textRange.end)
                        range = NSRange(location: location, length: length)
                    }
                    
                    if let range = range, let replaceText = wSelf.contentTextView.getTextFromRange(range: range)  {
                        wSelf.handleTextOver(textView: wSelf.contentTextView, range: range, replacementText: replaceText, typePasteOverLength: type)
                    }
                }
                
                wSelf.contentTextView.unmarkText()
            }.disposed(by: disposeBag)
        
        let eventWillEnterForegroundTrigger = NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .asDriverOnErrorJustComplete()
            .mapToVoid()

        let input = CreationViewModel
            .Input(
                loadTrigger: Driver.just(()),
                viewWillAppear: self.rx.viewWillAppear.asDriver().mapToVoid(),
                viewDidAppear: self.rx.viewDidAppear.asDriver().mapToVoid(),
                viewDidLayoutSubviews: self.rx.viewDidLayoutSubviews.asDriver().mapToVoid(),
                titleInputTrigger: titleInputTrigger,
                contentInputTrigger: contentInputTrigger,
                cursorPosition: cursorPosition,
                selectionTrigger: selectionTrigger,
                updateRawTitleTrigger: updateRawTitleTrigger.asDriverOnErrorJustComplete(),
                updateRawContentTrigger: updateRawContentTrigger.asDriverOnErrorJustComplete(),
                dismissTrigger: self.eventDismissDraft.asDriverOnErrorJustComplete(),
                saveTrigger: self.eventSaveDraft.asDriverOnErrorJustComplete(),
                shareTrigger: shareButtonItem.rx.tap.asDriver(),
                idiomTrigger: idiomButton.rx.tap.asDriver(),
                thesaurusTrigger: thesaurusButton.rx.tap.asDriver(),
                dictionaryTrigger: dictionaryTrigger,
                enterEditingMode: enterEditingMode,
                tapTooltipTrigger: tapTooltip.asDriverOnErrorJustComplete(),
                tapFontViewTrigger: tapFontViewTrigger,
                tapContentViewTrigger: tapContentView.asDriverOnErrorJustComplete(),
                selectFontStyleTrigger: selectFontStyleTrigger,
                isRotation: isRotation.asDriverOnErrorJustComplete(),
                selectFrameTrigger: selectFrameTrigger,
                tapTriggerHeader: tapTriggerHeader,
                searchInputTrigger: searchInputTrigger,
                tapTriggerSearch: tapTriggerSearch,
                tapReplace: replace,
                updateTextViewContent: updateTextViewContent,
                eventTextOverMaxLenght: self.eventTextOverMaxLenght.asDriverOnErrorJustComplete(),
                eventShowAlertMaxLenght: self.eventShowAlertMaxLenght.asDriverOnErrorJustComplete(),
                eventSettingSearch: self.eventSettingSearch.asDriverOnErrorJustComplete(),
                tapViewCoverSettingSearch: self.tapViewCoverSettingSearch.rx.event.mapToVoid().asDriverOnErrorJustComplete(),
                getAttributeLoadFirst: getAttributeLoadFirst,
                updateListSearchWithEmpty: updateListSearchWithEmpty,
                eventUpdateListRangeWhenReplace: self.eventUpdateListRangeWhenReplace.asDriverOnErrorJustComplete(),
                eventShowAlertTitleMaxLenght: eventShowAlertTitleMaxLenght.asDriverOnErrorJustComplete(),
                eventAutoSaveCloud: self.eventAutoSaveCloud.asDriverOnErrorJustComplete(),
                eventWillEnterForegroundTrigger: eventWillEnterForegroundTrigger
            )
        
        let output = viewModel.transform(input)
        
        displayViewDidLayout
            .take(1)
            .asObservable()
            .bind { [weak self] (isShow) in
                guard let self = self else { return }
                if isShow {
                    self.updateUIFollowRotate(size: self.view.bounds.size, isFirst: true)
                }
        }.disposed(by: disposeBag)
        
        Observable.combineLatest(self.viewDidChangeRotate.asObservable(), self.updateSpacingButtonIPad.asObservable())
            .bind { [weak self] (item) in
                guard let self = self else {
                    return
                }
                self.getUpdateLayoutIpad(isFirst: item.1.0, size: item.1.1)
            }.disposed(by: disposeBag)
        
        updateSpacingButtonIPad
            .takeUntil(self.viewDidChangeRotate.asObservable())
            .debounce(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
            .bind { [weak self] (isFirst, size) in
                guard let self = self else {
                    return
                }
                self.getUpdateLayoutIpad(isFirst: isFirst, size: size)
        }.disposed(by: disposeBag)
        
        updateSpacingButtonIPhone
            .bind { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.displayViewButton.onNext(true)
            }.disposed(by: disposeBag)
        
        Observable.combineLatest(displayViewButton.asObservable(), self.showTooltip.asObservable())
            .bind { [weak self] ( isDisplay, show) in
                guard let configFrame = self?.getConfigFrame(), let self = self else {
                    return
                }
                if show && isDisplay {
                    self.view.show(popup: self.tooltipPopup,
                                   targetRect: configFrame.1,
                                   config: configFrame.0,
                                   controlView: self.toolBar)
                } else {
                    self.view.dismiss(popup: self.tooltipPopup)
                }
            }.disposed(by: disposeBag)
        
        Observable.combineLatest(self.updateTooltip.asObservable(), self.showTooltip.asObserver())
            .delay(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
            .bind { [weak self] (_, isShow) in
                guard  let self = self, let frame = self.getConfigFrame() else {
                    return
                }
                if isShow {
                    self.view.show(popup: self.tooltipPopup, targetRect: frame.1, config: frame.0, controlView: self.toolBar)
                    self.tooltipPopup.addTapGesture { [weak self] (gesture) in
                        self?.tapTooltip.onNext(())
                    }
                }  else {
                    self.view.dismiss(popup: self.tooltipPopup)
                }
            }.disposed(by: disposeBag)
        
        self.updateTextView
            .asObservable()
            .bind { [weak self] _ in
                self?.viewDidChangeRotate.onNext(())
                guard let self = self, let present = self.currentPresent, present.1.height > 0 else {
                    return
                }
                let toolbarHeight = self.toolBar.bounds.height
                var contentInsets = self.contentTextView.contentInset
                contentInsets.bottom = UIScreen.main.bounds.height / 2 - self.view.safeAreaInsets.bottom - toolbarHeight
                self.contentTextView.contentInset = contentInsets

                var scrollIndicatorInsets = self.contentTextView.scrollIndicatorInsets
                scrollIndicatorInsets.bottom = UIScreen.main.bounds.height / 2 - self.view.safeAreaInsets.bottom - toolbarHeight
                self.contentTextView.scrollIndicatorInsets = scrollIndicatorInsets
        }.disposed(by: disposeBag)
        
        let updateTitle = output.title
            .map({ $0.text })
            .asObservable()
        
        updateTitle
            .take(1) // set once
            .asDriverOnErrorJustComplete()
            .drive(self.titleTextField.rx.text)
            .disposed(by: self.disposeBag)
        
        updateTitle
            .skip(1)
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] text in
                guard let self = self else { return }
                if let currentText = self.titleTextField.text, currentText != text {
                    let start = self.titleTextField.beginningOfDocument
                    let end = self.titleTextField.endOfDocument
                    if let range = self.titleTextField.textRange(from: start, to: end) {
                        self.titleTextField.replace(range, withText: text)
                    }
                }
            })
            .disposed(by: self.disposeBag)
        
        let updateContentTrigger = output.content
            .map({ $0.text })
            .asObservable()
            .take(1)
            .asDriverOnErrorJustComplete()
        
        Driver.combineLatest(updateContentTrigger, output.lastCursorPosition)
            .drive(onNext: { [weak self] (text, cursorPosition) in
                guard let self = self else { return }
                
                if #available(iOS 13.0, *) {
                    self.contentTextView.text = text
                    self.maskContentTextView.text = text
                    
//                    self.setCursor(at: cursorPosition)
                    
                } else {
                    // I have to update the text with a short delay time to make the text view displayed on top. I tried to find the last event to be called to set up text view, but I hadn't found it out.
                    // view did layout subviews, text view did update the font, or text view did layout, all of them don't work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.contentTextView.text = text
                        self.maskContentTextView.text = text
                        
                        NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: self.contentTextView)
                        NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: self.maskContentTextView)
                        
                        self.setCursor(at: cursorPosition)
                    }
                }
            })
            .disposed(by: self.disposeBag)
        
        output.detectData
            .drive{ [weak self] hasData in
                guard let wSelf = self else { return }
                
                let bts = [wSelf.thesaurusButton, wSelf.idiomButton]
                bts.forEach { bt in
                    bt?.isEnabled = hasData
                    bt?.backgroundColor = (hasData) ? Asset.highlight.color : Asset.separator.color
                }
                
            }.disposed(by: self.disposeBag)
        
        Driver.merge(output.numberOfCharacter, self.eventNumberOfCharacters.asDriverOnErrorJustComplete())
            .map({ number -> String in
                let count = FormatHelper.numberFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
                
                return count + L10n.Creation.word
            })
            .drive(self.navigationItem.rx.title)
            .disposed(by: self.disposeBag)
        
        output.keyboardHeight
            .drive(onNext: { [weak self] (data) in
                guard let self = self else { return }
                let toolbarBottomConstant = data.height > 0 ? data.height - self.view.safeAreaInsets.bottom : 0
                self.toolbarBottomConstraint.constant = -toolbarBottomConstant
                self.hViewBottomSearch.constant = (data.height > 0) ? 0 : self.view.safeAreaBottom
                self.searchBottomConstraint.constant = data.height
                
                self.getMainBottom(hasHideViewSearch: self.viewSearch.isHidden)
                
                self.view.layoutIfNeeded()
            })
            .disposed(by: self.disposeBag)
        
        output.keyboardHeight
            .map({ $0.height > 0 ? Asset.icKeyboardA.image : Asset.icKeyboardB.image })
            .drive(onNext: { [weak self] (image) in
                self?.keyboardStateButton.setImage(image, for: .normal)
            })
            .disposed(by: self.disposeBag)
        
        output.share
            .drive(onNext: { [weak self] (_) in
                self?.clearTitleHighlight()
                self?.clearContentHighlight()
            })
            .disposed(by: self.disposeBag)
        
        Driver.combineLatest(output.keyboardHeight.startWith(PresentAnim.empty),
                             output.presentedViewHeight.startWith(PresentAnim.empty))
            .asObservable()
            .skip(1)
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] (data) in
                guard let self = self else { return }
                self.currentPresent = data
                // keyboard
                let textViewBottomInsetByKeyboard = data.0.height > 0 ? data.0.height - self.view.safeAreaInsets.bottom : 0
                
                // text view insets
                let toolbarHeight = self.toolBar.bounds.height
                let textViewBottomInsetByPresentedView = data.1.height > 0 ? data.1.height - self.view.safeAreaInsets.bottom - toolbarHeight: 0
                
                var maxTextViewBottomInset = max(textViewBottomInsetByKeyboard, textViewBottomInsetByPresentedView)
                
                let maxDuration = max(data.0.duration, data.1.duration)
                
                let animator = UIViewPropertyAnimator(duration: maxDuration, curve: .linear) { [weak self] in
                    guard let self = self else { return }
                    
                    var contentInsets = self.contentTextView.contentInset
                    contentInsets.bottom = maxTextViewBottomInset
                    self.contentTextView.contentInset = contentInsets
                    
                    var scrollIndicatorInsets = self.contentTextView.scrollIndicatorInsets
                    scrollIndicatorInsets.bottom = maxTextViewBottomInset
                    self.contentTextView.scrollIndicatorInsets = scrollIndicatorInsets
                    self.maxTextViewBottomInset = maxTextViewBottomInset
                    
                    if !self.viewSearch.isHidden {
                        maxTextViewBottomInset += self.vSearch.frame.height
                        self.getMainBottom(hasHideViewSearch: false)
                        self.contentTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                        self.contentTextView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                        return
                    }
                }
                
                animator.startAnimation()
            })
            .disposed(by: self.disposeBag)
        
        Driver.merge(output.showIdiom, output.showThesaurus)
            .drive(onNext: { [weak self] (_) in
                guard let self = self else { return }
                
                self.contentTextView.resignFirstResponder()
                self.titleTextField.resignFirstResponder()
            })
            .disposed(by: self.disposeBag)
        
        output.isRotation
            .drive()
            .disposed(by: self.disposeBag)
        
        output.showDictionary
            .drive()
            .disposed(by: self.disposeBag)
        
        // Progress Bar
        let showProgress = output.showProgress
            .map({ $0 ? ProgressState.loading : ProgressState.success })
        
        output.showProgress
            .drive(UIApplication.shared.rx.isNetworkActivityIndicatorVisible)
            .disposed(by: self.disposeBag)
        
        // hide progress bar when scrolling the content TextView after getting the result
        let hideProgressWhenScrolling = self.contentTextView.rx
            .willBeginDragging
            .asDriver()
            .withLatestFrom(showProgress)
            .map({ $0 == ProgressState.success ? ProgressState.hide : $0 })
        
        Driver
            .merge(
                showProgress,
                output.error.filter({ $0 }).map({ _ in ProgressState.hide }),
                output.hideProgressBar.map({ ProgressState.hide }),
                output.findTagOnTitle.map({ _ in ProgressState.hide }),
                output.findTagOnContent.map({ _ in ProgressState.hide }),
                hideProgressWhenScrolling)
            .skip(1)
            .distinctUntilChanged()
            .drive(onNext: { [weak self] (state) in
                guard let self = self else { return }
                
                if state == .loading {
                    self.contentTextView.resignFirstResponder()
                    self.titleTextField.resignFirstResponder()
                }
                
                if state == .hide {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.progressView.state = .hide
                        self.stackView.layoutIfNeeded()
                    })
                } else {
                    self.progressView.state = state
                    
                    UIView.animate(withDuration: 0.3, animations: {
                        self.stackView.layoutIfNeeded()
                    })
                }
            })
            .disposed(by: self.disposeBag)
        
        output.dismiss
            .drive()
            .disposed(by: self.disposeBag)
        
        output.dismissSuggestion
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.clearTitleHighlight()
                    self.clearContentHighlight()
                }
            })
            .disposed(by: self.disposeBag)
        
        output.statusLoading.drive().disposed(by: self.disposeBag)
        
        output.lastSaveDraft
            .drive()
            .disposed(by: self.disposeBag)
        
        output.showToast
            .withLatestFrom(output.statusLoading, resultSelector: { ($1) })
            .drive(onNext: { [weak self] statusLoading in
                guard let self = self, statusLoading == .show else { return }
                
                let center = CGPoint(x: self.toolBar.center.x, y: self.toolBar.frame.minY - 35)
                self.view.showToast(message: L10n.Creation.saveMessage, center: center, controlView: self.toolBar)
            })
            .disposed(by: self.disposeBag)
        
        output.showTooltip
            .drive(onNext: { [weak self] (show) in
                self?.showTooltip.onNext(show)
            })
            .disposed(by: self.disposeBag)
        
        output.autoHideTooltips
            .drive()
            .disposed(by: self.disposeBag)
        
        output.cancelRequestAPI
            .drive()
            .disposed(by: self.disposeBag)
        
        output.eventShowAlertTitleMaxLenght
            .drive { [weak self] textRange in
                guard let wSelf = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    wSelf.titleTextField.selectedTextRange = textRange
                    wSelf.titleTextField.becomeFirstResponder()
                }
            }.disposed(by: disposeBag)
        
        output.findTagOnTitle
            .drive(onNext: { [weak self] (data) in
                self?.updateTitle(text: data.text,
                                  index: data.offset,
                                  source: data.source,
                                  replacement: data.replacement)
                self?.clearContentHighlight()
            })
            .disposed(by: self.disposeBag)
        
        output.findTagOnContent
            .drive(onNext: { [weak self] (data) in
                self?.updateContent(text: data.text,
                                    index: data.offset,
                                    source: data.source,
                                    replacement: data.replacement,
                                    canRepalce: data.canRepalce)
                self?.clearTitleHighlight()
            })
            .disposed(by: self.disposeBag)
        
        output.loadFontData
            .drive(onNext: { [weak self] (data: (current: Int, total: Int)) in
                guard let self = self else { return }
                
                self.fontStyleView.set(currentLevel: data.current, total: data.total)
            })
            .disposed(by: self.disposeBag)
        
        output.showOrHideFontStyleView
            .distinctUntilChanged()
            .map({ [weak self] isShow -> CGFloat in
                guard let self = self else { return 0 }
                
                return isShow ? 0 : -self.fontStyleView.frame.height
            })
            .drive(onNext: { [weak self] (value) in
                guard let self = self else { return }
                
                self.fontStyleViewTopConstraint.constant = value
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
            })
            .disposed(by: self.disposeBag)
        
        output.changedFontStyle
            .drive(onNext: { [weak self] (fontStyleData) in
                guard let self = self else { return }
                
                self.titleTextField.font = fontStyleData.getTitleFont()
                self.titleTextField.typingAttributes = fontStyleData.getTitleAtts(baseOn: self.titleTextField.typingAttributes)
                
                self.contentTextView.font = fontStyleData.getContentFont()
                self.maskContentTextView.font = fontStyleData.getContentFont()
                // update placeholder line height
                // use `contentFontSize` to make placeholder Label to fix with its font size
                self.contentTextView.estimatedLineHeight = fontStyleData.contentFontSize// .contentLineHeight
                self.maskContentTextView.estimatedLineHeight = fontStyleData.contentFontSize
                //Realte to paragraphStyle
                //Old flow when change Size will apply new paragraphStyle
                //Currently, only use one paragraphStyle
                let attrs = fontStyleData.getContentAtts(baseOn: self.contentTextView.typingAttributes)
                self.contentTextView.typingAttributes = attrs
                self.contentTextView.textStorage.addAttributes(attrs, range: NSMakeRange(0, self.contentTextView.text.utf16.count))
                self.contentTextView.textAlignment = .justified
            })
            .disposed(by: self.disposeBag)
        
        output.serverErrorHandler
            .drive()
            .disposed(by: self.disposeBag)
        
        output.loadingFullScreen
            .withLatestFrom(output.statusLoading, resultSelector: { (show: $0, statusLoading: $1) })
            .drive(onNext: { (show, statusLoading) in
                guard statusLoading == .show else {
                    GooLoadingViewController.shared.hide()
                    return
                }
                if show {
                    GooLoadingViewController.shared.show()
                } else {
                    GooLoadingViewController.shared.hide()
                }
            })
            .disposed(by: self.disposeBag)
        
        output.deleteCloudDraft
            .drive()
            .disposed(by: self.disposeBag)
        
        output.showBanner
            .drive(onNext: { [weak self] type in
                guard let self = self else { return }
                
                let banner = BannerView(frame: .zero, type: type)
                self.stackView.insertArrangedSubview(banner, at: 1)
            })
            .disposed(by: self.disposeBag)
        
        let updateListPosition: PublishSubject<[NSRange]> = PublishSubject.init()
        
        output.tapTriggerHeader
            .drive { [weak self] tapHeader in
                guard let wSelf = self else { return }
                switch tapHeader {
                case .setting:
                    wSelf.viewSearch.isHidden = true
                    wSelf.toolBar.isHidden = false
                    wSelf.tapSearch = false
                    
                case .hideSettingFont:
                    wSelf.btSetting.isSelected = false
                    wSelf.getMainBottom(hasHideViewSearch: wSelf.viewSearch.isHidden)
                case .search:
                    wSelf.viewSearch.isHidden = false
                    wSelf.toolBar.isHidden = true
                    wSelf.tapSearch = true
                    wSelf.lbTotalSearch.isHidden = false
                
                    wSelf.getMainBottom(hasHideViewSearch: false)
                    
                    if #available(iOS 13.0, *) {
                        wSelf.tfSearch.becomeFirstResponder()
                    } else {
                        //I tried to find the last event to be called to set up text view, but I hadn't found it out.
                        // view did layout subviews, text view did update the font, or text view did layout, all of them don't work
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            wSelf.tfSearch.becomeFirstResponder()
                        }
                    }
                    
                    let userStatus: GATracking.UserStatus = AppManager.shared.userInfo.value == nil
                        ? .other
                        : AppManager.shared.billingInfo.value.billingStatus == .paid
                        ? .premium
                        : .regular
                    GATracking.scene(.sentenceSearch, params: [.userStatus(userStatus)])
                    
                case .cleanText:
                    wSelf.tfSearch.text = ""
                    wSelf.btClean.isHidden = true
                    wSelf.lbTotalSearch.isHidden = true
                    wSelf.updateParagraphStyle()
                    
                case .editChanged:
                    wSelf.lbTotalSearch.isHidden = true
                    wSelf.updateParagraphStyle()
                case .unSearch:
                    wSelf.tfSearch.text = nil
                    wSelf.tfSearch.resignFirstResponder()
                    wSelf.tfReplace.text = nil
                    wSelf.tfReplace.resignFirstResponder()
                    wSelf.btClean.isHidden = true
                    wSelf.btCleanReplace.isHidden = true
                    wSelf.lbTotalSearch.isHidden = true
                    wSelf.viewSearch.isHidden = true
                    wSelf.toolBar.isHidden = false
                    wSelf.tapSearch = false
                    
                    wSelf.getMainBottom(hasHideViewSearch: true)
                    
                    updateListPosition.onNext([])
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        wSelf.clearContentHighlight()
                    }
        
                case .cleanReplace:
                    wSelf.tfReplace.text = ""
                    wSelf.btCleanReplace.isHidden = true
                    
                default: break
                }
                
            }.disposed(by: self.disposeBag)
        
        output.textSearchTrigger
            .drive { [weak self] (attriText) in
                guard let wSelf = self else { return }
                wSelf.lbTotalSearch.isHidden = false
            
            }.disposed(by: self.disposeBag)
        
        let getListPostion = Driver.merge(output.listPositionSearch, updateListPosition.asDriverOnErrorJustComplete())
        var previousIndex: Int?
        Driver.combineLatest(getListPostion, output.currentIndex.debounce(.milliseconds(200)))
            .drive { [weak self] (list, range) in
                guard let wSelf = self else { return }
                wSelf.listPosition = list
//                wSelf.lbTotalSearch.isHidden = false
                
                if let e = wSelf.tfSearch.text?.isEmpty, e {
                    wSelf.lbTotalSearch.isHidden = true
                }
                
                let bts = [wSelf.btNextSearch, wSelf.btPreviousSearch, wSelf.btReplace, wSelf.btReplaceAll]
                
                bts.forEach { (bt) in
                    bt?.isEnabled = (list.count > 0) ? true : false
                    bt?.setTitleColor((list.count > 0) ? Asset._111111Ffffff.color : Asset.cecece464646.color, for: .normal)

                    if bt == wSelf.btNextSearch {
                        let image = (list.count > 0) ? Asset.icNextSearchOn.image : Asset.icNextSearchOff.image
                        bt?.setImage(image, for: .normal)
                    }
                    
                    if bt == wSelf.btPreviousSearch {
                        let image = (list.count > 0) ? Asset.icPreviousSearchOn.image : Asset.icPreviousSearchOff.image
                        bt?.setImage(image, for: .normal)
                    }
                }
                
                if let rangePosition = range.currentIndex, let index = list.firstIndex(of: rangePosition)  {
                    wSelf.lbTotalSearch.text = "\(index + 1)/\(list.count)"
                    previousIndex = index
                    if index == 0 {
                        let image = Asset.icPreviousSearchOff.image
                        wSelf.btPreviousSearch.setImage(image, for: .normal)
                        wSelf.btPreviousSearch.isEnabled = false
                    }
                    
                    if index == list.count - 1 && range.isScroll  {
                        let image = Asset.icNextSearchOff.image
                        wSelf.btNextSearch.setImage(image, for: .normal)
                        wSelf.btNextSearch.isEnabled = false
                    }
                    
                    if range.isScroll {
                        wSelf.view.layoutIfNeeded()
                        wSelf.scrollToPosition(at: rangePosition, showRange: false)
                    }
                    
                    
                } else {
                    wSelf.lbTotalSearch.text = "\(list.count)"
                    
                    if previousIndex == 0 {
                        let image = Asset.icPreviousSearchOff.image
                        wSelf.btPreviousSearch.setImage(image, for: .normal)
                        wSelf.btPreviousSearch.isEnabled = false
                    }
                }
                
                let size = wSelf.lbTotalSearch.sizeThatFits(wSelf.lbTotalSearch.bounds.size)
                wSelf.wLabelTotalSearch.constant = size.width
                
                
            }.disposed(by: disposeBag)
        
        Driver.combineLatest(getListPostion, output.currentIndex)
            .drive { [weak self] (list, range) in
                guard let wSelf = self else { return }
                if list.count == 0 { return }
                
                let isEquaList = list.elementsEqual(wSelf.cacheListRange, by: { $0 == $1} )
                if isEquaList {
                    // Only update at current index, last Index
                    if let rangePosition = range.currentIndex, let _ = list.firstIndex(of: rangePosition) {
                        let attributeString = NSMutableAttributedString(attributedString: wSelf.maskContentTextView.attributedText)
                        attributeString.addAttributes([.backgroundColor: Asset.textReplace.color], range: rangePosition)
                        if let lastRange = wSelf.lastCurrentIndex, lastRange != rangePosition {
                            attributeString.addAttributes([.backgroundColor: Asset.textSearch.color], range: lastRange)
                        }
                        wSelf.lastCurrentIndex = rangePosition
                        wSelf.maskContentTextView.attributedText = attributeString
                    } else {
                        if let lastRange = wSelf.lastCurrentIndex {
                            let attributeString = NSMutableAttributedString(attributedString: wSelf.maskContentTextView.attributedText)
                            attributeString.addAttributes([.backgroundColor: Asset.textSearch.color], range: lastRange)
                            wSelf.maskContentTextView.attributedText = attributeString
                        }
                    }
                    return
                }
                wSelf.cacheListRange = list
                
                wSelf.shouldBindContentOffset = false
                if wSelf.viewSearch.isHidden == false {
                    wSelf.maskContentTextView.isHidden = false
                    wSelf.contentTextView.textColor = .clear
                    wSelf.maskContentTextView.textColor = Asset.textPrimary.color
                }

                if let rangePosition = range.currentIndex, let index = list.firstIndex(of: rangePosition)  {
                    let color = Asset.textSearch.color
                    
                    let attributeString = NSMutableAttributedString(attributedString: wSelf.contentTextView.attributedText)
                    attributeString.addAttributes([.foregroundColor: Asset.textPrimary.color], range: NSRange(location: 0, length: attributeString.length))
                    
                    list.enumerated().forEach { (item) in
                        if item.offset == index {
                            wSelf.lastCurrentIndex = rangePosition
                            attributeString.addAttributes([.backgroundColor: Asset.textReplace.color], range: item.element)
                        } else {
                            attributeString.addAttributes([.backgroundColor: color], range: item.element)
                        }
                    }
                    wSelf.maskContentTextView.attributedText = attributeString
                    wSelf.maskContentTextView.font = wSelf.contentTextView.font
                    wSelf.maskContentTextView.estimatedLineHeight = wSelf.contentTextView.estimatedLineHeight
                    wSelf.maskContentTextView.layoutSubviews()
                } else {
                    let color = Asset.textSearch.color
                    let attributeString = NSMutableAttributedString(attributedString: wSelf.contentTextView.attributedText)
                    attributeString.addAttributes([.foregroundColor: Asset.textPrimary.color], range: NSRange(location: 0, length: attributeString.length))
                    
                    list.enumerated().forEach { (item) in
                        attributeString.addAttributes([.backgroundColor: color], range: item.element)
                    }
                    
                    wSelf.maskContentTextView.attributedText = attributeString
                    wSelf.maskContentTextView.font = wSelf.contentTextView.font
                    wSelf.maskContentTextView.estimatedLineHeight = wSelf.contentTextView.estimatedLineHeight
                    wSelf.maskContentTextView.layoutSubviews()
                }
                
            }.disposed(by: disposeBag)
        
        output.currentIndex
            .debounce(.milliseconds(200))
            .asObservable()
            .flatMap{ _ in output.doEventLastIndex }
            .bind { [weak self] isLastIndex in
                guard let wSelf = self else { return }
                if isLastIndex {
                    let image = Asset.icNextSearchOff.image
                    wSelf.btNextSearch.setImage(image, for: .normal)
                    wSelf.btNextSearch.isEnabled = false
                }
            }.disposed(by: disposeBag)

        output.tapTriggerSearch
            .drive().disposed(by: self.disposeBag)
        
        output.autoSaveCloud.drive().disposed(by: disposeBag)
        
        output.settingFont.drive { [weak self] s in
            guard let wSelf = self else { return }
            wSelf.settingFont = s
            let attrs = s.getContentAttsSearch(baseOn: wSelf.contentTextView.typingAttributes, statusHighlight: .noColor)
            let attrsForMaskTextView = s.getMaskContentAttsSearch(baseOn: wSelf.contentTextView.typingAttributes, statusHighlight: .noColor)
            wSelf.contentTextView.typingAttributes = attrs
            wSelf.maskContentTextView.typingAttributes = attrsForMaskTextView
            wSelf.contentTextView.textStorage.addAttributes(attrs, range: NSMakeRange(0, wSelf.contentTextView.text.utf16.count))
            wSelf.contentTextView.textAlignment = .justified
            wSelf.contentTextView.font = s.getFont()
            
            wSelf.maskContentTextView.textAlignment = .justified
            wSelf.maskContentTextView.font = s.getFont()
            wSelf.titleTextField.font = s.getFont()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                wSelf.updateParagraphStyle()
            }
            wSelf.eventAutoSaveCloud.onNext(s.autoSave ?? false)
        }.disposed(by: self.disposeBag)
        
        output.shareSettingFont
            .drive(onNext: { [weak self] (_) in
                self?.clearTitleHighlight()
                self?.clearContentHighlight()
            })
            .disposed(by: self.disposeBag)
        
        var eventShowViewSearch: TapHeader = .unSearch
        
        let eventUpdateShowViewSearch = Observable.merge(self.thesaurusButton.rx.tap.map{ TapHeader.unSearch },
                                                         self.idiomButton.rx.tap.map{ TapHeader.unSearch }
                                                         )
        .asDriverOnErrorJustComplete()
        
        Driver.merge(output.tapTriggerHeader.startWith(.unSearch).filter{ $0 != .editChanged },
                     eventUpdateShowViewSearch
                   )
            .drive { tap in
            
            eventShowViewSearch = tap
        } .disposed(by: disposeBag)
        
        Driver.combineLatest(output.isShowSettingView, output.eventHeightSettingFont)
            .drive { [weak self] (isShow, height) in
            guard let wSelf = self else { return }
            if isShow {
                wSelf.contentTextView.resignFirstResponder()
                wSelf.titleTextField.resignFirstResponder()
                wSelf.viewSearch.isHidden = true
                wSelf.maskContentTextView.isHidden = true
                wSelf.contentTextView.textColor = Asset.textPrimary.color
                wSelf.tapSearch = false
                //Waiting for All event is end, then call this method
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    wSelf.resetAttributedString(updateListPosition: updateListPosition, eventShowViewSearch: eventShowViewSearch)

                    var h: CGFloat
                    if wSelf.viewSearch.isHidden {
                        h = height - Constant.distanceBottomToMainView - wSelf.view.safeAreaBottom
                    } else {
                        h = height - wSelf.viewSearch.frame.height - wSelf.view.safeAreaBottom
                    }

                    var contentInsets = wSelf.contentTextView.contentInset
                    contentInsets.bottom = h
                    wSelf.contentTextView.contentInset = contentInsets

                    var scrollIndicatorInsets = wSelf.contentTextView.scrollIndicatorInsets
                    scrollIndicatorInsets.bottom = h
                    wSelf.contentTextView.scrollIndicatorInsets = scrollIndicatorInsets

                }
            }
                wSelf.btSetting.isSelected = isShow
        }.disposed(by: self.disposeBag)

        output.dismissSettingView.drive().disposed(by: self.disposeBag)
        
        output.settingSearch.drive { [weak self] s in
            guard let wSelf = self else { return }
            wSelf.vReplace.isHidden = !s.isReplace
        }.disposed(by: self.disposeBag)
        
        output.isShowSettingSearch.drive { [weak self] isShow in
            guard let wSelf = self else { return }
            if isShow {
                wSelf.view.endEditing(true)
            }
            wSelf.viewCoverSettingSearch.isHidden = !isShow
            wSelf.btSettingSearch.isEnabled = !isShow
        }.disposed(by: self.disposeBag)
        
        output.dismissSettingSearchView.drive().disposed(by: self.disposeBag)
        
        output.actionUndoReplace
            .drive { [weak self] range in
                guard let wSelf = self else { return }
            wSelf.updateRawContentTrigger.onNext(wSelf.contentTextView.text)
        }.disposed(by: self.disposeBag)
        
        //Fix case
        //Sometimes, after replce to the end, user press undo so app only undo one time
        output.textReplace
            .drive { [weak self] (item) in
                guard let wSelf = self, let item = item, let replaceText = wSelf.tfReplace.text else { return }
                
                switch item.tap {
                case .replace:
                    switch  item.statusReplace {
                    case .replace:
                        var updateRange: NSRange?
                        item.listRange.forEach { r in
                            wSelf.replaceTextHighLight(textRange: r, replacement: replaceText)
                            updateRange = NSRange(location: r.location, length: replaceText.count)
                        }
                        
                        if let u = updateRange {
                            wSelf.eventUpdateListRangeWhenReplace.onNext(TextReplaceUpdate(text: replaceText, range: u))
                        }
                        
                    case .highlight:
                        let attributeString = NSMutableAttributedString(attributedString: wSelf.maskContentTextView.attributedText)
                        
                        item.listRange.forEach { r in
                            attributeString.addAttributes([.backgroundColor: Asset.textReplace.color], range: r)
                        }
                        wSelf.maskContentTextView.attributedText = attributeString
                    }
                default: break
                }
                
                wSelf.updateRawContentTrigger.onNext(wSelf.contentTextView.text)
            }.disposed(by: self.disposeBag)
        
        output.updateTextViewReplaceAll.drive { [weak self] att in
            guard let wSelf = self else { return }
            wSelf.updateAttribute(textAttribute: att)
            wSelf.contentTextView.layoutIfNeeded()
            wSelf.maskContentTextView.isHidden = true
            wSelf.updateRawContentTrigger.onNext(wSelf.contentTextView.text)
            wSelf.clearContentHighlight()
        }.disposed(by: disposeBag)
        
        output.eventUpdateListRangeWhenReplace.drive().disposed(by: disposeBag)
        
        
        tapViewCoverSettingSearch.rx.event.bind { tap in
            eventShowViewSearch = .search
        }.disposed(by: disposeBag)
        
        //skip 1 to skip the first, if Not, contentView will scroll
        output.resetAttributedString
            .skip(1)
            .drive{ [weak self] att in
                guard let wSelf = self else { return }
                //If attributedText is wrrong, can check here.
                //warning about attributedText
                //Have to call DispatchQueue.main.async, to Cursor Position don't move incorrectly
                //If Call on sync, method clearContentHighlight work incorrectly
                DispatchQueue.main.async {
                    wSelf.resetAttributedString(updateListPosition: updateListPosition,
                                                keepStatusViewSearch: att.1,
                                                eventShowViewSearch: eventShowViewSearch)
                    if eventShowViewSearch != .search {
                        wSelf.getMainBottom(hasHideViewSearch: wSelf.viewSearch.isHidden)
                    }
                
                }
            }.disposed(by: self.disposeBag)
        
        self.contentTextView.rx
            .didBeginEditing
            .asObservable()
            .delay(.milliseconds(300), scheduler: ConcurrentMainScheduler.instance)
            .bind { _ in
                eventShowViewSearch = .unSearch
            }.disposed(by: disposeBag)

        output.updateTextViewContent.drive().disposed(by: disposeBag)
        output.errorHandler.drive().disposed(by: disposeBag)
        output.eventTextOverMaxLenght
            .debounce(.microseconds(200))
            .drive { [weak self] handleReplace in
                guard let wSelf = self else { return }
                if let validText = wSelf.viewModel.replaceText(content: handleReplace.textView.text ?? "",
                                                               shouldChangeTextIn: handleReplace.range,
                                                               replacementText: handleReplace.replace) {
                    if handleReplace.textView.text != validText,
                       let _ = handleReplace.textView.textRange(from: handleReplace.textView.beginningOfDocument,
                                                                to: handleReplace.textView.endOfDocument) {
                        let start = handleReplace.range.location
                        if let fromTextPosition = handleReplace.textView.position(from: handleReplace.textView.beginningOfDocument, offset: start),
                           let toTextPosition = handleReplace.textView.position(from: fromTextPosition, offset: handleReplace.range.length),
                           let textRange = handleReplace.textView.textRange(from: fromTextPosition, to: toTextPosition) {
                            handleReplace.textView.replace(textRange, withText: validText)
                            wSelf.replaceMaskTextView(textRange: textRange, text: validText)
                            wSelf.updateRawContentTrigger.onNext(handleReplace.textView.text)
                            wSelf.eventNumberOfCharacters.onNext(handleReplace.textView.text.count)
                            wSelf.contentTextView.font = wSelf.settingFont?.getFont()
                            wSelf.updateParagraphStyle()
                            
                            //Fix textView auto scroll when combine with alert
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                wSelf.contentTextView.resignFirstResponder()
                                wSelf.eventShowAlertMaxLenght.onNext(handleReplace)
                            }
                        }
                    }
                }
            }.disposed(by: disposeBag)
        
        output.eventShowAlertMaxLenght
            .drive { [weak self] handleReplace in
                guard let wSelf = self, handleReplace.pasteOverLength != .replace else { return }
                wSelf.contentTextView.scrollRangeToVisible(NSRange(location: handleReplace.range.location + handleReplace.replace.count, length: 0))
                wSelf.contentTextView.selectedRange = NSRange(location: handleReplace.range.location + handleReplace.replace.count, length: 0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    wSelf.contentTextView.becomeFirstResponder()
                    switch handleReplace.pasteOverLength {
                    case .saveDraftOver: wSelf.eventSaveDraft.onNext(())
                    case .dismissDraft: wSelf.eventDismissDraft.onNext(())
                    default: break
                    }
                }
            }.disposed(by: disposeBag)
        
        output.getAttributeLoadFirst.drive().disposed(by: disposeBag)
        
        output.updateListSearchWithEmpty.drive().disposed(by: disposeBag)
        
        Driver.combineLatest(updateContentTrigger, output.lastCursorPosition)
            .delay(.milliseconds(200))
            .drive(onNext: { [weak self] (text, cursorPosition) in
                guard let self = self else { return }
                
                if #available(iOS 13.0, *) {
                    
                    self.contentTextView.text = text
                    self.maskContentTextView.text = text
                    
                    self.setCursor(at: cursorPosition)
                    
                } else {
                    // I have to update the text with a short delay time to make the text view displayed on top. I tried to find the last event to be called to set up text view, but I hadn't found it out.
                    // view did layout subviews, text view did update the font, or text view did layout, all of them don't work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.contentTextView.text = text
                        self.maskContentTextView.text = text
                        NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: self.contentTextView)
                        NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: self.maskContentTextView)
                        
                        self.setCursor(at: cursorPosition)
                    }
                }
            })
            .disposed(by: self.disposeBag)
        
        output.otherCodeTrigger.drive(onNext: { [weak self] _ in
            guard let wSelf = self, let s = wSelf.settingFont else { return }
            wSelf.eventAutoSaveCloud.onNext(s.autoSave ?? false)
        }).disposed(by: disposeBag)
        
        self.rx.viewDidAppear.asObservable()
            .withLatestFrom(output.lastCursorPosition, resultSelector: { $1 })
            .bind { [weak self] lastCursorPosition in
            guard let wSelf = self else { return }
            let r = NSRange(location: lastCursorPosition, length: 0)
            wSelf.contentTextView.scrollRangeToVisible(r, consideringInsets: true)
        }.disposed(by: disposeBag)
        
        output.doEventResetScrollTapReplace.drive().disposed(by: disposeBag)
        
        output.disableAutoSave.drive().disposed(by: disposeBag)
        
        output.positionCursorAutoSave.drive().disposed(by: disposeBag)
        
        output.showPremium.drive().disposed(by: self.disposeBag)
        
        output.enableAutoSaveCloud.drive().disposed(by: self.disposeBag)
            
        output.errorReloadDraft.drive().disposed(by: self.disposeBag)
                        
        output.reloadContent
            .delay(.milliseconds(200))
            .drive(onNext: { [weak self] (document) in
                guard let self = self, let text = document?.content else { return }
                if #available(iOS 13.0, *) {
                    self.contentTextView.text = text
                    self.maskContentTextView.text = text
                    
                } else {
                    // I have to update the text with a short delay time to make the text view displayed on top. I tried to find the last event to be called to set up text view, but I hadn't found it out.
                    // view did layout subviews, text view did update the font, or text view did layout, all of them don't work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.contentTextView.text = text
                        self.maskContentTextView.text = text
                        NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: self.contentTextView)
                        NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: self.maskContentTextView)
                    }
                }
            })
            .disposed(by: self.disposeBag)
        
        output.reloadContent
            .delay(.milliseconds(200))
            .drive(onNext: { [weak self] (document) in
                guard let self = self, let text = document?.content, let cursorPosition = document?.cursorPosition else { return }
                if #available(iOS 13.0, *) {
                    self.contentTextView.text = text
                    self.maskContentTextView.text = text
                    self.scrollWithApi(text: text, cursorPosition: cursorPosition)
                    
                } else {
                    // I have to update the text with a short delay time to make the text view displayed on top. I tried to find the last event to be called to set up text view, but I hadn't found it out.
                    // view did layout subviews, text view did update the font, or text view did layout, all of them don't work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.contentTextView.text = text
                        self.maskContentTextView.text = text
                        NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: self.contentTextView)
                        NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: self.maskContentTextView)
                        self.scrollWithApi(text: text, cursorPosition: cursorPosition)
                    }
                }
            })
            .disposed(by: self.disposeBag)
        
        output.resetCursor.drive { [weak self] _ in
            guard let wSelf = self else { return }
            wSelf.contentTextView.resignFirstResponder()
            wSelf.maskContentTextView.resignFirstResponder()
        }.disposed(by: self.disposeBag)
        
        output.doBackUp.drive().disposed(by: self.disposeBag)
        
        output.isCallAutoSave.drive { [weak self] isAutoSave in
            guard let _ = self else { return }
            isCallAutoSave = isAutoSave
        }.disposed(by: self.disposeBag)
    }
    
    private func scrollWithApi(text: String, cursorPosition: Int) {
        if let currentCursor = self.lastCursorAPI, abs(currentCursor - cursorPosition) >= Constant.distanceBetweenRange {
            self.contentTextView.becomeFirstResponder()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.view.layoutIfNeeded()
            if cursorPosition <= Constant.distanceBetweenRange {
                self.setCursor(at: cursorPosition)
            } else if let currentCursor = self.lastCursorAPI, abs(currentCursor - cursorPosition) >= Constant.distanceBetweenRange || self.lastCursorAPI == nil {
                self.scrollToPosition(at: NSRange(location: cursorPosition, length: 0), showRange: true)
            } else {
                self.setCursor(at: cursorPosition)
            }
        }
    }
    
    private func hanleTextLessThanLimit(typePasteOverLength: PasteOverLength) {
        switch typePasteOverLength {
        case .saveDraftOver: self.eventSaveDraft.onNext(())
        case .dismissDraft: self.eventDismissDraft.onNext(())
        default: break
        }
    }
    
    private func handleTextOver(textView: UITextView, range: NSRange, replacementText: String, typePasteOverLength: PasteOverLength) {
        if viewModel.validateContent(content: textView.text ?? "", shouldChangeTextIn: range, replacementText: replacementText) != nil {
            let textReplace = viewModel.getTextReplace(currentText: textView.text ?? "",
                                                       maxLen: CreationUseCase.Constant.maxContent,
                                                       shouldChangeTextIn: range,
                                                       replacementText: replacementText) ?? ""

            if textReplace.count > 0 {
                self.eventTextOverMaxLenght.onNext((HandleReplace(textView: textView,
                                                                  range: range,
                                                                  replace: textReplace,
                                                                  pasteOverLength: typePasteOverLength)))
            }
        }
    }
    
    private func updateAttribute(textAttribute: NSMutableAttributedString) {
        self.contentTextView.text = textAttribute.string
        self.maskContentTextView.text = textAttribute.string
        
        if let s = self.settingFont {
            self.contentTextView.typingAttributes = s.getContentAttsSearch(baseOn: self.contentTextView.typingAttributes,
                                                                           statusHighlight: .noColor)
        }
        
        self.contentTextView.attributedText = textAttribute
        self.maskContentTextView.attributedText = textAttribute
        self.contentTextView.textAlignment = .justified
        self.maskContentTextView.textAlignment = .justified
    }
    
    private func updateParagraphStyle() {
        self.clearContentHighlight()
    }
    
    private func resetAttributedString(updateListPosition: PublishSubject<[NSRange]>,
                                       keepStatusViewSearch: Bool = false,
                                       eventShowViewSearch: TapHeader = .unSearch) {
        self.clearContentHighlight()
        self.tfSearch.text = nil
        self.btClean.isHidden = true
        self.lbTotalSearch.isHidden = true
        self.toolBar.isHidden = false
        
        if !keepStatusViewSearch {
            self.tapSearch = false
            self.viewSearch.isHidden = true
            self.maskContentTextView.isHidden = true
            self.contentTextView.textColor = Asset.textPrimary.color
            self.tfReplace.text = nil
            self.btCleanReplace.isHidden = true
        }
        
        //reset listPostion
        updateListPosition.onNext([])
        
        switch eventShowViewSearch {
        case .search:
            let distanceViewSrach = (self.toolbarBottomConstraint.constant >= 0 ) ? (Constant.distanceBottomToMainView + self.view.safeAreaBottom) :  Constant.distanceBottomToMainView
            let h = (self.viewSearch.isHidden) ? distanceViewSrach : self.viewSearch.frame.height
            let heightWithOurSafeArea = -h + self.toolbarBottomConstraint.constant
            let heightSafeArea = -h + self.hViewBottomSearch.constant + self.toolbarBottomConstraint.constant
            self.mainBottomConstraint.constant = (self.hViewBottomSearch.constant == self.view.safeAreaBottom) ? heightSafeArea : heightWithOurSafeArea
            
        default: break
        }

    }
    
    private func getMainBottom(hasHideViewSearch: Bool) {
        if hasHideViewSearch {
            self.mainBottomConstraint.constant = -Constant.distanceBottomToMainView
            
            if let maxTextViewBottomInset = self.maxTextViewBottomInset {
                var contentInsets = self.contentTextView.contentInset
                contentInsets.bottom = maxTextViewBottomInset
                self.contentTextView.contentInset = contentInsets

                var scrollIndicatorInsets = self.contentTextView.scrollIndicatorInsets
                scrollIndicatorInsets.bottom = maxTextViewBottomInset
                self.contentTextView.scrollIndicatorInsets = scrollIndicatorInsets
                self.maskContentTextView.scrollIndicatorInsets = scrollIndicatorInsets
                self.maxTextViewBottomInset = maxTextViewBottomInset
            }
            if self.contentTextView.textColor == .clear {
                self.contentTextView.textColor = Asset.textPrimary.color
            }
            self.maskContentTextView.isHidden = true
            
        } else {
            let heightWithOurSafeArea = -self.viewSearch.frame.height + self.toolbarBottomConstraint.constant
            let heightSafeArea = -self.viewSearch.frame.height + self.hViewBottomSearch.constant + self.toolbarBottomConstraint.constant
            self.mainBottomConstraint.constant = (self.hViewBottomSearch.constant == self.view.safeAreaBottom) ? heightSafeArea : heightWithOurSafeArea
        }
    }
    
    private func getConfigFrame() -> (UIView.AnimConfig, CGRect, CGRect)? {
        guard let tabBarItem = self.idiomButton.superview else { return nil }
        guard let superView = tabBarItem.superview else { return nil }
        var config = UIView.AnimConfig()
        // based on the tooltip image, we've to move it to the left 5 pixels for alignment to the center of the button
        config.popupAnchorPoint = UIView.AnchorPoint.anchor(
            CGPoint(x: self.tooltipPopup.frame.width * 0.5 + 5, y: self.tooltipPopup.frame.height + 10))
        config.targetAnchorPoint = UIView.AnchorPoint.centerTop
        
        // convert rect to window view
        var targetRect = superView.convert(tabBarItem.frame, to: nil)
        // convert rect from window view to view
        targetRect = self.view.convert(targetRect, from: nil)
        
        let point = config.targetAnchorPoint.position(form: targetRect)
        let finalFrame = config.popupAnchorPoint.rect(from: point, size: self.tooltipPopup.bounds.size)
        return (config, targetRect, finalFrame)
    }
    
    private func updateUIToolBar(size: CGSize, isFirst: Bool) {
        self.tooltipPopup.removeConstraints(self.tooltipPopup.constraints)
        self.tooltipPopup.removeFromSuperview()
        self.updateUIFollowRotate(size: size, isFirst: isFirst)
    }
    
    private func updateUIFollowRotate(size: CGSize, isFirst: Bool) {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            self.updateLayoutIPad(size: size, isFirst: isFirst)
        default:
            let isLandscape = (size.height < size.width) ? true : false
            let ratio = self.view.bounds.width / Constant.widthOfiPhoneSE1
            let ratioIPhone: CGFloat = 0.17
            self.idiomButton.bounds.size = CGSize(width: (isLandscape ? (size.width * ratioIPhone) : (self.wIdiomButton * ratio)),
                                                  height: idiomButton.bounds.height)
            self.thesaurusButton.bounds.size = CGSize(width: (isLandscape ? (size.width * ratioIPhone) : (self.wThesaurusButton * ratio)),
                                                      height: thesaurusButton.bounds.height)
            self.dictionaryButton.bounds.size = CGSize(width: (isLandscape ? (size.width * ratioIPhone) : (self.wDictionaryButton * ratio)),
                                                       height: dictionaryButton.bounds.height)
            self.toolBar.layoutIfNeeded()
            stackViewLeft.constant = 0
            
            if isLandscape {
                self.stackViewButtonDetail.spacing = 24
                self.trailingViewSearchiPhone.constant = 24
                self.stackViewReplace.spacing = 22
                self.stackViewButtonClean.spacing = 2
                self.trailingStackViewSearch.constant = 8
                self.leadingStackViewReplace.constant = 22
                self.leadingSearchBar.constant = 22
                self.leadingContainerSearchView.constant = 5
                self.trailingContainerSearchView.constant = -8
                if #available(iOS 11.0, *), let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
                    if window.safeAreaInsets.left > 0 || window.safeAreaInsets.right > 0 {
                        stackViewLeft.constant = window.safeAreaInsets.left > 44 ? -4 : 0
                    }
                }
            } else {
                self.stackViewButtonDetail.spacing = 16
                self.trailingViewSearchiPhone.constant = 16
                self.stackViewReplace.spacing = 13
                self.stackViewButtonClean.spacing = 2
                self.trailingStackViewSearch.constant = 8
                self.leadingStackViewReplace.constant = 15
                self.leadingSearchBar.constant = 16
                self.leadingContainerSearchView.constant = 0
                self.trailingContainerSearchView.constant = 0
            }
            self.view.layoutIfNeeded()
            updateSpacingButtonIPhone.onNext(true)
        }
    }
    
    private func updateLayoutIPad(size: CGSize, isFirst: Bool) {
        let isLandscape = (size.height < size.width) ? true : false
        let ratioIPad: CGFloat = 0.2
        
        self.idiomButton.bounds.size = CGSize(width: (isLandscape) ? ((size.width - 256) * ratioIPad) : (size.width * ratioIPad),
                                              height: idiomButton.bounds.height)

        self.thesaurusButton.bounds.size = CGSize(width: (isLandscape) ? ((size.width - 256) * ratioIPad) : (size.width * ratioIPad),
                                                  height: thesaurusButton.bounds.height)
        self.dictionaryButton.bounds.size = CGSize(width: (isLandscape) ? ((size.width - 256) * ratioIPad) : (size.width * ratioIPad),
                                                   height: dictionaryButton.bounds.height)
        self.updateSpacingButtonIPad.onNext((isFirst, size))
        
        if size.width < 400 {
            let width = self.idiomButton.sizeThatFits(self.idiomButton.bounds.size).width
            self.idiomButton.bounds.size.width = width
            
            //currently, Dictionary's Button is followed to IdiomButton's Width
            self.dictionaryButton.bounds.size.width = width
        }
        
        self.leadingContainerSearchView.constant = isLandscape ? -2 : 8
        self.trailingContainerSearchView.constant = isLandscape ? 0 : -8

        self.stackViewButtonDetail.spacing = 24
        self.trailingViewSearch.constant = 24
        self.stackViewReplace.spacing = 22
        self.stackViewButtonClean.spacing = 2
        self.trailingStackViewSearch.constant = 8
        self.leadingStackViewReplace.constant = 22
        self.leadingSearchBar.constant = 24
        self.trailingViewSearchiPhone.constant = 24
        self.view.layoutIfNeeded()
    }
    
    private func getUpdateLayoutIpad(isFirst: Bool, size: CGSize) {
        let isLandscape = (size.height < size.width) ? true : false
        let positionX: CGFloat = 128
        guard !isLandscape else {
            guard let tabBarItem = self.idiomButton.superview else { return  }
            guard let superView = tabBarItem.superview else { return  }
            self.stackViewLeft.constant = positionX
            self.stackViewRight.constant = positionX
            self.fontStyleLeftSafe.constant = positionX
            self.fontStyleRightSafe.constant = positionX
            if size.width == superView.bounds.width {
                self.fixedThesaurus.width = positionX + (self.spaceToolBar ?? 20)
                self.fixedKeyboardState.width = positionX + (self.spaceToolBar ?? 20)
            } else {
                self.fixedThesaurus.width = positionX
                self.spaceToolBar = (size.width - superView.bounds.width) / 2
                self.fixedKeyboardState.width = positionX
            }
            
            self.fontStyleView.setNeedsDisplay()
            return
        }

        self.stackViewLeft.constant = 0
        self.stackViewRight.constant = 0
        self.fontStyleLeftSafe.constant = 0
        self.fontStyleRightSafe.constant = 0
        self.fixedThesaurus.width = 0
        self.fixedKeyboardState.width = 0
        
        self.fontStyleView.setNeedsDisplay()
    }
    
    fileprivate func updateTitle(text: String, index: Int, source: String, replacement: String) {
        var currentText = NSMutableAttributedString(string: text, attributes: [
            NSAttributedString.Key.foregroundColor: Asset.textPrimary.color,
            NSAttributedString.Key.backgroundColor: UIColor.clear,
            NSAttributedString.Key.font: self.settingFont?.getFont() ?? UIFont.textFieldFont
        ])
        
        let textLen = currentText.string.utf16.count
        let start = index
        let sourceLen = source.utf16.count
        let replacementLen = replacement.utf16.count
        
        if textLen < start + sourceLen {
            // out of bounds
            return
        }
        
        forceShowTitleTrigger.onNext(())
        
        if source == replacement {
            // only highlight the selected text
            currentText.addAttributes([.backgroundColor: Asset.tag.color], range: NSMakeRange(start, sourceLen))
        } else {
            // highlight and replace the selected text
            let replacementAttrString = NSAttributedString(string: replacement, attributes: [
                NSAttributedString.Key.foregroundColor: Asset.textPrimary.color,
                NSAttributedString.Key.backgroundColor: Asset.tag.color,
                NSAttributedString.Key.font: self.settingFont?.getFont() ?? UIFont.textFieldFont
            ])
            
            currentText.replaceCharacters(in: NSMakeRange(start, sourceLen), with: replacementAttrString)
        }
        
        if let validText = viewModel.validate(title: currentText) {
            currentText = NSMutableAttributedString(attributedString: validText)
        }
        
        self.titleTextField.setAttributedTextAndUpdateUI(currentText)
        updateRawTitleTrigger.onNext(self.titleTextField.text ?? "")
        
        // -----------------------------
        // scroll
        if start == 0 {
            topView.scroll(toOffset: .zero)
        } else if
            let start = titleTextField.position(from: titleTextField.beginningOfDocument, offset: start),
            let end = titleTextField.position(from: start, offset: replacementLen),
            let textRange = titleTextField.textRange(from: start, to: end)
        {
            let rect = self.titleTextField.firstRect(for: textRange)
            let offset = CGPoint(x: rect.origin.x, y: 0)
            topView.scroll(toOffset: offset)
        } else {
            topView.updateWidthWithLast()
        }
    }
    
    private func highLighttext(range: NSRange, statusHighlight: SettingFont.StatusHighlight) {
        var color: UIColor
        switch statusHighlight {
        case .search:
            color = Asset.textSearch.color
        case .replace:
            color = Asset.textReplace.color
        default:
            color = UIColor.clear
        }
        
        if let textRange = self.contentTextView.getTextRangeFromRange(range: range),
           let source = self.contentTextView.getTextFromRange(range: range) {
            self.contentTextView.replace(textRange, withText: source)
            updateRawContentTrigger.onNext(self.contentTextView.text)
            self.contentTextView.textStorage.addAttributes([.backgroundColor: color], range: NSMakeRange(range.location,
                                                                                                                   range.length))
        }
    }

    
    private func replaceTextHighLight(textRange: NSRange, replacement: String) {
        let start = textRange.location
        let sourceLen = self.contentTextView.text.utf16.count
        let cal = self.contentTextView.text.utf16.count - start
        let limitLen = cal > 0 ? min(sourceLen, cal) : 0
        if
            limitLen > 0,
            let fromTextPosition = self.contentTextView.position(from: self.contentTextView.beginningOfDocument, offset: start),
            let toTextPosition = self.contentTextView.position(from: fromTextPosition, offset: textRange.length),
            let textRange = self.contentTextView.textRange(from: fromTextPosition, to: toTextPosition)
        {
            self.contentTextView.replace(textRange, withText: replacement)
            self.replaceMaskTextView(textRange: textRange, text: replacement)
            updateRawContentTrigger.onNext(self.contentTextView.text)
        }
    }
    
    fileprivate func updateContent(text: String, index: Int, source: String, replacement: String, isTag: Bool = true, canRepalce: Bool) {
        // clear highlight
        clearContentHighlight()
        
        let textLen = text.utf16.count// self.contentTextView.text.utf16.count
        let start = index
        let sourceLen = source.utf16.count
        let replacementLen = replacement.utf16.count
        
        if textLen < start + sourceLen {
            // out of bounds
            return
        }
        
        // replace the selected text
        let sourceRange = NSMakeRange(start, sourceLen)
        if let validText = viewModel.validate(content: text, shouldChangeTextIn: sourceRange, replacementText: replacement), self.contentTextView.text != validText {
            
        } else if canRepalce {
            let cal = self.contentTextView.text.utf16.count - start
            let limitLen = cal > 0 ? min(sourceLen, cal) : 0
            if
                limitLen > 0,
                let fromTextPosition = self.contentTextView.position(from: self.contentTextView.beginningOfDocument, offset: start),
                let toTextPosition = self.contentTextView.position(from: fromTextPosition, offset: limitLen),
                let textRange = self.contentTextView.textRange(from: fromTextPosition, to: toTextPosition)
            {
                self.contentTextView.replace(textRange, withText: replacement)
                self.replaceMaskTextView(textRange: textRange, text: replacement)
                updateRawContentTrigger.onNext(self.contentTextView.text)
            }
        }
        
        // highlight the selected text
        if source == replacement, start < self.contentTextView.text.utf16.count {
            let cal = start + sourceLen - self.contentTextView.text.utf16.count
            let limitLen = cal > 0 ? min(sourceLen, cal) : sourceLen
            if limitLen > 0 {
                if isTag {
                    self.contentTextView.textStorage.addAttributes([.backgroundColor: Asset.tag.color], range: NSMakeRange(start, limitLen))
                }
            }
            
        } else {
            // highlight and replace the selected text
            let highLightRange = NSMakeRange(start, replacementLen)
            if let range = highLightRange.intersection(NSRange(location: 0, length: self.contentTextView.text.utf16.count)) {
                if isTag {
                    self.contentTextView.textStorage.addAttributes([.backgroundColor: Asset.tag.color], range: range)
                }
            }
        }
        
        // -----------------------------
        // scroll
        if start == 0 {
            self.contentTextView.setContentOffset(.zero, animated: true)
        } else {
            if start - Constant.expandedRange < 0 {
                // scroll to top
                self.contentTextView.setContentOffset(.zero, animated: true)
            } else if start + replacementLen + Constant.expandedRange > self.contentTextView.text.utf16.count {
                // scroll to bottom
                let visibleRect = self.contentTextView.visibleRectConsideringInsets(true)
                let offsetY = self.contentTextView.contentSize.height - visibleRect.height - 1 // In some cases, the textView can be scrolled back to the top if you scrolls it to the bottom exactly. That's why the value minus 1
                
                if offsetY > 0 {
                    let offset = CGPoint(x: 0, y: offsetY)
                    self.contentTextView.setContentOffset(offset, animated: true)
                }
            } else {
                let range = NSRange(location: start - Constant.expandedRange, length: replacementLen + 2 * Constant.expandedRange)
                self.contentTextView.scrollRangeToVisible(range, consideringInsets: true)
                
            }
        }
    }
    
    fileprivate func clearTitleHighlight() {
        let range = self.titleTextField.selectedTextRange
        let cleanText = NSMutableAttributedString(string: titleTextField.text ?? "", attributes: [
                                                    NSAttributedString.Key.font: titleTextField.font!,
                                                    NSAttributedString.Key.foregroundColor: Asset.textPrimary.color]
        )
        
        self.titleTextField.attributedText = cleanText
        self.titleTextField.selectedTextRange = range
    }
    
    fileprivate func clearContentHighlight() {
        self.contentTextView.textStorage.removeAttribute(.backgroundColor, range: NSMakeRange(0, self.contentTextView.text.utf16.count))
        let attributeString = NSMutableAttributedString(attributedString: self.contentTextView.attributedText)
        self.maskContentTextView.attributedText = attributeString
        self.contentTextView.textColor = Asset.textPrimary.color
        self.maskContentTextView.isHidden = true
        self.cacheListRange.removeAll()
        self.lastCurrentIndex = nil
    }
    
    private func updateUndoRedoState() {
        undoButton.isEnabled = contentTextView.undoManager?.canUndo ?? false
        redoButton.isEnabled = contentTextView.undoManager?.canRedo ?? false
        
        undoButton.backgroundColor = undoButton.isEnabled ? Asset.undoBgEnable.color : Asset.undoBgDisable.color
        redoButton.backgroundColor = redoButton.isEnabled ? Asset.undoBgEnable.color : Asset.undoBgDisable.color
    }
    
    private func moveCursorToEndOfSelectedText() {
        if let selectedTextRange = contentTextView.selectedTextRange {
            let newRange = contentTextView.textRange(from: selectedTextRange.end, to: selectedTextRange.end)
            contentTextView.selectedTextRange = newRange
            
            contentTextView.scrollRangeToVisible(contentTextView.selectedRange, consideringInsets: true)
        }
    }
    
    private func scrollToPosition(at range: NSRange, showRange: Bool) {
        shouldBindContentOffset = false
        if self.maskContentTextView.isHidden == false {
            self.maskContentTextView.scrollRangeToVisible(range, consideringInsets: true)
            self.contentTextView.scrollRangeToVisible(range, consideringInsets: true)
            if showRange {
                self.maskContentTextView.selectedRange = range
                self.contentTextView.selectedRange = range
            }
            return
        }
        self.contentTextView.scrollRangeToVisible(range, consideringInsets: true)
        
        if showRange {
            self.contentTextView.selectedRange = range
        }
        
    }
    
    private func setCursor(at position: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if self.contentTextView.text.utf16.count < position {
                return
            }
            
            if let textPosition = self.contentTextView.position(from: self.contentTextView.beginningOfDocument,
                                                                offset: position),
               let textRange = self.contentTextView.textRange(from: textPosition, to: textPosition) {

                // force layout for text containner
                self.contentTextView.layoutManager.ensureLayout(for: self.contentTextView.textContainer)
                let rect = self.contentTextView.firstRect(for: textRange)
                self.contentTextView.scrollRectToVisible(rect, animated: false)
                
                self.maskContentTextView.layoutManager.ensureLayout(for: self.maskContentTextView.textContainer)
    
                self.maskContentTextView.scrollRectToVisible(rect, animated: false)
                
                // display keyboard
                self.contentTextView.becomeFirstResponder()
                
                // set cursor position
                self.contentTextView.selectedTextRange = textRange
                self.maskContentTextView.selectedTextRange = textRange
            }
        }
    }
    
    private func updateFontWhenUndo() {
        guard let s = self.settingFont else {
            return
        }
        
        self.contentTextView.font = s.getFont()
        self.maskContentTextView.font = s.getFont()
        self.contentTextView.textColor = Asset.textPrimary.color
    }
    
    // MARK: - Action
    @IBAction func undoButtonPressed(_ sender: Any) {
        if let undoManager = contentTextView.undoManager, undoManager.canUndo, !undoManager.isUndoing, !undoManager.isRedoing {
            undoManager.undo()
            self.clearContentHighlight()
            self.updateFontWhenUndo()
            moveCursorToEndOfSelectedText()
        }
        updateUndoRedoState()
    }
    
    @IBAction func redoButtonPressed(_ sender: Any) {
        if let undoManager = contentTextView.undoManager, undoManager.canRedo, !undoManager.isUndoing, !undoManager.isRedoing  {
            undoManager.redo()
            self.clearContentHighlight()
            self.updateFontWhenUndo()
            moveCursorToEndOfSelectedText()
        }
        
        updateUndoRedoState()
    }
    
    @IBAction func keyboardStateButtonPressed(_ sender: Any) {
        if titleTextField.isFirstResponder || contentTextView.isFirstResponder {
            if titleTextField.isFirstResponder {
                titleTextField.resignFirstResponder()
            } else {
                contentTextView.resignFirstResponder()
            }
        } else if let text = titleTextField.text, text.isEmpty {
            titleTextField.becomeFirstResponder()
        } else if contentTextView.text.isEmpty {
            contentTextView.becomeFirstResponder()
        } else {
            titleTextField.becomeFirstResponder()
        }
    }
    
    // MARK: - Gesture Handles
    @objc func tapOnContentGestureHandle(_ gesture: UITapGestureRecognizer) {
        tapContentView.onNext(())
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}

// MARK: - UITextFieldDelegate
extension CreationViewController: UITextFieldDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        shouldBindContentOffset = true
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            shouldBindContentOffset = false
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if viewSearch.isHidden == false && shouldBindContentOffset {
            maskContentTextView.setContentOffset(scrollView.contentOffset, animated: false)
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        contentTextView.becomeFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if let validText = viewModel.validate(title: textField.text ?? "", shouldChangeTextIn: range, replacementText: string) {
            let range = textField.selectedTextRange
            if textField.text != validText, let endToEnd = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument) {
                textField.replace(endToEnd, withText: validText)
                eventShowAlertTitleMaxLenght.onNext(range)
            }
            
            return false
        }
        
        return true
    }
    
    private func updateDarkMode() {
        self.viewsSearch.forEach { (v) in
            v.layer.borderColor = Asset.cecece666666.color.cgColor
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.updateDarkMode()
    }
    
    // Should remove after implement custom Undo Manager
    private func replaceMaskTextView(textRange: UITextRange, text: String) {
        maskContentTextView.replace(textRange, withText: text)
    }
    
    private func handlePasteTitle(object: UITextField, range: NSRange, paste: String, textRange: UITextRange) {
        if let validText = viewModel.validate(title: object.text ?? "", shouldChangeTextIn: range, replacementText: paste) {
            let textReplace = viewModel.getTextReplace(currentText: object.text ?? "",
                                                       maxLen: CreationUseCase.Constant.maxTitle,
                                                       shouldChangeTextIn: range,
                                                       replacementText: paste) ?? ""
            if object.text != validText,
               let start = object.position(from: textRange.start, offset: 0),
               let end = object.position(from: textRange.end, offset: 0),
               let endToEnd = object.textRange(from: start, to: end)
            {
                object.replace(endToEnd, withText: textReplace)
                if let newPosition = self.titleTextField.position(from: textRange.start, offset: textReplace.count) {
                    self.titleTextField.selectedTextRange = self.titleTextField.textRange(from: newPosition, to: newPosition)
                    eventShowAlertTitleMaxLenght.onNext(self.titleTextField.selectedTextRange)
                }
                
            }
        } else {
            if let start = object.position(from: textRange.start, offset: 0),
               let end = object.position(from: textRange.end, offset: 0),
               let endToEnd = object.textRange(from: start, to: end)
            {
                object.replace(endToEnd, withText: paste)
                if let newPosition = self.titleTextField.position(from: textRange.start, offset: paste.count) {
                    self.titleTextField.selectedTextRange = self.titleTextField.textRange(from: newPosition, to: newPosition)
                }
                
            }
        }
    }
}

// MARK: - UITextPasteDelegate
extension CreationViewController: UITextPasteDelegate {
    func textPasteConfigurationSupporting(_ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting, transform item: UITextPasteItem) {
        guard let paste = UIPasteboard.general.string else {
            return
        }
        if let object = textPasteConfigurationSupporting as? UITextField, let textRange = object.selectedTextRange {
            let start = object.offset(from: object.beginningOfDocument, to: textRange.start)
            let end = object.offset(from: object.beginningOfDocument, to: textRange.end)
            let range = NSRange(location: start, length: end - start)
            self.handlePasteTitle(object: object, range: range, paste: paste, textRange: textRange)
        } else {
            if let textView = self.contentTextView  {
                let range = textView.selectedRange
                if viewModel.validateContent(content: textView.text ?? "", shouldChangeTextIn: range, replacementText: paste) != nil {
                    self.handleTextOver(textView: textView, range: range, replacementText: paste, typePasteOverLength: .paste)
                } else {
                    let start = range.location
                    if let fromTextPosition = textView.position(from: textView.beginningOfDocument, offset: start),
                       let toTextPosition = textView.position(from: fromTextPosition, offset: range.length),
                       let textRange = textView.textRange(from: fromTextPosition, to: toTextPosition) {
                        textView.replace(textRange, withText: paste)
                        self.replaceMaskTextView(textRange: textRange, text: paste)
                        updateRawContentTrigger.onNext(self.contentTextView.text)
                        self.updateRawContentTrigger.onNext(textView.text)
                        self.eventNumberOfCharacters.onNext(textView.text.count)
                        self.contentTextView.font = self.settingFont?.getFont()
                        self.updateParagraphStyle()
                        self.scrollToPosition(at: NSRange(location: range.location + paste.count, length: 0), showRange: true)
                        
                    }
                    
                }
            }
        }
        
    }
}

// MARK: - UITextViewDelegate
extension CreationViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateUndoRedoState()
        if self.maskContentTextView.isHidden == false {
            self.clearContentHighlight()
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (textView.markedTextRange != nil) && text.count == Constant.lengthTextReplace {
            return true
        }
        
        if text.isEmpty {
            return true
        }
        
        if viewModel.validateContent(content: textView.text ?? "", shouldChangeTextIn: range, replacementText: text) != nil {
            self.handleTextOver(textView: textView, range: range, replacementText: text, typePasteOverLength: .inputText)

            return false
        }
        
        /// to prevent a crash when text view's reaching to the limit of character, then user undo the text which is cut off because of limitation condition
        /// `range.upperBound` is counted with utf16, so the `textView.text` has to be counted with utf16 also
        if (textView.undoManager?.isUndoing == true || textView.undoManager?.isRedoing == true) && textView.text.utf16.count < range.upperBound {
            if let variableRange = NSRange(location: 0, length: textView.text.utf16.count).intersection(range),
               let startPosition = textView.position(from: textView.beginningOfDocument, offset: variableRange.location),
               let endPosition = textView.position(from: startPosition, offset: variableRange.length),
               let textRange = textView.textRange(from: startPosition, to: endPosition) {
                
                textView.replace(textRange, withText: text)
                self.replaceMaskTextView(textRange: textRange, text: text)
            }
            
            return false
        }
        
        return true
    }
}

// MARK: - UIGestureRecognizerDelegate
extension CreationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}
