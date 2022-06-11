//
//  BackupView.swift
//  GooDic
//
//  Created by Vinh Nguyen on 26/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit

class BackupView: UIView {
    
    struct Constant {
        enum BackupViewType {
            case backup, created
        }
    }
    
    @IBOutlet weak var stTitle: UILabel!
    @IBOutlet weak var titleDraftLbl: UILabel!
    @IBOutlet weak var contentDraftTv: UITextView!
    @IBOutlet weak var containerDraftView: UIView!
    
    @IBOutlet weak var lineView: UIView!

    
    private func updateUIWith(viewType: Constant.BackupViewType) {
        self.containerDraftView.backgroundColor = viewType == .backup ? Asset.f6Eceb.color : Asset.ffffff121212.color
        self.lineView.backgroundColor = viewType == .backup ?  Asset.cececeCfcfcf.color : Asset.cecece666666.color
    }
    
    func updateUIWith(backupDocument: CloudBackupDocument, document: Document, viewType: Constant.BackupViewType) {
        switch viewType {
        case .backup:
            self.stTitle.text = FormatHelper.dateFullFormatter.string(from: backupDocument.updatedAt) + L10n.BackupList.Backup.title
            self.titleDraftLbl.text = backupDocument.title
            self.contentDraftTv.text = backupDocument.content
            self.setCursor(at: backupDocument.cursorPosition, textView: self.contentDraftTv)
            break
        case .created:
            self.stTitle.text = L10n.BackupList.Backup.title
            self.titleDraftLbl.text = document.title
            self.contentDraftTv.text = document.content
            self.setCursor(at: document.cursorPosition, textView: self.contentDraftTv)
            break
        }
        self.updateUIWith(viewType: viewType)
    }

    private func setCursor(at position: Int, textView: UITextView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if textView.text.utf16.count < position {
                return
            }
            
            if let textPosition = textView.position(from: textView.beginningOfDocument,
                                                                offset: position),
               let textRange = textView.textRange(from: textPosition, to: textPosition) {

                // force layout for text containner
                textView.layoutManager.ensureLayout(for: textView.textContainer)
                let rect = textView.firstRect(for: textRange)
                textView.scrollRectToVisible(rect, animated: false)
                
                // set cursor position
                textView.selectedTextRange = textRange
            }
        }
    }

}
