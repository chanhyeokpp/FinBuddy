import SwiftUI

/// 핵심 금융 용어(한자어)를 터치하면 다국어(영어, 중국어, 베트남어) 번역과 초보자용 쉬운 설명을 띄워주는 글래스모피즘 오버레이 뷰
struct JargonTooltipView: View {
    let word: String
    @Binding var isPresented: Bool
    
    @State private var translationEN: String = "Loading..."
    @State private var translationZH: String = "Loading..."
    @State private var translationVI: String = "Loading..."
    @State private var simpleDefinition: String = "Loading..."
    @State private var isLoading = true
    @State private var errorMsg: String? = nil

    var body: some View {
        ZStack {
            // 바깥 빈 화면 터치 시 자연스럽게 모달 닫기
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
            
            // 용어 해설 카드 (글래스모피즘 모티브)
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(word)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView().tint(Color.imMint)
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else if let error = errorMsg {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.vertical, 10)
                } else {
                    // 다국어 번역 그리드 영역
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Text("🇺🇸 English:")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .frame(width: 80, alignment: .leading)
                            Text(translationEN)
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                        }
                        
                        HStack(spacing: 8) {
                            Text("🇨🇳 中文:")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .frame(width: 80, alignment: .leading)
                            Text(translationZH)
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                        }
                        
                        HStack(spacing: 8) {
                            Text("🇻🇳 Tiếng Việt:")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .frame(width: 80, alignment: .leading)
                            Text(translationVI)
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.02))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                    Divider()
                    
                    // 초보자용 쉬운 한국어 설명
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.caption.bold())
                                .foregroundStyle(Color.imMint)
                            Text("쉬운 해설")
                                .font(.caption.bold())
                                .foregroundStyle(Color.imMint)
                        }
                        
                        Text(simpleDefinition)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
            .padding(.horizontal, 28)
        }
        .onAppear {
            loadJargonData()
        }
    }
    
    private func loadJargonData() {
        Task {
            do {
                let res = try await APIClient.shared.jargonLookup(word: word)
                translationEN = res.translation_en
                translationZH = res.translation_zh
                translationVI = res.translation_vi
                simpleDefinition = res.simple_definition
                isLoading = false
            } catch {
                errorMsg = "용어 설명을 불러오지 못했습니다: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

#Preview {
    JargonTooltipView(word: "비과세", isPresented: .constant(true))
}
