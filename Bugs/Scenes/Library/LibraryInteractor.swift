//
//  LibraryInteractor.swift
//  Bugs
//

import Foundation

protocol LibraryBusinessLogic: AnyObject {
    func presentCategories(request: Library.Present.Request)
}

// Один запрос к API даже при нескольких быстрых вызовах `presentCategories`.
private actor LibraryCategoryLoader {
    private var cached: [Library.CategoryDefinition]?
    private var inflight: Task<[Library.CategoryDefinition], Never>?

    func getOrFetch(
        onStartingFetch: @Sendable () async -> Void,
        fetch: @escaping @Sendable () async -> [Library.CategoryDefinition]
    ) async -> [Library.CategoryDefinition] {
        if let c = cached { return c }
        if let t = inflight { return await t.value }
        await onStartingFetch()
        let newTask = Task { await fetch() }
        inflight = newTask
        let result = await newTask.value
        cached = result
        inflight = nil
        return result
    }
}

final class LibraryInteractor: LibraryBusinessLogic {

    var presenter: LibraryPresentationLogic?

    private let categoryLoader = LibraryCategoryLoader()

    func presentCategories(request: Library.Present.Request) {
        let query = request.searchQuery
        Task { [weak self] in
            guard let self else { return }
            let all = await self.categoryLoader.getOrFetch(
                onStartingFetch: { [weak self] in
                    await MainActor.run {
                        guard let self else { return }
                        self.presenter?.presentCategories(
                            response: Library.Present.Response(
                                definitions: [],
                                searchQuery: query,
                                isLoading: true
                            )
                        )
                    }
                },
                fetch: { await LibraryInteractor.fetchCategoriesFromAPI() }
            )
            let filtered = Self.filter(categories: all, searchQuery: query)
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.presenter?.presentCategories(
                    response: Library.Present.Response(
                        definitions: filtered,
                        searchQuery: query,
                        isLoading: false
                    )
                )
            }
        }
    }

    private static func fetchCategoriesFromAPI() async -> [Library.CategoryDefinition] {
        do {
            let data = try await CollectAPIClient.shared.get(path: "insects/categories/")
            let rows = try CollectHomeListPayload.objectRows(from: data)
            return rows.compactMap { row in
                guard let item = CollectHomeDTOMapper.category(row) else { return nil }
                return Library.CategoryDefinition(
                    displayTitle: item.displayTitle,
                    routingKey: item.categoryRoutingKey,
                    imageAssetName: item.imageAssetName,
                    imageURL: item.imageURL
                )
            }
        } catch {
            return []
        }
    }

    private static func filter(categories: [Library.CategoryDefinition], searchQuery: String) -> [Library.CategoryDefinition] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            return categories
        }
        return categories.filter { $0.displayTitle.lowercased().contains(q) }
    }
}
