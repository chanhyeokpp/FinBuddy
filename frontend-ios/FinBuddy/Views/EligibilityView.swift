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
    
    // 단계별 대화형 질문용 상태 변수
    @State private var currentStep = 1

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
                            // 3. 프로필 입력 화면 (단계별 대화형 질문 카드 구조)
                            VStack(spacing: 20) {
                                // A. 상단 단계별 프로그레스 및 이전 버튼
                                VStack(spacing: 8) {
                                    ProgressView(value: Double(currentStep), total: 5.0)
                                        .tint(Color.imMint)
                                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                                        .padding(.horizontal)
                                    
                                    HStack {
                                        if currentStep > 1 {
                                            Button {
                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                    // Q5에서 소득이 없었던 경우 Q3로 즉시 백래시 처리
                                                    if currentStep == 5 && !vm.hadIncomeLastYear {
                                                        currentStep = 3
                                                    } else {
                                                        currentStep -= 1
                                                    }
                                                }
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "arrow.left")
                                                        .font(.system(size: 11, weight: .bold))
                                                    Text("이전 질문")
                                                        .font(.system(size: 11, weight: .bold))
                                                }
                                                .foregroundStyle(Color.imMint)
                                            }
                                        } else {
                                            Spacer().frame(width: 50)
                                        }
                                        Spacer()
                                        Text("질문 \(currentStep) / 5")
                                            .font(.caption.bold())
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.top, 10)
                                
                                // B. 똑디 캐릭터 가이드 메세지
                                HStack(spacing: 12) {
                                    Image("onboarding_diagnose")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 44, height: 44)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.imMint.opacity(0.4), lineWidth: 1.5))
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("똑디의 자격진단 인터뷰")
                                            .font(.caption.bold())
                                            .foregroundStyle(Color.imMint)
                                        Text(guideMessageForStep(currentStep))
                                            .font(.system(size: 13))
                                            .foregroundStyle(.primary)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer()
                                }
                                .padding(14)
                                .glassmorphicCard()
                                .padding(.horizontal)
                                
                                // C. 대화형 질문 카드 렌더링
                                ZStack {
                                    if currentStep == 1 {
                                        questionCard(
                                            title: "한국 거주자이신가요? 🇰🇷",
                                            subtitle: "국내에 주소를 두거나 183일 이상 거소(체류)하고 계신지 확인합니다."
                                        ) {
                                            VStack(spacing: 12) {
                                                optionButton(title: "👍 네, 거주 중입니다.", isSelected: vm.isResident) {
                                                    vm.isResident = true
                                                    nextStep()
                                                }
                                                optionButton(title: "👎 아니요, 비거주자입니다.", isSelected: !vm.isResident) {
                                                    vm.isResident = false
                                                    nextStep()
                                                }
                                            }
                                        }
                                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                                    } else if currentStep == 2 {
                                        questionCard(
                                            title: "현재 만 나이를 알려주세요 🎂",
                                            subtitle: "비과세 계좌 가입에 적합한 연령 요건을 판별합니다."
                                        ) {
                                            VStack(spacing: 20) {
                                                Text("\(vm.age) 세")
                                                    .font(.system(size: 40, weight: .black))
                                                    .foregroundStyle(Color.imMint)
                                                
                                                Stepper("", value: $vm.age, in: 15...100)
                                                    .labelsHidden()
                                                    .scaleEffect(1.2)
                                                
                                                Button {
                                                    nextStep()
                                                } label: {
                                                    Text("나이 입력 완료")
                                                        .font(.subheadline.bold())
                                                        .foregroundStyle(.white)
                                                        .padding(.vertical, 12)
                                                        .frame(maxWidth: .infinity)
                                                        .background(Color.imMint)
                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                }
                                                .padding(.top, 10)
                                            }
                                        }
                                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                                    } else if currentStep == 3 {
                                        questionCard(
                                            title: "작년에 소득이 있으셨나요? 💰",
                                            subtitle: "세액공제 한도 및 자격 요건의 기준이 됩니다."
                                        ) {
                                            VStack(spacing: 12) {
                                                optionButton(title: "🙋‍♂️ 네, 소득이 있었습니다.", isSelected: vm.hadIncomeLastYear) {
                                                    vm.hadIncomeLastYear = true
                                                    nextStep()
                                                }
                                                optionButton(title: "🙅‍♂️ 아니요, 없었습니다.", isSelected: !vm.hadIncomeLastYear) {
                                                    vm.hadIncomeLastYear = false
                                                    // 소득이 없으면 소득유형을 .none 으로 고정하고 Q5로 바로 건너뜀
                                                    vm.incomeType = .none
                                                    currentStep = 5
                                                }
                                            }
                                        }
                                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                                    } else if currentStep == 4 {
                                        questionCard(
                                            title: "소득 유형을 선택해주세요 💼",
                                            subtitle: "직장 유형에 따른 정확한 절세 요건이 계산됩니다."
                                        ) {
                                            VStack(spacing: 10) {
                                                ForEach(IncomeType.allCases, id: \.self) { type in
                                                    // '소득 없음'은 Q3에서 걸렀으므로 제외
                                                    if type != .none {
                                                        optionButton(title: type.rawValue, isSelected: vm.incomeType == type) {
                                                            vm.incomeType = type
                                                            nextStep()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                                    } else if currentStep == 5 {
                                        questionCard(
                                            title: "금융소득종합과세 대상인가요? 📊",
                                            subtitle: "최근 3년 중 한 번이라도 연간 금융 소득(이자/배당)이 2천만 원을 초과했나요?"
                                        ) {
                                            VStack(spacing: 12) {
                                                optionButton(title: "⚠️ 네, 해당됩니다.", isSelected: vm.hasComprehensiveTax) {
                                                    vm.hasComprehensiveTax = true
                                                    triggerDiagnosis()
                                                }
                                                optionButton(title: "✅ 아니요, 해당되지 않습니다.", isSelected: !vm.hasComprehensiveTax) {
                                                    vm.hasComprehensiveTax = false
                                                    triggerDiagnosis()
                                                }
                                            }
                                        }
                                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                                    }
                                }
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
    
    // 똑디 가이드 메시지 분기
    private func guideMessageForStep(_ step: Int) -> String {
        switch step {
        case 1:
            return "안녕하세요! 절세를 위해 고객님이 국내 거주 상태인지 똑 부러지게 확인해 드릴게요."
        case 2:
            return "만 나이에 따라서 가입할 수 있는 상품과 혜택 한도가 달라진답니다."
        case 3:
            return "지난해 소득이 있으셨다면 연금저축 한도 혜택을 더 크게 받으실 수 있어요."
        case 4:
            return "직장인과 개인 사업자 등 소득 방식에 맞춰 서류 제출 기준을 맞출게요."
        case 5:
            return "종합과세 여부는 비과세 혜택을 받기 위한 최종적인 체크 리스트입니다!"
        default:
            return "자격 요건 분석을 마칠게요."
        }
    }
    
    // 다음 질문 카드 이동
    private func nextStep() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            currentStep += 1
        }
    }
    
    // 자격진단 개시
    private func triggerDiagnosis() {
        withAnimation {
            vm.diagnose()
        }
    }
    
    // 질문지 전용 프레임 카드
    private func questionCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Divider()
            
            content()
        }
        .padding(18)
        .glassmorphicCard()
    }
    
    // 비주얼 예/아니오 선택 옵션 버튼
    private func optionButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(isSelected ? Color.imMint : .primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.imMint)
                } else {
                    Circle()
                        .stroke(Color.secondary.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? Color.imMint.opacity(0.08) : Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.imMint : Color.white.opacity(0.4), lineWidth: 1.5)
            )
        }
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
