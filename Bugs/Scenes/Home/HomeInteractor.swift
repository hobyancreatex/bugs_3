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
            let (categoriesResult, popularResult, articlesResult) = await (categoriesTask, popularTask, articlesTask)
            let hadError = categoriesResult.failed || popularResult.failed || articlesResult.failed
            let response = Home.Load.Response(
                categories: categoriesResult.items,
                popularInsects: popularResult.items,
                articles: articlesResult.items,
                hadNetworkError: hadError
            )
            await MainActor.run {
                self.presenter?.presentLoad(response: response)
            }
        }
    }

    private func fetchCategories(client: CollectAPIClient) async -> (items: [Home.CategoryItemResponse], failed: Bool) {
        do {
            let data = try await client.get(path: "insects/categories/")
            let rows = try CollectHomeListPayload.objectRows(from: data)
            return (rows.compactMap { CollectHomeDTOMapper.category($0) }, false)
        } catch {
            return ([], true)
        }
    }

    private func fetchPopular(client: CollectAPIClient) async -> (items: [Home.PopularInsectItemResponse], failed: Bool) {
        do {
            // Trailing slash: иначе редирект на …/popular/ может убрать Authorization → 401.
            let data = try await client.get(path: "insects/popular/")
            let rows = try CollectHomeListPayload.objectRows(from: data)
            return (rows.compactMap { CollectHomeDTOMapper.popularInsect($0) }, false)
        } catch {
            return ([], true)
        }
    }

    private func fetchArticles(client: CollectAPIClient) async -> (items: [Home.ArticleItemResponse], failed: Bool) {
        do {
            let data = try await client.get(path: "articles/insects/")
            let rows = try CollectHomeListPayload.objectRows(from: data)
            return (rows.compactMap { CollectHomeDTOMapper.article($0) }, false)
        } catch {
            return ([], true)
        }
    }
}
