//
//  Whistle.swift
//  Project33
//
//  Created by jc on 2020-07-12.
//  Copyright © 2020 J. All rights reserved.
//

import UIKit
import CloudKit

class Whistle: NSObject {
    var recordID: CKRecord.ID!
    var genre: String!
    var comments: String!
    var audio: URL!
}
