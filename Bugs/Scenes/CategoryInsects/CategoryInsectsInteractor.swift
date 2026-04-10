//
//  CategoryInsectsInteractor.swift
//  Bugs
//

import Foundation

protocol CategoryInsectsBusinessLogic: AnyObject {
    func presentInsects(request: CategoryInsects.Present.Request)
    func loadMoreInsects()
}

final class CategoryInsectsInteractor: CategoryInsectsBusinessLogic {

    var presenter: CategoryInsectsPresentationLogic?

    private let categoryRoutingKey: String
    private let lock = NSLock()
    private var loadGeneration = 0
    private var accumulated: [CollectCatalogInsect] = []
    private var nextPageURL: URL?
    private var isLoadingMore = false
    private var lastSearchQuery: String = ""
    private var listFetchTask: Task<Void, Never>?

    init(categoryRoutingKey: String) {
        self.categoryRoutingKey = categoryRoutingKey
    }

    func presentInsects(request: CategoryInsects.Present.Request) {
        listFetchTask?.cancel()
        let query = request.searchQuery
        lock.lock()
        loadGeneration += 1
        let generation = loadGeneration
        accumulated = []
        nextPageURL = nil
        isLoadingMore = false
        lastSearchQuery = query
        lock.unlock()

        listFetchTask = Task { [weak self] in
            guard let self else { return }
            await MainActor.run { [weak self] in
                guard let self, generation == self.loadGeneration else { return }
                self.presenter?.presentInsects(
                    response: CategoryInsects.Present.Response(
                        insects: [],
                        searchQuery: query,
                        isLoading: true,
                        isLoadingMore: false
                    )
                )
            }

            do {
                try await self.runInitialListFetch(generation: generation, query: query)
            } catch {
                return
            }

            let definitions = self.makeDefinitions()
            await MainActor.run { [weak self] in
                guard let self, generation == self.loadGeneration else { return }
                self.presenter?.presentInsects(
                    response: CategoryInsects.Present.Response(
                        insects: definitions,
                        searchQuery: query,
                        isLoading: false,
                        isLoadingMore: false
                    )
                )
            }
        }
    }

    /// Первая выдача: `GET insects/?search=…` (если строка не пустая), фильтр по категории на клиенте; при пустом результате листаем страницы, пока не появятся совпадения или конец выдачи.
    private func runInitialListFetch(generation: Int, query: String) async throws {
        var url: URL? = Self.firstInsectsListURL(search: query)
        var pagesScanned = 0
        let maxSilentPages = 25

        while pagesScanned < maxSilentPages {
            try Task.checkCancellation()
            guard generation == loadGeneration else { throw CancellationError() }
            guard let pageURL = url else { break }

            let (items, next) = await Self.fetchPage(url: pageURL)
            let inCategory = Self.filterByCategory(items, routingKey: categoryRoutingKey)

            lock.lock()
            guard generation == loadGeneration else {
                lock.unlock()
                throw CancellationError()
            }
            accumulated.append(contentsOf: inCategory)
            nextPageURL = next
            lock.unlock()

            pagesScanned += 1
            if !copyAccumulated().isEmpty { break }
            if next == nil { break }
            url = next
        }
    }

    func loadMoreInsects() {
        Task { [weak self] in
            guard let self else { return }
            self.lock.lock()
            guard let url = self.nextPageURL, !self.isLoadingMore else {
                self.lock.unlock()
                return
            }
            let generation = self.loadGeneration
            self.isLoadingMore = true
            let queryForResponse = self.lastSearchQuery
            self.lock.unlock()

            let beforeDefinitions = self.makeDefinitions()
            await MainActor.run { [weak self] in
                guard let self, generation == self.loadGeneration else { return }
                self.presenter?.presentInsects(
                    response: CategoryInsects.Present.Response(
                        insects: beforeDefinitions,
                        searchQuery: queryForResponse,
                        isLoading: false,
                        isLoadingMore: true
                    )
                )
            }

            let (items, next) = await Self.fetchPage(url: url)
            let inCategory = Self.filterByCategory(items, routingKey: self.categoryRoutingKey)

            self.lock.lock()
            guard generation == self.loadGeneration else {
                self.isLoadingMore = false
                self.lock.unlock()
                return
            }
            self.accumulated.append(contentsOf: inCategory)
            self.nextPageURL = next
            self.isLoadingMore = false
            self.lock.unlock()

            let definitions = self.makeDefinitions()
            await MainActor.run { [weak self] in
                guard let self, generation == self.loadGeneration else { return }
                self.presenter?.presentInsects(
                    response: CategoryInsects.Present.Response(
                        insects: definitions,
                        searchQuery: queryForResponse,
                        isLoading: false,
                        isLoadingMore: false
                    )
                )
            }
        }
    }

    private func copyAccumulated() -> [CollectCatalogInsect] {
        lock.lock()
        let c = accumulated
        lock.unlock()
        return c
    }

    private func makeDefinitions() -> [CategoryInsects.InsectDefinition] {
        copyAccumulated().map {
            CategoryInsects.InsectDefinition(
                insectId: $0.id,
                title: $0.title,
                subtitle: $0.subtitle,
                imageAssetName: "home_popular_insect",
                imageURL: $0.imageURL
            )
        }
    }

    private static func firstInsectsListURL(search: String) -> URL {
        let base = URL(string: "insects/", relativeTo: APIConfiguration.collectBaseURL)!.absoluteURL
        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return base }
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)!
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "search", value: trimmed))
        components.queryItems = items
        return components.url ?? base
    }

    private static func fetchPage(url: URL) async -> (items: [CollectCatalogInsect], next: URL?) {
        do {
            let data = try await CollectAPIClient.shared.get(url: url)
            if let parsed = try? CollectPaginatedPayload.parseInsectsListPage(data: data) {
                let items = parsed.rows.compactMap { CollectHomeDTOMapper.catalogInsect($0) }
                return (items, parsed.nextURL)
            }
            let rows = try CollectHomeListPayload.objectRows(from: data)
            let items = rows.compactMap { CollectHomeDTOMapper.catalogInsect($0) }
            return (items, nil)
        } catch {
            return ([], nil)
        }
    }

    private static func filterByCategory(_ items: [CollectCatalogInsect], routingKey: String) -> [CollectCatalogInsect] {
        let key = routingKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if key.isEmpty || key == "all" {
            return items
        }
        return items.filter { insect in
            insect.categoryMatchKeys.contains(key)
        }
    }

}
