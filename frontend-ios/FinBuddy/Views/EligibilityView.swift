import SwiftUI
import Combine
import CoreImage

@MainActor
final class EligibilityViewModel: ObservableObject {
    @Published var isResident = true
    @Published var age = 27
    @Published var hadIncomeLastYear = true
    @Published var incomeType: IncomeType = .employed
    @Published var hasComprehensiveTax = false

    @Published var result: EligibilityResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func diagnose() {
        isLoading = true
        errorMessage = nil
        result = nil

        let req = EligibilityRequest(
            is_resident: isResident,
            age: age,
            had_income_last_year: hadIncomeLastYear,
            income_type: incomeType.rawValue,
            has_comprehensive_tax: hasComprehensiveTax
        )

        Task {
            do {
                result = try await APIClient.shared.diagnose(req)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct EligibilityView: View {
    @StateObject private var vm = EligibilityViewModel()
    @EnvironmentObject private var appState: AppState
    
    // 아코디언 상태 보관
    @State private var expandedProducts: Set<String> = []
    
    // QR 모달 표시 여부 State
    @State private var isShowingQRModal = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 1. 오로라 일렁임 배경 적용
                AuroraBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if appState.isDiagnosed, let result = appState.diagnosedResult {
                            // 2. 자격진단 결과 노출 화면 (Result Screen State)
                            VStack(spacing: 20) {
                                
                                // 결과 요약 비주얼 헤더
                                VStack(spacing: 8) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 64))
                                        .foregroundStyle(Color.imMint)
                                        .padding(.bottom, 4)
                                    
                                    Text("자격 진단 완료")
                                        .font(.title2.bold())
                                        .foregroundStyle(.primary)
                                    
                                    Text("고객님의 신분 및 소득 조건에 맞춤 진단된 결과입니다.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.top, 10)
                                
                                // 3종 금융 상품 카드 (ISA / IRP / 연금저축펀드)
                                VStack(spacing: 14) {
                                    ForEach(result.all, id: \.name) { item in
                                        let name = item.name
                                        let isEligible = item.result.eligible
                                        let reason = item.result.reason
                                        let docs = item.result.required_docs
                                        let isExpanded = expandedProducts.contains(name)
                                        
                                        VStack(alignment: .leading, spacing: 0) {
                                            Button {
                                                if isEligible {
                                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                        if isExpanded {
                                                            expandedProducts.remove(name)
                                                        } else {
                                                            expandedProducts.insert(name)
                                                        }
                                                    }
                                                }
                                            } label: {
                                                HStack(spacing: 14) {
                                                    Image(systemName: isEligible ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                        .font(.title2)
                                                        .foregroundStyle(isEligible ? Color.imMint : .gray)
                                                    
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(name == "연금저축펀드" ? "연금저축펀드" : name)
                                                            .font(.headline.bold())
                                                            .foregroundStyle(.primary)
                                                        
                                                        Text(reason)
                                                            .font(.caption)
                                                            .foregroundStyle(.secondary)
                                                            .multilineTextAlignment(.leading)
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    Text(isEligible ? "가입 가능" : "가입 불가")
                                                        .font(.caption.bold())
                                                        .foregroundStyle(isEligible ? Color.imMint : .gray)
                                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                                        .background(isEligible ? Color.imMint.opacity(0.12) : Color.gray.opacity(0.12))
                                                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                                    
                                                    if isEligible {
                                                        Image(systemName: "chevron.down")
                                                            .font(.system(size: 11, weight: .bold))
                                                            .foregroundStyle(.secondary)
                                                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                                                            .padding(.leading, 2)
                                                    }
                                                }
                                                .padding(18)
                                            }
                                            
                                            // 아코디언 상세 영역: 필요 서류 리스트 노출
                                            if isEligible && isExpanded {
                                                Divider().padding(.horizontal, 18)
                                                
                                                VStack(alignment: .leading, spacing: 10) {
                                                    Text("📋 필요한 제출 서류")
                                                        .font(.caption.bold())
                                                        .foregroundStyle(.primary)
                                                    
                                                    if docs.isEmpty {
                                                        Text("비대면 인증으로 자동 서류 갈음이 가능하여 별도 지참 서류가 필요하지 않습니다.")
                                                            .font(.caption)
                                                            .foregroundStyle(.secondary)
                                                            .fixedSize(horizontal: false, vertical: true)
                                                    } else {
                                                        ForEach(docs, id: \.self) { doc in
                                                            HStack(spacing: 8) {
                                                                Circle()
                                                                    .frame(width: 4, height: 4)
                                                                    .foregroundStyle(.secondary)
                                                                Text(doc)
                                                                    .font(.caption)
                                                                    .foregroundStyle(.secondary)
                                                            }
                                                        }
                                                    }
                                                }
                                                .padding(18)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(Color.black.opacity(0.02))
                                            }
                                        }
                                        .glassmorphicCard()
                                        .padding(.horizontal)
                                    }
                                }
                                
                                // 하단 이동 버튼들
                                VStack(spacing: 12) {
                                    // 챗봇 상세 연동 질문
                                    Button {
                                        appState.chatPrefillQuestion = "내가 자격진단을 해봤는데 \(appState.diagnosisSummary) 판정을 받았어. 이 상품들에 외국인으로 비대면 가입하기 위한 준비 절차를 알려줘."
                                        appState.shouldAutoSend = true
                                        appState.selectedTab = 1 // 챗봇 탭
                                    } label: {
                                        Text("챗봇에서 더 물어보기")
                                    }
                                    .buttonStyle(GlassmorphicButtonStyle())
                                    .padding(.horizontal)
                                    
                                    // [NEW] 행원 공유용 QR 모달 노출 버튼
                                    Button {
                                        isShowingQRModal = true
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "qrcode")
                                                .font(.headline)
                                            Text("iM뱅크 행원에게 내 진단 공유 (QR)")
                                                .font(.subheadline.bold())
                                        }
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 14)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.imMintLimeGradient)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .shadow(color: Color.imMint.opacity(0.2), radius: 8, x: 0, y: 4)
                                    }
                                    .padding(.horizontal)
                                    
                                    // 다시 진단하기 폼 리턴
                                    Button {
                                        withAnimation {
                                            appState.clearDiagnosis()
                                            vm.result = nil
                                        }
                                    } label: {
                                        Text("다시 진단하기")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.top, 4)
                                }
                                .padding(.top, 10)
                            }
                        } else {
                            // 3. 프로필 입력 화면 (Input Form Screen State)
                            VStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 18) {
                                    Text("프로필 정보 입력")
                                        .font(.headline.bold())
                                        .foregroundStyle(.primary)
                                    
                                    Divider()
                                    
                                    Toggle("국내 거주자 (183일 이상 체류)", isOn: $vm.isResident)
                                        .tint(.imMint)
                                    
                                    HStack {
                                        Text("나이")
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Stepper("\(vm.age)세", value: $vm.age, in: 15...100)
                                    }
                                    
                                    Toggle("직전연도 근로소득 있음", isOn: $vm.hadIncomeLastYear)
                                        .tint(.imMint)
                                    
                                    HStack {
                                        Text("소득 유형")
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Picker("소득 유형", selection: $vm.incomeType) {
                                            ForEach(IncomeType.allCases) { Text($0.rawValue).tag($0) }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(.imMint)
                                    }
                                    
                                    Toggle("최근 3년 금융소득종합과세 대상", isOn: $vm.hasComprehensiveTax)
                                        .tint(.imMint)
                                }
                                .padding(18)
                                .glassmorphicCard()
                                .padding(.horizontal)

                                Button {
                                    vm.diagnose()
                                } label: {
                                    if vm.isLoading {
                                        ProgressView()
                                            .tint(.primary)
                                    } else {
                                        Text("자격 진단하기")
                                    }
                                }
                                .buttonStyle(GlassmorphicButtonStyle())
                                .disabled(vm.isLoading)
                                .padding(.horizontal)

                                if let error = vm.errorMessage {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top, 10)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
            .navigationTitle("자격진단")
            .onChange(of: vm.result) { newResult in
                if let res = newResult {
                    withAnimation {
                        appState.saveDiagnosisResult(response: res)
                    }
                }
            }
            // QR 코드 렌더링 모달 오버레이
            .overlay {
                if isShowingQRModal {
                    QRCodeShareModal(urlString: shareURL, isPresented: $isShowingQRModal)
                        .transition(.opacity)
                }
            }
        }
    }
    
    // 모바일용 행원 리포트 HTML 주소 구성
    private var shareURL: String {
        let baseUrlString = "http://127.0.0.1:8000"
        let rawType = vm.incomeType.rawValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let query = "is_resident=\(vm.isResident)&age=\(vm.age)&had_income_last_year=\(vm.hadIncomeLastYear)&income_type=\(rawType)&has_comprehensive_tax=\(vm.hasComprehensiveTax)&search_queries=ISA%EB%B9%84%EA%B3%BC%EC%84%B8,IRP%EA%B0%80%EC%9E%85&clicked_policies=ISA%EB%B9%84%EA%B3%BC%EC%84%B8%ED%95%9C%EB%8F%84%EC%95%88%EB%82%B4&chat_count=3"
        return "\(baseUrlString)/banker/report?\(query)"
    }
}

// 행원 창구 연동을 위한 네이티브 QR 코드 팝업 모달
struct QRCodeShareModal: View {
    let urlString: String
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("행원 상담용 QR 코드")
                    .font(.headline.bold())
                    
                Text("iM뱅크 창구 방문 시 행원에게 아래 QR 코드를 제시해 주세요. 고객님의 상담 심사 지원 리포트로 연결됩니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // 네이티브 QR 코드 이미지 생성 및 표기
                if let qrImage = generateQRCode(from: urlString) {
                    Image(uiImage: qrImage)
                        .interpolation(.none) // 레티나 선명도 유지
                        .resizable()
                        .frame(width: 200, height: 200)
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.08), radius: 8)
                } else {
                    Text("QR 코드 인쇄 실패")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                
                Text("iM FinBuddy 심사 연계 서비스")
                    .font(.caption2.bold())
                    .foregroundStyle(Color.imMint)
            }
            .padding(24)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
            )
            .shadow(radius: 20)
            .padding(.horizontal, 36)
        }
    }
    
    // CoreImage 활용 네이티브 QR 코드 생성
    private func generateQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel") // Medium 오차복구
        
        guard let ciImage = filter.outputImage else { return nil }
        
        // 이미지 스케일 확대 처리
        let transform = CGAffineTransform(scaleX: 8, y: 8)
        let scaledCIImage = ciImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    EligibilityView()
        .environmentObject(AppState())
}
