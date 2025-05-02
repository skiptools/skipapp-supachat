import Foundation
import Observation
import SkipFuse
import SkipKeychain
import Supabase

/// A logger for the SupachatModel module.
let logger: Logger = Logger(subsystem: "supachat.model", category: "SupachatModel")

/// The Observable ViewModel used by the application.
@Observable public class ViewModel {
    public var items: [Item] = loadItems() {
        didSet { saveItems() }
    }

    public init() {
    }

    public func clear() {
        items.removeAll()
    }

    public func isUpdated(_ item: Item) -> Bool {
        item != items.first { i in
            i.id == item.id
        }
    }

    public func save(item: Item) {
        items = items.map { i in
            i.id == item.id ? item : i
        }
    }
}

/// An individual item held by the ViewModel
public struct Item : Identifiable, Hashable, Codable {
    public let id: UUID
    public var date: Date
    public var favorite: Bool
    public var title: String
    public var notes: String

    public init(id: UUID = UUID(), date: Date = .now, favorite: Bool = false, title: String = "", notes: String = "") {
        self.id = id
        self.date = date
        self.favorite = favorite
        self.title = title
        self.notes = notes
    }

    public var itemTitle: String {
        !title.isEmpty ? title : dateString
    }

    public var dateString: String {
        date.formatted(date: .complete, time: .omitted)
    }

    public var dateTimeString: String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}

/// Utilities for defaulting and persising the items in the list
extension ViewModel {
    private static let savePath = URL.applicationSupportDirectory.appendingPathComponent("appdata.json")

    fileprivate static func loadItems() -> [Item] {
        do {
            let start = Date.now
            let data = try Data(contentsOf: savePath)
            defer {
                let end = Date.now
                logger.info("loaded \(data.count) bytes from \(Self.savePath.path) in \(end.timeIntervalSince(start)) seconds")
            }
            return try JSONDecoder().decode([Item].self, from: data)
        } catch {
            // perhaps the first launch, or the data could not be read
            logger.warning("failed to load data from \(Self.savePath), using defaultItems: \(error)")
            let defaultItems = (1...365).map { Date(timeIntervalSinceNow: Double($0 * 60 * 60 * 24 * -1)) }
            return defaultItems.map({ Item(date: $0) })
        }
    }

    fileprivate func saveItems() {
        do {
            let start = Date.now
            let data = try JSONEncoder().encode(items)
            try FileManager.default.createDirectory(at: URL.applicationSupportDirectory, withIntermediateDirectories: true)
            try data.write(to: Self.savePath)
            let end = Date.now
            logger.info("saved \(data.count) bytes to \(Self.savePath.path) in \(end.timeIntervalSince(start)) seconds")
        } catch {
            logger.error("error saving data: \(error)")
        }
    }
}

// MARK: Supabase Credentials

// Update this section with your own Supabase account into

fileprivate let supabaseURL = "https://zncizygaxuzzvxnsfdvp.supabase.co"
fileprivate let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpuY2l6eWdheHV6enZ4bnNmZHZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDc4NjE1NDksImV4cCI6MjAyMzQzNzU0OX0.yoFteItT4FVu_kbMuMnQCzE8YYU5jEVWLU7NDBY94-E"

fileprivate let client = SupabaseClient(
    supabaseURL: URL(string: supabaseURL)!,
    supabaseKey: supabaseKey,
    options: SupabaseClientOptions(auth: SupabaseClientOptions.AuthOptions(storage: SimpleAuthLocalStorage()))
)

/// An auth storage that uses the iOS Keychain and Android EncyptedSharedPreferences.
///
/// Data is stored in base64-encoded string values.
struct SimpleAuthLocalStorage : AuthLocalStorage {
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


// WIP

struct Country: Codable {
    var id: Int
    var name: String
    var created: Date? = nil
    var gdp: Decimal? = nil
}

func fetchCountries() async throws -> [Country] {
    logger.log("running testSkipSupabase")

    let countriesResp: PostgrestResponse<[Country]> = try await client
        .from("countries")
        .select()
        .order("id")
        .limit(1)
        .execute(options: FetchOptions(head: false, count: CountOption.exact))
    let countries = countriesResp.value
    return countries
}

