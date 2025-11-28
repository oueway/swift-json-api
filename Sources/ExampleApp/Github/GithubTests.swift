//
//  GithubTests.swift
//  SwiftJsonApi
//
//  Created by Brandee on 11/28/25.
//
import Foundation
import SwiftJsonApi

struct GithubTests {
    func testExamples() async {
        MyLogger.setJsonApiLog(level: .warning)

        WebService.configure(delegate: GithubWebService())

        do {
            let response: SimpleListResponse = try await GHUser.list(pageSize: 3)
            print("✅ Got users:", response.items.count)
            let user: SimpleSingleResponse = try await GHUser.get(byID: "octocat")
            print("✅ Got user by username:", user.item)
            let user1: SimpleSingleResponse = try await GHUser.get(byID: "583231")
            print("✅ Got user by id:", user1.item)
        } catch {
            print("❌ Failure: \(error)")
        }
    }
}
