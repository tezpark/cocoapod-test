//
//  AIAgentStarterKit.swift
//  QuickStart
//
//  Created by Tez Park on 5/12/25.
//

import UIKit
import SendbirdAIAgentMessenger
import SendbirdChatSDK

extension AIAgentStarterKit {
    /// Stores information required to manage a session with the AI Agent.
    class SessionData {
        /// The application ID used to identify the AI Agent service.
        var appId: String = ""
        /// The user ID associated with the current session.
        var userId: String?
        /// The session token used for authentication and session management.
        var sessionToken: String?
        /// The delegate handling session-related events.
        var sessionHandler: AIAgentSessionDelegate?
    }
    
    /// Represents the different lifecycle stages of the AI Agent.
    enum Status {
        case uninitialized
        case initialized
        case readyToUse
    }
}

/// Singleton controller for initializing and managing AI Agent SDK operations.
class AIAgentStarterKit: NSObject {
    typealias ErrorHandler = (Error?) -> Void
    
    static let shared = AIAgentStarterKit()
    
    static var isConnected: Bool = false
    static var sessionData = SessionData()
    
    var onReadyToUse: (() -> Void)?
    var initParamsBuilder: ((_ params: SendbirdChatSDK.InitParams?) -> Void)?
    var status: Status = .uninitialized {
        didSet {
            if self.status == oldValue { return }
            if self.status != .readyToUse { return }
            DispatchQueue.main.async { [weak self] in
                self?.onReadyToUse?()
            }
        }
    }
}

// MARK: - Initialize
extension AIAgentStarterKit {
    /// Initializes the AI Agent SDK with the given application ID.
    /// - Parameters:
    ///   - appId: The application ID to initialize the SDK.
    ///   - completion: Optional completion handler called with an error if initialization fails.
    static func initialize(
        appId: String,
        completion: ErrorHandler? = nil
    ) {
        Self.sessionData.appId = appId
        
        // (Optional) for log level setting.
        AIAgentStarterKit.shared.initParamsBuilder = { params in
            params?.logLevel = .debug
        }
        
        Task {
            do {
                // INFO: This is only necessary when using extended SDKs(e,g,. UIKit, DeskSDK).
                try await ExtendedSDKBridge.initializeIfNeeded()
                
                try await self.initialize()
                
                #if INTERNAL_TEST
                if let target = SampleTestInfo.productionServer {
                    try await ExtendedSDKBridge.updateHost(target)
                }
                #endif
                
                AIAgentStarterKit.shared.status = .initialized
                DispatchQueue.main.async {
                    completion?(nil)
                }
            } catch {
                debugPrint("[sdk-initialize] error: \(error)")
                DispatchQueue.main.async {
                    completion?(error)
                }
            }
        }
    }
}

// MARK: - Session Management
extension AIAgentStarterKit {
    /// Updates the current session information with user ID, session token, and session handler.
    /// - Parameters:
    ///   - userId: The user ID for the session.
    ///   - sessionToken: The session token for authentication.
    ///   - sessionHandler: The delegate to handle session events.
    static func updateSessionInfo(
        userId: String,
        sessionToken: String?,
        sessionHandler: AIAgentSessionDelegate?
    ) {
        // Set the session data.
        AIAgentStarterKit.sessionData.userId = userId
        AIAgentStarterKit.sessionData.sessionToken = sessionToken
        AIAgentStarterKit.sessionData.sessionHandler = sessionHandler
        
        Task {
            do {
                // INFO: This is only necessary when using extended SDKs(e,g,. UIKit, DeskSDK).
                try await ExtendedSDKBridge.updateSessionInfoIfNeeded()
                
                try await self.updateSessionInfo()
                
                AIAgentStarterKit.shared.status = .readyToUse
            } catch {
                debugPrint("[session-info] error: \(error)")
            }
        }
    }
}

// MARK: Session Delegate
// TODO: This session handler is for example code only, and should be updated via the service's API.
extension AIAgentStarterKit: AIAgentSessionDelegate, SessionDelegate {
    /// Called when a session token is required for authentication.
    /// - Parameters:
    ///   - successCompletion: Closure to call with the session token on success.
    ///   - failCompletion: Closure to call on failure.
    func sessionTokenDidRequire(
        successCompletion success: @escaping (String?) -> Void,
        failCompletion fail: @escaping () -> Void
    ) {
        debugPrint("[xxx] aiagent session handler - \(#function)")
        success(AIAgentStarterKit.sessionData.sessionToken)
    }
    
    /// Called when the session has been closed.
    func sessionWasClosed() {
        debugPrint("[xxx] aiagent session handler - \(#function)")
    }
    
    /// Called when the session has been refreshed.
    func sessionWasRefreshed() {
        debugPrint("[xxx] aiagent session handler - \(#function)")
    }
    
    /// Handles common session errors.
    /// - Parameter error: The error encountered.
    func commonErrorHandle(_ error: Error) {
        debugPrint("[xxx] common session error handler - \(#function)- error: \(error)")
    }
    
    /// Called when the session encounters an error.
    /// - Parameter error: The error encountered.
    func sessionDidHaveError(_ error: Error) {
        self.commonErrorHandle(error)
    }
    
    /// Called when the session encounters an SBError.
    /// - Parameter error: The SBError encountered.
    func sessionDidHaveError(_ error: SBError) {
        self.commonErrorHandle(error)
    }
}


// MARK: - Connect/Disconnect
extension AIAgentStarterKit {
    /// Connects to the AI Agent service.
    /// - Parameter completion: Optional completion handler called with an error if connection fails.
    static func connect(completion: ErrorHandler? = nil) {
        Task {
            do {
                self.isConnected = true
                
                // INFO: This is only necessary when using extended SDKs(e,g,. UIKit, DeskSDK).
                try await ExtendedSDKBridge.connectIfNeeded()
                
                // If you only use AIAgent, there is no need to use this function because connect is handled internally when necessary.
                try await self.connect()
                
                DispatchQueue.main.async {
                    completion?(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion?(error)
                }
            }
        }
    }
    
    /// Disconnects from the AI Agent service.
    /// - Parameter completion: Optional completion handler called with an error if disconnection fails.
    static func disconnect(completion: ErrorHandler? = nil) {
        Task {
            do {
                self.isConnected = false
                
                // INFO: This is only necessary when using extended SDKs(e,g,. UIKit, DeskSDK).
                try await ExtendedSDKBridge.disconnectIfNeeded()
                
                try await self.disconnect()
                
                DispatchQueue.main.async {
                    completion?(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion?(error)
                }
            }
        }
    }
}

// MARK: - Present Conversation & Attach Launcher
extension AIAgentStarterKit {
    /// Use this when you want to display in full screen.
    /// - Parameter parent: The ViewController to parent and integrate with.
    static func present(parent: UIViewController) {
        AIAgentStarterKit.loadCustomSets()
        
        let params = ConversationSettingsParams(
            language: self.contextObjects.language,
            countryCode: self.contextObjects.countryCode,
            context: self.contextObjects.context,
            parent: parent
        )
        
        AIAgentMessenger.presentConversation(
            aiAgentId: SampleTestInfo.aiAgentId,
            params: params
        )
        
        // - NOTE: Use this logic if you want to present it as a conversation list.
//        AIAgentMessenger.presentConversationList(
//            aiAgentId: SampleTestInfo.aiAgentId,
//            params: params
//        )
    }
    
    /// Use this when you want to show and use the launcher button from the Sendbird Dashboard.
    /// - Parameter view: The view to parent.
    static func attachLauncher(view: UIView? = nil) {
        AIAgentStarterKit.loadCustomSets()
        
        // INFO: Sample
//        let options = SBALauncherOptions(
//            parentView: nil, // the view that will be the launcher's parent view, if not, attach to window.
//            entryPoint: .conversationList,
//
//            // options to set the layout of the laucnher button
//            layout: .init(
//                position: .trailingTop,
//                margin: .default,
//                useSafeArea: true
//            ),
//
//            // Options to set how the conversation screen is displayed
//            displayStyle: .fullscreen(
//                .init(
//                    presentationStyle: .fullScreen,
//                    parentController: nil
//                )
//            )
//        )
        
        // The point at which the context object is assigned is when the launcher is exposed.
        let params = LauncherSettingsParams(
            language: self.contextObjects.language,
            countryCode: self.contextObjects.countryCode,
            context: self.contextObjects.context
        )
        
        let startLauncher: (() -> Void) = {
            AIAgentMessenger.attachLauncher(
                aiAgentId: SampleTestInfo.aiAgentId,
                params: params
            )
        }
        
        AIAgentStarterKit.shared.onReadyToUse = startLauncher
        
        startLauncher()
    }

    /// Call this if you attach a launcher to the window.
    static func detachLauncher() {
        AIAgentMessenger.detachLauncher(
            aiAgentId: SampleTestInfo.aiAgentId
        )
    }
}
