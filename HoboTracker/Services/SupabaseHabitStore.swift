import Foundation
import Supabase

struct HabitDTO: Codable {
    let id: UUID
    let ownerId: String
    let name: String
    let habitDescription: String
    let iconName: String
    let colorHex: String
    let loggedDates: [Date]
    let creationDate: Date
    let updatedAt: Date
    let isDeleted: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case name
        case habitDescription = "habit_description"
        case iconName = "icon_name"
        case colorHex = "color_hex"
        case loggedDates = "logged_dates"
        case creationDate = "creation_date"
        case updatedAt = "updated_at"
        case isDeleted = "is_deleted"
    }
}

final class SupabaseHabitStore {
    private let client: SupabaseClient
    private let table = "habits"
    private let isoFormatter = ISO8601DateFormatter()

    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }

    func fetchUpdatedSince(_ date: Date?, userId: String) async throws -> [HabitDTO] {
        print("🔍 SupabaseHabitStore: Fetching habits for user: \(userId)")
        var query = client.database
            .from(table)
            .select()
            .eq("owner_id", value: userId)
            .order("updated_at", ascending: true)

        let response: PostgrestResponse<[HabitDTO]> = try await query.execute()
        print("🔍 SupabaseHabitStore: Fetched \(response.value.count) habits from database")
        
        if let date {
            let filtered = response.value.filter { $0.updatedAt >= date }
            print("🔍 SupabaseHabitStore: Filtered to \(filtered.count) habits updated since \(date)")
            return filtered
        }
        return response.value
    }

    func upsert(_ dto: HabitDTO) async throws {
        print("💾 SupabaseHabitStore: Upserting habit '\(dto.name)' (ID: \(dto.id)) for user: \(dto.ownerId)")
        _ = try await client.database
            .from(table)
            .upsert(dto)
            .execute()
        print("✅ SupabaseHabitStore: Successfully upserted habit '\(dto.name)'")
    }

    func delete(id: UUID, userId: String) async throws {
        print("🗑️ SupabaseHabitStore: Deleting habit ID: \(id) for user: \(userId)")
        _ = try await client.database
            .from(table)
            .delete()
            .eq("id", value: id.uuidString)
            .eq("owner_id", value: userId)
            .execute()
        print("✅ SupabaseHabitStore: Successfully deleted habit ID: \(id)")
    }
}
