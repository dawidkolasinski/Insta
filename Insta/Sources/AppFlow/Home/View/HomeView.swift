//
//  HomeView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct HomeView<ViewModel: HomeViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel

    var body: some View {
        Text("HomeView")
    }

    init(viewModel: ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
}

