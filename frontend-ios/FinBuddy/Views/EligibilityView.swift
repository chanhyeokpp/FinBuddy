import SwiftUI
import Combine
import CoreImage
import AVFoundation

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
    
    // 다국어 지원 상태 변수
    @State private var selectedLanguage: String = "ko"
    
    // TTS 음성 합성기
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    // 음성 발화 Helper
    private func speakText(_ text: String, lang: String) {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        let localeMap = ["ko": "ko-KR", "en": "en-US", "zh": "zh-CN", "vi": "vi-VN"]
        let locale = localeMap[lang] ?? "ko-KR"
        utterance.voice = AVSpeechSynthesisVoice(language: locale)
        utterance.rate = 0.5
        speechSynthesizer.speak(utterance)
    }
    
    private func getTranslation(step: Int, lang: String) -> (title: String, subtitle: String, guide: String) {
        switch lang {
        case "en":
            switch step {
            case 1:
                return (
                    title: "Are you a resident of Korea? 🇰🇷",
                    subtitle: "Confirm if you have an address or have resided in Korea for 183 days or more.",
                    guide: "Hello! I will clearly verify if you reside in Korea to qualify for tax savings."
                )
            case 2:
                return (
                    title: "Please select your international age 🎂",
                    subtitle: "We determine the appropriate age requirements for tax-free accounts.",
                    guide: "Depending on your international age, the products you can join and their benefit limits vary."
                )
            case 3:
                return (
                    title: "Did you have taxable income last year? 💰",
                    subtitle: "We check if you had wage or business income in the previous taxable period.",
                    guide: "If you had income last year, you can receive larger benefits for retirement savings."
                )
            case 4:
                return (
                    title: "What is your type of income? 💼",
                    subtitle: "Select your primary source of domestic income.",
                    guide: "We will align the document submission criteria to your income type (wage earner or business owner)."
                )
            case 5:
                return (
                    title: "Was your global income under 38M KRW? 📊",
                    subtitle: "This determines if you qualify for the special taxpayer category.",
                    guide: "Global taxation status is the final checklist for receiving tax-free benefits!"
                )
            default:
                return (title: "", subtitle: "", guide: "")
            }
            
        case "zh":
            switch step {
            case 1:
                return (
                    title: "您是韩国居民吗？ 🇰🇷",
                    subtitle: "确认您在韩国是否有住所或已居住183天以上。",
                    guide: "您好！为了帮您节省税款，我会帮您确认您是否属于韩国居民身份。"
                )
            case 2:
                return (
                    title: "请输入您当前的实际年龄 🎂",
                    subtitle: "判定您是否符合免税账户的年龄要求。",
                    guide: "根据您的实际年龄，您可以加入的金融产品和优惠限额也会有所不同。"
                )
            case 3:
                return (
                    title: "您在上一纳税期有收入吗？ 💰",
                    subtitle: "确认您在上一纳税期是否有工资或营业收入。",
                    guide: "如果您去年有收入，您的养老储蓄账户可以获得更大的税收优惠。"
                )
            case 4:
                return (
                    title: "您的收入类型是什么？ 💼",
                    subtitle: "选择您在韩国国内的主要收入来源。",
                    guide: "我们将根据您的收入类型（上班族或个体工商户）来对应调整您需要提交的材料标准。"
                )
            case 5:
                return (
                    title: "您上一年度的综合所得是否在3800万韩元以下？ 📊",
                    subtitle: "确认您是否属于平民型免税额度对象。",
                    guide: "综合所得税申报情况是享受免税优惠的最终确认清单！"
                )
            default:
                return (title: "", subtitle: "", guide: "")
            }
            
        case "vi":
            switch step {
            case 1:
                return (
                    title: "Bạn có phải cư dân Hàn Quốc không? 🇰🇷",
                    subtitle: "Xác nhận xem bạn có địa chỉ hoặc đã cư trú tại HQ từ 183 ngày trở lên không.",
                    guide: "Xin chào! Tôi sẽ kiểm tra chính xác tình trạng cư trú tại Hàn Quốc để giúp bạn được giảm thuế."
                )
            case 2:
                return (
                    title: "Vui lòng cho biết tuổi quốc tế hiện tại 🎂",
                    subtitle: "Xác định xem bạn có đủ điều kiện về độ tuổi để mở tài khoản miễn thuế không.",
                    guide: "Tùy thuộc vào độ tuổi quốc tế của bạn, các sản phẩm và hạn mức ưu đãi có thể tham gia sẽ khác nhau."
                )
            case 3:
                return (
                    title: "Bạn có thu nhập trong kỳ tính thuế trước không? 💰",
                    subtitle: "Kiểm tra xem bạn có thu nhập từ tiền lương hoặc kinh doanh trong năm ngoái không.",
                    guide: "Nếu bạn có thu nhập vào năm ngoái, bạn có thể nhận được ưu đãi hạn mức tích lũy hưu trí lớn hơn."
                )
            case 4:
                return (
                    title: "Hình thức thu nhập của bạn là gì? 💼",
                    subtitle: "Chọn nguồn thu nhập chính của bạn tại Hàn Quốc.",
                    guide: "Chúng tôi sẽ căn chỉnh tiêu chí nộp tài liệu theo hình thức thu nhập của bạn (nhân viên văn phòng hoặc hộ kinh doanh)."
                )
            case 5:
                return (
                    title: "Thu nhập tổng hợp trước đó có từ 38 triệu KRW trở xuống? 📊",
                    subtitle: "Xác nhận xem bạn có đủ điều kiện áp dụng hạn mức miễn thuế phổ thông hay không.",
                    guide: "Tình trạng thuế tổng hợp là danh mục kiểm tra cuối cùng để nhận ưu đãi miễn thuế!"
                )
            default:
                return (title: "", subtitle: "", guide: "")
            }
            
        default: // "ko"
            switch step {
            case 1:
                return (
                    title: "한국 거주자이신가요? 🇰🇷",
                    subtitle: "국내에 주소를 두거나 183일 이상 거소(체류)하고 계신지 확인합니다.",
                    guide: "안녕하세요! 절세를 위해 고객님이 국내 거주 상태인지 똑 부러지게 확인해 드릴게요."
                )
            case 2:
                return (
                    title: "현재 만 나이를 알려주세요 🎂",
                    subtitle: "비과세 계좌 가입에 적합한 연령 요건을 판별합니다.",
                    guide: "만 나이에 따라서 가입할 수 있는 상품과 혜택 한도가 달라진답니다."
                )
            case 3:
                return (
                    title: "직전 과세기간에 소득이 있으셨나요? 💰",
                    subtitle: "지난해 근로 소득이나 사업 소득이 발생했는지 체크합니다.",
                    guide: "지난해 소득이 있으셨다면 연금저축 한도 혜택을 더 크게 받으실 수 있어요."
                )
            case 4:
                return (
                    title: "소득 형태가 어떻게 되시나요? 💼",
                    subtitle: "국내에서 발생하는 주된 소득 형태를 선택해 주세요.",
                    guide: "직장인과 개인 사업자 등 소득 방식에 맞춰 서류 제출 기준을 맞출게요."
                )
            case 5:
                return (
                    title: "직전 종합소득금액이 3,800만원 이하이신가요? 📊",
                    subtitle: "비과세 한도를 늘려주는 '서민형 가입' 자격 요건을 판별합니다.",
                    guide: "종합과세 여부는 비과세 혜택을 받기 위한 최종적인 체크 리스트입니다!"
                )
            default:
                return (title: "", subtitle: "", guide: "")
            }
        }
    }
    
    @ViewBuilder
    private func flagButton(flag: String, langCode: String) -> some View {
        Button {
            selectedLanguage = langCode
            let text = getTranslation(step: currentStep, lang: langCode).guide
            speakText(text, lang: langCode)
        } label: {
            Text(flag)
                .font(.system(size: 15))
                .padding(4)
                .background(selectedLanguage == langCode ? Color.imMint.opacity(0.18) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
    
    private func getOptionText(step: Int, optionIndex: Int, lang: String) -> String {
        switch step {
        case 1:
            if optionIndex == 0 {
                return lang == "ko" ? "👍 네, 거주 중입니다." : (lang == "en" ? "👍 Yes, I reside here." : (lang == "zh" ? "👍 是的，我在此居住。" : "👍 Vâng, tôi cư trú ở đây."))
            } else {
                return lang == "ko" ? "👎 아니요, 비거주자입니다." : (lang == "en" ? "👎 No, I do not reside here." : (lang == "zh" ? "👎 不，我不在此居住。" : "👎 Không, tôi không cư trú ở đây."))
            }
        case 2:
            return lang == "ko" ? "나이 입력 완료" : (lang == "en" ? "Done Entering Age" : (lang == "zh" ? "完成输入年龄" : "Hoàn thành nhập tuổi"))
        case 3:
            if optionIndex == 0 {
                return lang == "ko" ? "🙋‍♂️ 네, 소득이 있었습니다." : (lang == "en" ? "🙋‍♂️ Yes, I had income." : (lang == "zh" ? "🙋‍♂️ 是的，我有收入。" : "🙋‍♂️ Có, tôi có thu nhập."))
            } else {
                return lang == "ko" ? "🙅‍♂️ 아니요, 없었습니다." : (lang == "en" ? "🙅‍♂️ No, I did not." : (lang == "zh" ? "🙅‍♂️ 不，我没有。" : "🙅‍♂️ Không, tôi không có."))
            }
        case 5:
            if optionIndex == 0 {
                return lang == "ko" ? "⚠️ 네, 해당됩니다." : (lang == "en" ? "⚠️ Yes, applicable." : (lang == "zh" ? "⚠️ 是的，适用。" : "⚠️ Có, áp dụng."))
            } else {
                return lang == "ko" ? "✅ 아니요, 해당되지 않습니다." : (lang == "en" ? "✅ No, not applicable." : (lang == "zh" ? "✅ 不，不适用。" : "✅ Không, không 적용."))
            }
        default:
            return ""
        }
    }
    
    private func getIncomeTypeText(type: IncomeType, lang: String) -> String {
        switch type {
        case .employed:
            return lang == "ko" ? "🏢 근로 소득 (직장인)" : (lang == "en" ? "🏢 Earned Income (Employee)" : (lang == "zh" ? "🏢 工资收入 (上班族)" : "🏢 Thu nhập lương (Nhân viên)"))
        case .selfEmployed:
            return lang == "ko" ? "💼 사업 소득 (프리랜서/개인사업자)" : (lang == "en" ? "💼 Business Income (Freelancer/Self-employed)" : (lang == "zh" ? "💼 营业收入 (自由职业者/个体户)" : "💼 Thu nhập kinh doanh (Hộ kinh doanh)"))
        case .none:
            return ""
        }
    }
    
    private func getAgeLabel(age: Int, lang: String) -> String {
        let suffix = lang == "ko" ? "세" : (lang == "en" ? "years" : (lang == "zh" ? "岁" : "tuổi"))
        return "\(age) \(suffix)"
    }
    
    private func getScannerButtonText(lang: String) -> String {
        return lang == "ko" ? "신분증(외국인등록증) 스캔으로 자동 입력" : (lang == "en" ? "Scan ID card to autofill in 3s" : (lang == "zh" ? "扫描身份证自动填写" : "Quét thẻ căn cước tự động nhập"))
    }
    
    // 아코디언 상태 보관
    @State private var expandedProducts: Set<String> = []
    
    // QR 모달 표시 여부 State
    @State private var isShowingQRModal = false
    
    // 단계별 대화형 질문용 상태 변수
    @State private var currentStep = 1
    
    // OCR 신분증 스캔 모달 플래그
    @State private var isShowingOCRScanner = false

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
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        HStack {
                                            Text("똑디의 자격진단 인터뷰")
                                                .font(.caption.bold())
                                                .foregroundStyle(Color.imMint)
                                            
                                            Spacer()
                                            
                                            // 다국어 선택 국기 버튼 행
                                            HStack(spacing: 6) {
                                                flagButton(flag: "🇰🇷", langCode: "ko")
                                                flagButton(flag: "🇺🇸", langCode: "en")
                                                flagButton(flag: "🇨🇳", langCode: "zh")
                                                flagButton(flag: "🇻🇳", langCode: "vi")
                                            }
                                        }
                                        
                                        HStack(alignment: .bottom, spacing: 8) {
                                            Text(getTranslation(step: currentStep, lang: selectedLanguage).guide)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundStyle(.primary)
                                                .lineLimit(3)
                                                .fixedSize(horizontal: false, vertical: true)
                                            
                                            Spacer()
                                            
                                            Button {
                                                let text = getTranslation(step: currentStep, lang: selectedLanguage).guide
                                                speakText(text, lang: selectedLanguage)
                                            } label: {
                                                Image(systemName: "speaker.wave.2.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(Color.imMint)
                                                    .padding(6)
                                                    .background(Color.imMint.opacity(0.12))
                                                    .clipShape(Circle())
                                            }
                                        }
                                    }
                                }
                                .padding(12)
                                .glassmorphicCard()
                                .padding(.horizontal)
                                
                                // C. 대화형 질문 카드 렌더링
                                ZStack {
                                    if currentStep == 1 {
                                        questionCard(
                                            title: getTranslation(step: 1, lang: selectedLanguage).title,
                                            subtitle: getTranslation(step: 1, lang: selectedLanguage).subtitle
                                        ) {
                                            VStack(spacing: 12) {
                                                // OCR 신분증 스캔 퀵 버튼 배치
                                                Button {
                                                    isShowingOCRScanner = true
                                                } label: {
                                                    HStack(spacing: 8) {
                                                        Image(systemName: "camera.viewfinder")
                                                            .font(.system(size: 13, weight: .bold))
                                                        Text(getScannerButtonText(lang: selectedLanguage))
                                                            .font(.system(size: 11, weight: .bold))
                                                    }
                                                    .foregroundStyle(Color.white)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(Color.imMintLimeGradient)
                                                    .clipShape(Capsule())
                                                    .shadow(color: Color.imMint.opacity(0.3), radius: 4, y: 2)
                                                }
                                                .padding(.bottom, 6)
                                                
                                                optionButton(
                                                    title: getOptionText(step: 1, optionIndex: 0, lang: selectedLanguage),
                                                    isSelected: vm.isResident
                                                ) {
                                                    vm.isResident = true
                                                    nextStep()
                                                }
                                                optionButton(
                                                    title: getOptionText(step: 1, optionIndex: 1, lang: selectedLanguage),
                                                    isSelected: !vm.isResident
                                                ) {
                                                    vm.isResident = false
                                                    nextStep()
                                                }
                                            }
                                        }
                                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                                    } else if currentStep == 2 {
                                        questionCard(
                                            title: getTranslation(step: 2, lang: selectedLanguage).title,
                                            subtitle: getTranslation(step: 2, lang: selectedLanguage).subtitle
                                        ) {
                                            VStack(spacing: 20) {
                                                Text(getAgeLabel(age: vm.age, lang: selectedLanguage))
                                                    .font(.system(size: 40, weight: .black))
                                                    .foregroundStyle(Color.imMint)
                                                
                                                Stepper("", value: $vm.age, in: 15...100)
                                                    .labelsHidden()
                                                    .scaleEffect(1.2)
                                                
                                                Button {
                                                    nextStep()
                                                } label: {
                                                    Text(getOptionText(step: 2, optionIndex: 0, lang: selectedLanguage))
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
                                            title: getTranslation(step: 3, lang: selectedLanguage).title,
                                            subtitle: getTranslation(step: 3, lang: selectedLanguage).subtitle
                                        ) {
                                            VStack(spacing: 12) {
                                                optionButton(
                                                    title: getOptionText(step: 3, optionIndex: 0, lang: selectedLanguage),
                                                    isSelected: vm.hadIncomeLastYear
                                                ) {
                                                    vm.hadIncomeLastYear = true
                                                    nextStep()
                                                }
                                                optionButton(
                                                    title: getOptionText(step: 3, optionIndex: 1, lang: selectedLanguage),
                                                    isSelected: !vm.hadIncomeLastYear
                                                ) {
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
                                            title: getTranslation(step: 4, lang: selectedLanguage).title,
                                            subtitle: getTranslation(step: 4, lang: selectedLanguage).subtitle
                                        ) {
                                            VStack(spacing: 10) {
                                                ForEach(IncomeType.allCases, id: \.self) { type in
                                                    if type != .none {
                                                        let titleText = getIncomeTypeText(type: type, lang: selectedLanguage)
                                                        optionButton(title: titleText, isSelected: vm.incomeType == type) {
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
                                            title: getTranslation(step: 5, lang: selectedLanguage).title,
                                            subtitle: getTranslation(step: 5, lang: selectedLanguage).subtitle
                                        ) {
                                            VStack(spacing: 12) {
                                                optionButton(
                                                    title: getOptionText(step: 5, optionIndex: 0, lang: selectedLanguage),
                                                    isSelected: vm.hasComprehensiveTax
                                                ) {
                                                    vm.hasComprehensiveTax = true
                                                    triggerDiagnosis()
                                                }
                                                optionButton(
                                                    title: getOptionText(step: 5, optionIndex: 1, lang: selectedLanguage),
                                                    isSelected: !vm.hasComprehensiveTax
                                                ) {
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
            .fullScreenCover(isPresented: $isShowingOCRScanner) {
                OCRScannerView(vm: vm, currentStep: $currentStep)
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
