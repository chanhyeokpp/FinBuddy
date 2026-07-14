import Foundation

/// 백엔드(FastAPI) 통신 담당. 시뮬레이터 기준 127.0.0.1:8000.
/// 실기기 테스트 시 Mac의 로컬 IP(예: 192.168.0.12)로 바꿔야 함 - 설정에서 조회
enum APIConfig {
    static let baseURL = URL(string: "http://127.0.0.1:8000")!
}

enum APIError: Error, LocalizedError {
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "서버 응답을 처리할 수 없습니다."
        case .server(let msg): return msg
        }
    }
}

struct APIClient {
    static let shared = APIClient()

    private func post<Req: Encodable, Res: Decodable>(
        path: String, body: Req, as: Res.Type
    ) async throws -> Res {
        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "서버 오류 (\(http.statusCode))"
            throw APIError.server(msg)
        }
        return try JSONDecoder().decode(Res.self, from: data)
    }

    func chat(question: String, language: String) async throws -> ChatResponse {
        try await post(path: "/chat", body: ChatRequest(question: question, language: language), as: ChatResponse.self)
    }

    func diagnose(_ req: EligibilityRequest) async throws -> EligibilityResponse {
        try await post(path: "/eligibility/diagnose", body: req, as: EligibilityResponse.self)
    }

    func jargonLookup(word: String) async throws -> JargonResponse {
        try await post(path: "/api/jargon", body: JargonRequest(word: word), as: JargonResponse.self)
    }
}
