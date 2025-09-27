//
//  UserSource.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Foundation

struct UsersSource {
    private struct Root: Decodable { let pages: [Page] }
    private struct Page: Decodable { let users: [UserDTO] }
    private struct UserDTO: Decodable {
        let id: Int
        let name: String
        let profile_picture_url: URL
    }

    /// Zwraca użytkowników pogrupowanych jak w JSON: [pageIndex: [User]]
    func loadAllUsers() throws -> [[User]] {
        let url = try bundleURL(named: "users", ext: "json")
        let data = try Data(contentsOf: url)
        let root = try JSONDecoder().decode(Root.self, from: data)

        return root.pages.map { page in
            page.users.map { dto in
                User(id: dto.id, name: dto.name, avatarURL: dto.profile_picture_url)
            }
        }
    }

    private func bundleURL(named: String, ext: String) throws -> URL {
        guard let url = Bundle.main.url(forResource: named, withExtension: ext) else {
            throw NSError(domain: "UsersSource", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "users.json not found in bundle"
            ])
        }
        return url
    }
}
