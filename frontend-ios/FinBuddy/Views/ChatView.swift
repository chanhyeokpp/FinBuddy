import SwiftUI
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var input: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedLanguage: String = "ko" // 기본값 한국어

    init() {
        // 최초 시스템 메세지: 투자자문 금지 안내
        messages.append(ChatMessage(role: .system, text: "📢 핀버디는 투자자문업자가 아니며 정보 제공 및 제도 안내만 수행합니다."))
    }

    func send() {
        let question = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }

        messages.append(ChatMessage(role: .user, text: question))
        input = ""
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let res = try await APIClient.shared.chat(question: question, language: selectedLanguage)
                messages.append(ChatMessage(role: .bot, text: res.answer, sources: res.sources))
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func sendDirect(question: String) {
        input = question
        send()
    }
}

struct ChatView: View {
    @StateObject private var vm = ChatViewModel()
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 상단 다국어 선택 토글 (한국어 / English / Tiếng Việt / 中文)
                HStack(spacing: 6) {
                    ForEach([("ko", "한국어 🇰🇷"), ("en", "English 🇺🇸"), ("vi", "Tiếng Việt 🇻🇳"), ("zh", "中文 🇨🇳")], id: \.0) { code, label in
                        Button {
                            withAnimation {
                                vm.selectedLanguage = code
                            }
                        } label: {
                            Text(label)
                                .font(.system(size: 11, weight: vm.selectedLanguage == code ? .bold : .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(vm.selectedLanguage == code ? Color.imMint.opacity(0.18) : Color.white.opacity(0.08))
                                .foregroundStyle(vm.selectedLanguage == code ? Color.imMint : Color.secondary)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(vm.selectedLanguage == code ? Color.imMint : Color.white.opacity(0.2), lineWidth: 0.8)
                                )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                
                ScrollViewReader { proxy in
                    ZStack {
                        AuroraBackgroundView()
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 14) {
                                ForEach(vm.messages) { msg in
                                    ChatBubble(message: msg).id(msg.id)
                                }
                                
                                // 로딩 중일 때 깜빡이는 점 3개 타이핑 인디케이터 표시
                                if vm.isLoading {
                                    HStack(spacing: 8) {
                                        TypingIndicatorView()
                                        Text("답변 준비 중...")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.leading, 8)
                                    .id("loading_indicator")
                                }
                                
                                // 최초 대화 상태(시스템 공지만 있을 때) 추천 질문 칩 목록 표시
                                if vm.messages.count <= 1 && !vm.isLoading {
                                    exampleChipsSection
                                }
                            }
                            .padding()
                        }
                    }
                    .onChange(of: vm.messages.count) { _ in
                        if let last = vm.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                    .onChange(of: vm.isLoading) { isLoading in
                        if isLoading {
                            withAnimation { proxy.scrollTo("loading_indicator", anchor: .bottom) }
                        }
                    }
                }
                .onAppear {
                    handlePrefill()
                }
                .onChange(of: appState.shouldAutoSend) { shouldSend in
                    if shouldSend {
                        handlePrefill()
                    }
                }

                if let error = vm.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.red).padding(.horizontal)
                }

                Divider()

                // 하단 반투명 입력부 (Glassmorphism Input)
                HStack(spacing: 10) {
                    TextField("ISA 비과세 한도가 얼마야?", text: $vm.input, axis: .vertical)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                        )
                    
                    Button {
                        vm.send()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(
                                vm.input.trimmingCharacters(in: .whitespaces).isEmpty ? AnyShapeStyle(Color.gray) : AnyShapeStyle(Color.imMintLimeGradient)
                            )
                    }
                    .disabled(vm.input.trimmingCharacters(in: .whitespaces).isEmpty || vm.isLoading)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        AIPulseCoreView(isLoading: vm.isLoading)
                        
                        Text("FinBuddy AI")
                            .font(.headline.bold())
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }

    // 추천 질문 칩 섹션
    private var exampleChipsSection: some View {
        VStack(spacing: 12) {
            Text("💡 이런 질문을 던져보세요")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .padding(.top, 40)
            
            VStack(spacing: 10) {
                ForEach([
                    "F-2 비자인데 ISA 되나요?",
                    "연금저축 세액공제 한도는?",
                    "종합소득세 언제까지 신고해요?"
                ], id: \.self) { question in
                    Button {
                        vm.sendDirect(question: question)
                    } label: {
                        Text(question)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
                            )
                    }
                    .shadow(color: .black.opacity(0.02), radius: 3, x: 0, y: 1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    private func handlePrefill() {
        guard appState.shouldAutoSend && !appState.chatPrefillQuestion.isEmpty else { return }
        let question = appState.chatPrefillQuestion
        appState.chatPrefillQuestion = ""
        appState.shouldAutoSend = false
        vm.sendDirect(question: question)
    }
}

// 실시간 AI 연산/대기 상태 고동 코어 (Pulsing Brain)
struct AIPulseCoreView: View {
    let isLoading: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var rotate = 0.0

    var body: some View {
        ZStack {
            // 외부 은은한 민트빛 안개 글로우
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.imMint.opacity(0.35), .clear],
                        center: .center, startRadius: 0, endRadius: 18
                    )
                )
                .frame(width: 36, height: 36)
                .scaleEffect(scale)
            
            // 회전하는 투톤 그래디언트 구체 코어
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.imMint, Color.imLime],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 14, height: 14)
                .rotationEffect(.degrees(rotate))
                .shadow(color: Color.imMint.opacity(0.4), radius: 4)
        }
        .onAppear {
            // 주기적인 맥박 효과
            withAnimation(
                .easeInOut(duration: 1.4)
                .repeatForever(autoreverses: true)
            ) {
                scale = 1.25
            }
            
            // 공전 모션
            withAnimation(
                .linear(duration: 4.5)
                .repeatForever(autoreverses: false)
            ) {
                rotate = 360.0
            }
        }
        .onChange(of: isLoading) { loading in
            // 연산 중일 때 맥박 주기가 빨라지며 강한 파장 묘사
            withAnimation(
                .easeInOut(duration: loading ? 0.5 : 1.4)
                .repeatForever(autoreverses: true)
            ) {
                scale = loading ? 1.55 : 1.25
            }
            
            withAnimation(
                .linear(duration: loading ? 1.5 : 4.5)
                .repeatForever(autoreverses: false)
            ) {
                rotate = loading ? 360.0 : 0.0
            }
        }
    }
}

// 로딩 애니메이션 컴포넌트 (타이핑 점 3개 모션)
struct TypingIndicatorView: View {
    @State private var dotOffset1: CGFloat = 0
    @State private var dotOffset2: CGFloat = 0
    @State private var dotOffset3: CGFloat = 0

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .frame(width: 6, height: 6)
                .foregroundStyle(.secondary)
                .offset(y: dotOffset1)
            Circle()
                .frame(width: 6, height: 6)
                .foregroundStyle(.secondary)
                .offset(y: dotOffset2)
            Circle()
                .frame(width: 6, height: 6)
                .foregroundStyle(.secondary)
                .offset(y: dotOffset3)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(Capsule())
        .onAppear {
            let duration = 0.4
            withAnimation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                dotOffset1 = -4
            }
            withAnimation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(0.12)) {
                dotOffset2 = -4
            }
            withAnimation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(0.24)) {
                dotOffset3 = -4
            }
        }
    }
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == ChatMessage.Role.system {
                // 공지/안내 메시지 렌더링
                Spacer()
                Text(message.text)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.4), lineWidth: 0.8)
                    )
                Spacer()
            } else if message.role == .bot {
                // AI 대화 풍선 (네추럴 프리미엄 글래스모피즘)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(Color.imMint)
                        Text("FinBuddy AI")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.imMint)
                    }
                    
                    Text(message.text)
                        .font(.system(size: 14.5))
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // RAG 출처 표시 칩 고도화
                    if !message.sources.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 9))
                            Text(message.sources.joined(separator: " / "))
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(Color.imMint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.imMint.opacity(0.08))
                        .clipShape(Capsule())
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.1)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
                
                Spacer(minLength: 50)
            } else {
                Spacer(minLength: 50)
                
                // 사용자 대화 풍선 (시각적으로 정돈된 민트 그라데이션)
                VStack(alignment: .trailing, spacing: 6) {
                    Text(message.text)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.imMint, Color.imMint.opacity(0.8)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.imMint.opacity(0.2), radius: 8, x: 0, y: 4)
            }
        }
    }
}


#Preview {
    ChatView()
}
