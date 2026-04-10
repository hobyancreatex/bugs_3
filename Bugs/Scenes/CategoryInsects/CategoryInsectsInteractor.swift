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

    init(categoryRoutingKey: String) {
        self.categoryRoutingKey = categoryRoutingKey
    }

    func presentInsects(request: CategoryInsects.Present.Request) {
        let query = request.searchQuery
        lock.lock()
        loadGeneration += 1
        let generation = loadGeneration
        accumulated = []
        nextPageURL = nil
        isLoadingMore = false
        lastSearchQuery = query
        lock.unlock()

        Task { [weak self] in
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

            var url: URL? = Self.firstInsectsListURL()
            var pagesScanned = 0
            let maxSilentPages = 25

            repeat {
                guard generation == self.loadGeneration else { return }
                guard let pageURL = url else { break }
                let (items, next) = await Self.fetchPage(url: pageURL)
                let inCategory = Self.filterByCategory(items, routingKey: self.categoryRoutingKey)
                self.lock.lock()
                guard generation == self.loadGeneration else {
                    self.lock.unlock()
                    return
                }
                self.accumulated.append(contentsOf: inCategory)
                self.nextPageURL = next
                self.lock.unlock()
                url = next
                pagesScanned += 1

                let snapshot = self.copyAccumulated()
                if !Self.filterBySearch(snapshot, query: query).isEmpty { break }
                if next == nil { break }
            } while pagesScanned < maxSilentPages

            let definitions = self.makeDefinitions(search: query)
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
            let search = self.lastSearchQuery
            self.lock.unlock()

            let beforeDefinitions = self.makeDefinitions(search: search)
            await MainActor.run { [weak self] in
                guard let self, generation == self.loadGeneration else { return }
                self.presenter?.presentInsects(
                    response: CategoryInsects.Present.Response(
                        insects: beforeDefinitions,
                        searchQuery: search,
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

            let definitions = self.makeDefinitions(search: search)
            await MainActor.run { [weak self] in
                guard let self, generation == self.loadGeneration else { return }
                self.presenter?.presentInsects(
                    response: CategoryInsects.Present.Response(
                        insects: definitions,
                        searchQuery: search,
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

    private func makeDefinitions(search: String) -> [CategoryInsects.InsectDefinition] {
        let raw = copyAccumulated()
        let filtered = Self.filterBySearch(raw, query: search)
        return filtered.map {
            CategoryInsects.InsectDefinition(
                insectId: $0.id,
                title: $0.title,
                subtitle: $0.subtitle,
                imageAssetName: "home_popular_insect",
                imageURL: $0.imageURL
            )
        }
    }

    private static func firstInsectsListURL() -> URL {
        URL(string: "insects/", relativeTo: APIConfiguration.collectBaseURL)!.absoluteURL
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

    private static func filterBySearch(_ items: [CollectCatalogInsect], query: String) -> [CollectCatalogInsect] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            return items
        }
        return items.filter {
            $0.title.lowercased().contains(q) || $0.subtitle.lowercased().contains(q)
        }
    }
}
