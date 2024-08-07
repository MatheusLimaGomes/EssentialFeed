//
//  FeedUIComposer.swift
//  EssentialFeediOS
//
//  Created by Matheus Gomes on 26/06/24.
//
import EssentialFeed
import UIKit

public final class FeedUIComposer {
    private init() {}
    
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let feedViewModel = FeedViewModel(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(viewModel: feedViewModel)
        let feedController = FeedViewController(refreshController: refreshController)
        feedViewModel.onFeedLoad = adaptFeedToCellControllers(
            forwardingTo: feedController,
            loader: imageLoader
        )
        return feedController
    }
    private static func adaptFeedToCellControllers(forwardingTo controller: FeedViewController, loader: FeedImageDataLoader) -> ([FeedImage]) -> Void {
        { [weak controller] feed in
            controller?.tableModel = feed.map({
                model in
                FeedImageCellController(
                    viewModel: FeedImageViewModel<UIImage>(model: model, imageLoader: loader, imageTransformer: UIImage.init)
                )
            })
        }
    }
}
