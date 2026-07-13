import Foundation

// MARK: - 챗봇

struct ChatRequest: Encodable {
    let question: String
}

struct ChatResponse: Decodable {
    let answer: String
    let sources: [String]
}

struct ChatMessage: Identifiable {
    enum Role { case user, bot, system }
    let id = UUID()
    let role: Role
    let text: String
    var sources: [String] = []
}

// MARK: - 자격진단

enum IncomeType: String, CaseIterable, Identifiable, Codable {
    case employed = "근로소득자"
    case selfEmployed = "자영업자"
    case none = "무소득"
    var id: String { rawValue }
}

struct EligibilityRequest: Encodable {
    let is_resident: Bool
    let age: Int
    let had_income_last_year: Bool
    let income_type: String
    let has_comprehensive_tax: Bool
}

struct ProductResult: Codable, Equatable {
    let eligible: Bool
    let reason: String
    let required_docs: [String]
}

struct EligibilityResponse: Codable, Equatable {
    let ISA: ProductResult
    let IRP: ProductResult
    let 연금저축펀드: ProductResult

    var all: [(name: String, result: ProductResult)] {
        [("ISA", ISA), ("IRP", IRP), ("연금저축펀드", 연금저축펀드)]
    }
}

// MARK: - 금융 용어 번역
struct JargonRequest: Encodable {
    let word: String
}

struct JargonResponse: Decodable {
    let word: String
    let translation_en: String
    let translation_zh: String
    let translation_vi: String
    let simple_definition: String
}
