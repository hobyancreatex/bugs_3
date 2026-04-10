//
//  HomeInteractor.swift
//  Bugs
//

import Foundation

protocol HomeBusinessLogic: AnyObject {
    func load(request: Home.Load.Request)
}

final class HomeInteractor: HomeBusinessLogic {

    var presenter: HomePresentationLogic?

    func load(request: Home.Load.Request) {
        Task {
            let client = CollectAPIClient.shared
            async let categoriesTask = fetchCategories(client: client)
            async let popularTask = fetchPopular(client: client)
            async let articlesTask = fetchArticles(client: client)
            let (categories, popularInsects, articles) = await (categoriesTask, popularTask, articlesTask)
            let response = Home.Load.Response(
                categories: categories,
                popularInsects: popularInsects,
                articles: articles
            )
            await MainActor.run {
                self.presenter?.presentLoad(response: response)
            }
        }
    }

    private func fetchCategories(client: CollectAPIClient) async -> [Home.CategoryItemResponse] {
        do {
            let data = try await client.get(path: "insects/categories/")
            let rows = try CollectHomeListPayload.objectRows(from: data)
            return rows.compactMap { CollectHomeDTOMapper.category($0) }
        } catch {
            return []
        }
    }

    private func fetchPopular(client: CollectAPIClient) async -> [Home.PopularInsectItemResponse] {
        do {
            // Trailing slash: иначе редирект на …/popular/ может убрать Authorization → 401.
            let data = try await client.get(path: "insects/popular/")
            let rows = try CollectHomeListPayload.objectRows(from: data)
            return rows.compactMap { CollectHomeDTOMapper.popularInsect($0) }
        } catch {
            return []
        }
    }

    private func fetchArticles(client: CollectAPIClient) async -> [Home.ArticleItemResponse] {
        do {
            let data = try await client.get(path: "articles/insects/")
            let rows = try CollectHomeListPayload.objectRows(from: data)
            return rows.compactMap { CollectHomeDTOMapper.article($0) }
        } catch {
            return []
        }
    }
}
