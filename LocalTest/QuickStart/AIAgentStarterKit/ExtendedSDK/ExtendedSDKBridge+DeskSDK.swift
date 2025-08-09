//
//  DeskTask.swift
//  QuickStart
//
//  Created by Tez Park on 6/16/25.
//

/// This file defines the `DeskTask` class which manages DeskSDK-specific lifecycle for the extended SDK bridge.

import SendbirdAIAgentMessenger
import Foundation
import SendbirdChatSDK
#if canImport(SendBirdDesk)
import SendBirdDesk
#endif

extension ExtendedSDKBridge {
    /// A DeskSDK-specific implementation of `ExtendedSDKTaskable` that handles initialization,
    /// connection, session updates, and disconnection for the DeskSDK within the extended SDK bridge.
    class DeskTask: BaseTask, ExtendedSDKTaskable {
        /// Initializes the SendbirdChat and DeskSDK components asynchronously.
        /// Throws an error if initialization fails.
        func initialize() async throws {
            return try await withCheckedThrowingContinuation { continuation in
                let params = InitParams(applicationId: AIAgentStarterKit.sessionData.appId)
                AIAgentStarterKit.shared.initParamsBuilder?(params)
                
                // NOTE: SendbirdDesk must be initialized and used with SendbirdChat.
                SendbirdChat.initialize(
                    params: params,
                    migrationStartHandler: nil,
                    completionHandler: { error in
                        if let error {
                            continuation.resume(throwing: error)
                            return
                        }
                        #if canImport(SendBirdDesk)
                        if SBDSKMain.initializeDesk() == false {
                            continuation.resume(
                                throwing: ChatError.invalidParameter.asSBError
                            )
                            return
                        }
                        #endif
                        continuation.resume()
                    }
                )
            }
        }
        
        /// Updates session information if needed.
        /// This implementation does nothing as no session update is required.
        func updateSessionInfo() async throws {
            // do nothing
        }
        
        /// Connects to the DeskSDK using the current user's ID and session token.
        /// Throws an error if the user ID is missing or authentication fails.
        func connect() async throws {
            guard let userId = AIAgentStarterKit.sessionData.userId else {
                throw ChatError.invalidParameter.asSBError
            }
            
            let sessionToken = AIAgentStarterKit.sessionData.sessionToken
            
            return try await withCheckedThrowingContinuation { continuation in
                #if canImport(SendBirdDesk)
                SBDSKMain.authenticate(
                    withUserId: userId,
                    accessToken: sessionToken
                ) { error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume()
                }
                #else
                continuation.resume()
                #endif
            }
        }
        
        /// Disconnects from the DeskSDK.
        /// This implementation calls `initializeDesk` as part of the disconnection process.
        func disconnect() async throws {
            return try await withCheckedThrowingContinuation { continuation in
                #if canImport(SendBirdDesk)
                SBDSKMain.initializeDesk()
                #endif
                continuation.resume()
            }
        }
    }
}
