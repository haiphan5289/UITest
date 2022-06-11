//
//  Extension+DocumentSnapshot.swift
//  GooDic
//
//  Created by haiphan on 15/10/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import FirebaseFirestore

extension DocumentSnapshot {
    var convertData: Data? {
        guard let value = data() else { return nil }
        return try? JSONSerialization.data(withJSONObject: value, options: .prettyPrinted)
    }
}
