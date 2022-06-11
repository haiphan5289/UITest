//
//  EmptyView.swift
//  GooDic
//
//  Created by ttvu on 3/11/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol EmptyViewDelegate {
    func saveIndex(sortModel: SortModel)
    func moveToSortEmpty()
}

enum EmptyType {
    case noDraft
    case noDraftInUncategoriedFolder
    case noDraftInFolder
    case noDraftInTrash
    case noCloudDraft
    case noCloudFolder
    
    var image: UIImage {
        switch self {
        case .noDraft: return Asset.imgEmpty01.image
        case .noDraftInUncategoriedFolder: return Asset.imgEmptyInUncategory.image
        case .noDraftInFolder: return Asset.imgEmptyInFolder.image
        case .noDraftInTrash: return Asset.imgEmpty02.image
        case .noCloudDraft: return Asset.imgCloudEmpty.image
        case .noCloudFolder: return Asset.imgCloudEmptyFolder.image
        }
    }
        
    var description: String {
        if self == .noDraftInTrash {
            return L10n.Trash.noData
        }
        
        return ""
    }
}

class EmptyView: UIView {
    
    static let minSize = CGSize(width: 300, height: 400)
    
    var delegate: EmptyViewDelegate?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var messageLbl: UILabel!
    private let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadNib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        loadNib()
    }
    
    private func loadNib() {
        let view = fromNib()
        addSubview(view)
        
        self.backgroundColor = UIColor.clear
        
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: self.topAnchor),
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            view.leftAnchor.constraint(equalTo: self.leftAnchor),
            view.rightAnchor.constraint(equalTo: self.rightAnchor)
        ])
    }
    
    func bind(type: EmptyType) {
        imageView.image = type.image
        messageLbl.text = type.description
    }
}
