import Foundation

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case system
    case ko
    case en

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return String(localized: "Language.System")
        case .ko: return "한국어"
        case .en: return "English"
        }
    }

    /// nil = follow system locale
    var bundleLanguageCode: String? {
        switch self {
        case .system: return nil
        case .ko: return "ko"
        case .en: return "en"
        }
    }
}
