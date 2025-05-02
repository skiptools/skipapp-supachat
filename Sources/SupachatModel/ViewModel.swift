import Foundation
import Observation
import SkipFuse
import SkipKeychain
import Supabase

/// A logger for the SupachatModel module.
let logger: Logger = Logger(subsystem: "supachat.model", category: "SupachatModel")

/// The Observable ViewModel used by the application.
@Observable @MainActor public class ViewModel {
    public var messages: [Message] = []
    /// The username, which is persisted to the UserDefaults
    public var username: String = UserDefaults.standard.string(forKey: "username") ?? "" {
        didSet { UserDefaults.standard.set(username, forKey: "username") }
    }

    public init() {
    }

    public func refreshMessages() async {
        do {
            messages = try await fetchMessages(username: username)
        } catch {
            logger.error("error refreshing messages: \(error)")
        }
    }

    func fetchMessages(username: String) async throws -> [Message] {
        try await client
            .from("message")
            .select()
            .or("sender.eq.\(username),recipient.eq.\(username)")
            .order("created_at", ascending: true)
            .execute()
            .value
    }
}

public struct Message: Identifiable, Codable, Hashable,Sendable {
    public var id: Int64
    public var created_at: Date? = nil
    public var sender: String
    public var recipient: String
    public var message: String
}

// MARK: Supabase Credentials

// Update this section with your own Supabase account info

fileprivate let supabaseURL = "https://zncizygaxuzzvxnsfdvp.supabase.co"
fileprivate let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpuY2l6eWdheHV6enZ4bnNmZHZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDc4NjE1NDksImV4cCI6MjAyMzQzNzU0OX0.yoFteItT4FVu_kbMuMnQCzE8YYU5jEVWLU7NDBY94-E"

fileprivate let client = SupabaseClient(
    supabaseURL: URL(string: supabaseURL)!,
    supabaseKey: supabaseKey,
    options: SupabaseClientOptions(
        auth: SupabaseClientOptions.AuthOptions(storage: SkipKeychainAuthLocalStorage())
    )
)


/// An auth storage that uses the iOS Keychain and Android EncyptedSharedPreferences.
///
/// Data is stored in base64-encoded string values.
struct SkipKeychainAuthLocalStorage : AuthLocalStorage {
    func store(key: String, value: Data) throws {
        logger.info("SimpleAuthLocalStorage: store key: \(key)")
        try Keychain.shared.set(value.base64EncodedString(), forKey: key)
    }

    func retrieve(key: String) throws -> Data? {
        logger.info("SimpleAuthLocalStorage: retrieve key: \(key)")
        guard let value = try Keychain.shared.string(forKey: key) else {
            return nil
        }
        return Data(base64Encoded: value)
    }

    func remove(key: String) throws {
        logger.info("SimpleAuthLocalStorage: remove key: \(key)")
        try Keychain.shared.removeValue(forKey: key)
    }
}
