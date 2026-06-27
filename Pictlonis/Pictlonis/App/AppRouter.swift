//
//  AppRouter.swift
//  Pictlonis
//
//  Created by Etienne Roche on 11/11/2025.
//
import SwiftUI
import Combine

final class AppRouter: ObservableObject {
    @Published var pendingRoomId: String? = nil
}
