//
//  ServerValidation.swift
//  GooDic
//
//  Created by paxcreation on 12/7/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

struct ServerValidation: Codable {
    let gooID: String?
    let userID: String?
    let gooidTicketManagerOutputExpired: String?

    enum CodingKeys: String, CodingKey {
        case gooID = "GOO_ID"
        case userID = "USER_ID"
        case gooidTicketManagerOutputExpired = "GOOID_TICKET_MANAGER_OUTPUT_EXPIRED"
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gooID = try container.decode(String.self, forKey: .gooID)
        userID = try container.decode(String.self, forKey: .userID)
        gooidTicketManagerOutputExpired = try container.decode(String.self, forKey: .gooidTicketManagerOutputExpired)
    }
}
