//
//  CollectAPIError.swift
//  Bugs
//

import Foundation

enum CollectAPIError: Error {
    case invalidURL
    case badStatus(Int, Data?)
}
