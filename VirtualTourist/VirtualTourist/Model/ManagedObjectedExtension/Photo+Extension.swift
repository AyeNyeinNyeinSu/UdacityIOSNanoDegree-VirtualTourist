//
//  Photo+Extension.swift
//  VirtualTourist
//
//  Created by Aye Nyein Nyein Su on 22/05/2023.
//

import Foundation

extension Photo {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.creationDate = Date()
    }
}
