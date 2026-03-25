import SwiftUI
internal import UniformTypeIdentifiers

struct InsuranceDetailsScreen: View {
    @Bindable var data: CompleteAssessmentData
    @State private var goNext           = false
    @State private var showFilePicker    = false
    @State private var uploadedFileName: String? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(.vertical) {
                VStack(spacing: 0) {

                    StepBadge(current: 4, total: 4, title: "Insurance & Protection")
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)

                    // ── Manual Entry Card (Insurance) ────────────────────
                    

                   

                    // ── Upload Document ──────────────────────────────────
                    FormCard {
                        CardHeader(icon: "doc.badge.arrow.up.fill", title: "Upload Policy Document")
                        Text("Upload your policy PDF to auto-fill coverage details and reduce manual entry.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        UploadDropZone(fileName: uploadedFileName) {
                            showFilePicker = true
                        }
                    }
                    OrDivider()
                    FormCard {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.orange.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "shield.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.orange)
                            }
                            Text("Manual Entry")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Spacer()
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    data.insuranceEntries.append(AssessmentInsuranceEntry())
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.subheadline)
                                    Text("Add")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(AppTheme.primaryGreen)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.primaryGreen.opacity(0.1))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(AppTheme.primaryGreen.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }

                    // ── Insurance Entries ────────────────────────────────
                    if data.insuranceEntries.isEmpty {
                        FormCard {
                            InsuranceEmptyHint()
                        }
                    } else {
                        ForEach($data.insuranceEntries) { $entry in
                            FormCard {
                                InsuranceAssessmentRow(
                                    entry: $entry,
                                    onRemove: {
                                        if let index = data.insuranceEntries.firstIndex(where: { $0.id == entry.id }) {
                                            data.insuranceEntries.remove(at: index)
                                        }
                                    }
                                )
                            }
                        }
                    }

                    Spacer().frame(height: 90)
                }
            }

            SingleNavFooter(isLast: true) {
                goNext = true
            }
        }
        .navigationTitle("Financial Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $goNext) {
            FinancialHealthReportView(data: data)
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf, .commaSeparatedText, .spreadsheet],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                uploadedFileName = url.lastPathComponent
            }
        }
    }
}

// MARK: - Insurance Assessment Row (Full Detail Form)

private struct InsuranceAssessmentRow: View {
    @Binding var entry: AssessmentInsuranceEntry
    var onRemove: () -> Void

    @State private var showStartPicker  = false
    @State private var showExpiryPicker = false
    @State private var hasExpiry        = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Row Header ──────────────────────────────────────────────
            HStack {
                Text("Policy Details")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.brown)
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "trash.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red.opacity(0.75))
                        .padding(8)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 14) {

                // Policy Type Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Policy Type")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .tracking(0.4)

                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.orange.opacity(0.12))
                                .frame(width: 30, height: 30)
                            Image(systemName: entry.currentType.icon)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                        }

                        Picker("Policy Type", selection: Binding(
                            get: { entry.currentType },
                            set: { entry.switchType(to: $0) }
                        )) {
                            ForEach(AssessmentInsuranceEntry.InsuranceType.allCases) { t in
                                Text(t.displayName).tag(t)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .tint(.orange)

                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                // Insurer Name
                NativeField(
                    label: "Insurer / Provider",
                    placeholder: "e.g. HDFC Life, LIC, Star Health",
                    text: $entry.insurer
                )

                // Cover Amount + Policy Number
                HStack(spacing: 12) {
                    NativeField(
                        label: "Cover Amount (₹)",
                        placeholder: "e.g. 1000000",
                        text: $entry.coverAmount,
                        keyboard: .numberPad
                    )
                    NativeField(
                        label: "Policy Number",
                        placeholder: "Optional",
                        text: $entry.policyNumber
                    )
                }

                // Annual Premium
                NativeField(
                    label: "Annual Premium (₹)",
                    placeholder: "e.g. 15000",
                    text: $entry.annualPremium,
                    keyboard: .numberPad
                )

                // Start Date
                InsDateButtonField(
                    label: "Policy Start Date",
                    date: $entry.startDate,
                    showPicker: $showStartPicker
                )

                // Expiry Date Toggle
                HStack {
                    Text("Has Expiry Date")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Toggle("", isOn: $hasExpiry)
                        .labelsHidden()
                        .tint(.orange)
                }

                if hasExpiry {
                    InsDateButtonField(
                        label: "Expiry / Maturity Date",
                        date: $entry.expiryDate,
                        showPicker: $showExpiryPicker
                    )
                }
            }

            InsSectionDivider(title: "PREMIUM BREAKDOWN")

            // ──────────────────────────────────────────────────────────
            // SECTION 2 — Premium Breakdown
            // ──────────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 14) {

                HStack(spacing: 12) {
                    NativeField(
                        label: "Base Premium (₹)",
                        placeholder: "e.g. 12000",
                        text: $entry.basePremium,
                        keyboard: .numberPad
                    )
                    NativeField(
                        label: "Taxes & GST (₹)",
                        placeholder: "e.g. 2160",
                        text: $entry.taxesGST,
                        keyboard: .numberPad
                    )
                }

                HStack(spacing: 12) {
                    NativeField(
                        label: "Add-On / Rider Cost (₹)",
                        placeholder: "0",
                        text: $entry.addOnCost,
                        keyboard: .numberPad
                    )
                    _InsSectionPickerField(label: "Payment Frequency", accentColor: .orange) {
                        Picker("Frequency", selection: $entry.premiumFrequency) {
                            ForEach(AstraPremiumFrequency.allCases, id: \.self) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.orange)
                    }
                }
            }

            // ── Conditional Type-Specific Sections ─────────────────────

            // Life / Term / ULIP
            if [.life, .term, .ulip].contains(entry.currentType) {
                InsSectionDivider(title: "LIFE INSURANCE DETAILS")

                VStack(alignment: .leading, spacing: 14) {
                    if let life = entry.details.asLife {
                        let lifeBinding = Binding<AssessmentInsuranceEntry.LifeDetails>(
                            get: { entry.details.asLife ?? LifeDetails() },
                            set: { entry.details = .life($0) }
                        )

                        NativeField(
                            label: "Nominee Name",
                            placeholder: "e.g. Priya Sharma",
                            text: lifeBinding.nomineeName
                        )

                        _InsSectionPickerField(label: "Life Insurance Type", accentColor: .orange) {
                            Picker("Type", selection: lifeBinding.lifeInsuranceType) {
                                Text("Term").tag("Term")
                                Text("Endowment").tag("Endowment")
                                Text("Whole Life").tag("Whole Life")
                                Text("Money-Back").tag("Money-Back")
                                Text("ULIP").tag("ULIP")
                            }
                            .pickerStyle(.menu)
                            .tint(.orange)
                        }

                        HStack(spacing: 12) {
                            NativeField(
                                label: "Death Benefit (₹)",
                                placeholder: "e.g. 5000000",
                                text: lifeBinding.deathBenefit,
                                keyboard: .numberPad
                            )
                            NativeField(
                                label: "Maturity Benefit (₹)",
                                placeholder: "e.g. 2000000",
                                text: lifeBinding.maturityBenefit,
                                keyboard: .numberPad
                            )
                        }
                        let _ = life // suppress unused warning
                    }
                }
            }

            // Health / Critical Illness
            if [.health, .criticalIllness].contains(entry.currentType) {
                InsSectionDivider(title: "HEALTH INSURANCE DETAILS")

                VStack(alignment: .leading, spacing: 14) {
                    let healthBinding = Binding<AssessmentInsuranceEntry.HealthDetails>(
                        get: { entry.details.asHealth ?? HealthDetails() },
                        set: { entry.details = .health($0) }
                    )

                    _InsSectionPickerField(label: "Plan Type", accentColor: .orange) {
                        Picker("Plan Type", selection: healthBinding.planType) {
                            Text("Individual").tag("Individual")
                            Text("Family Floater").tag("Family Floater")
                            Text("Senior Citizen").tag("Senior Citizen")
                            Text("Group").tag("Group")
                        }
                        .pickerStyle(.menu)
                        .tint(.orange)
                    }

                    HStack(spacing: 12) {
                        NativeField(
                            label: "Room Rent Limit (₹)",
                            placeholder: "e.g. 5000",
                            text: healthBinding.roomRentLimit,
                            keyboard: .numberPad
                        )
                        NativeField(
                            label: "Network Hospitals",
                            placeholder: "e.g. 8000",
                            text: healthBinding.networkHospitalsCount,
                            keyboard: .numberPad
                        )
                    }

                    NativeField(
                        label: "Pre/Post Hospitalization Terms",
                        placeholder: "e.g. 30/60 days",
                        text: healthBinding.prePostHospitalization
                    )

                    HStack {
                        Text("Daycare Procedures Covered")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Toggle("", isOn: healthBinding.daycareProcedures)
                            .labelsHidden()
                            .tint(.orange)
                    }
                }
            }

            // Motor
            if entry.currentType == .motor {
                InsSectionDivider(title: "MOTOR INSURANCE DETAILS")

                VStack(alignment: .leading, spacing: 14) {
                    let motorBinding = Binding<AssessmentInsuranceEntry.MotorDetails>(
                        get: { entry.details.asMotor ?? MotorDetails() },
                        set: { entry.details = .motor($0) }
                    )

                    HStack(spacing: 12) {
                        NativeField(
                            label: "Vehicle Model",
                            placeholder: "e.g. Honda City",
                            text: motorBinding.vehicleModel
                        )
                        NativeField(
                            label: "Vehicle Number",
                            placeholder: "e.g. MH12AB1234",
                            text: motorBinding.vehicleNumber
                        )
                    }

                    NativeField(
                        label: "IDV — Insured Declared Value (₹)",
                        placeholder: "e.g. 700000",
                        text: motorBinding.idv,
                        keyboard: .numberPad
                    )

                    HStack {
                        Text("Zero Depreciation Cover")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Toggle("", isOn: motorBinding.zeroDep)
                            .labelsHidden()
                            .tint(.orange)
                    }

                    HStack {
                        Text("Roadside Assistance (RSA)")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Toggle("", isOn: motorBinding.roadsideAssistance)
                            .labelsHidden()
                            .tint(.orange)
                    }
                }
            }

            // Travel
            if entry.currentType == .travel {
                InsSectionDivider(title: "TRAVEL INSURANCE DETAILS")

                VStack(alignment: .leading, spacing: 14) {
                    let travelBinding = Binding<AssessmentInsuranceEntry.TravelDetails>(
                        get: { entry.details.asTravel ?? TravelDetails() },
                        set: { entry.details = .travel($0) }
                    )

                    HStack(spacing: 12) {
                        NativeField(
                            label: "Destination",
                            placeholder: "e.g. International",
                            text: travelBinding.destination
                        )
                        NativeField(
                            label: "Trip Duration (Days)",
                            placeholder: "e.g. 14",
                            text: travelBinding.tripDurationDays,
                            keyboard: .numberPad
                        )
                    }

                    HStack {
                        Text("Medical Coverage")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Toggle("", isOn: travelBinding.coversMedical)
                            .labelsHidden()
                            .tint(.orange)
                    }

                    HStack {
                        Text("Trip Cancellation Coverage")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Toggle("", isOn: travelBinding.coversCancellation)
                            .labelsHidden()
                            .tint(.orange)
                    }
                }
            }

            // Critical Illness
            if entry.currentType == .criticalIllness {
                InsSectionDivider(title: "CRITICAL ILLNESS DETAILS")

                VStack(alignment: .leading, spacing: 14) {
                    let ciBinding = Binding<AssessmentInsuranceEntry.CriticalIllnessDetails>(
                        get: { entry.details.asCriticalIllness ?? CriticalIllnessDetails() },
                        set: { entry.details = .criticalIllness($0) }
                    )

                    NativeField(
                        label: "Illnesses Covered",
                        placeholder: "e.g. Cancer, Heart Attack, Stroke",
                        text: ciBinding.illnessesCovered
                    )
                    NativeField(
                        label: "Waiting Period (Days)",
                        placeholder: "e.g. 90",
                        text: ciBinding.waitingPeriodDays,
                        keyboard: .numberPad
                    )
                }
            }

            // ULIP
            if entry.currentType == .ulip {
                InsSectionDivider(title: "ULIP DETAILS")

                VStack(alignment: .leading, spacing: 14) {
                    let ulipBinding = Binding<AssessmentInsuranceEntry.ULIPDetails>(
                        get: { entry.details.asULIP ?? ULIPDetails() },
                        set: { entry.details = .ulip($0) }
                    )

                    HStack(spacing: 12) {
                        NativeField(
                            label: "Nominee Name",
                            placeholder: "e.g. Priya Sharma",
                            text: ulipBinding.nomineeName
                        )
                        NativeField(
                            label: "Fund Type",
                            placeholder: "e.g. Equity, Debt",
                            text: ulipBinding.fundType
                        )
                    }

                    HStack(spacing: 12) {
                        NativeField(
                            label: "Lock-In Period (Years)",
                            placeholder: "e.g. 5",
                            text: ulipBinding.lockInPeriod,
                            keyboard: .numberPad
                        )
                        NativeField(
                            label: "Surrender Value (₹)",
                            placeholder: "e.g. 50000",
                            text: ulipBinding.surrenderValue,
                            keyboard: .numberPad
                        )
                    }

                    NativeField(
                        label: "Expected Maturity Amount (₹)",
                        placeholder: "e.g. 1500000",
                        text: ulipBinding.expectedMaturityAmount,
                        keyboard: .numberPad
                    )
                }
            }

            InsSectionDivider(title: "ADVANCED (OPTIONAL)")

            VStack(alignment: .leading, spacing: 14) {

                Text("Applicable for savings-linked or investment-linked policies.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                HStack(spacing: 12) {
                    NativeField(
                        label: "Surrender Value (₹)",
                        placeholder: "Optional",
                        text: .constant(""),
                        keyboard: .numberPad
                    )
                    NativeField(
                        label: "Lock-In Period (Months)",
                        placeholder: "Optional",
                        text: .constant(""),
                        keyboard: .numberPad
                    )
                }

                NativeField(
                    label: "Expected Maturity Amount (₹)",
                    placeholder: "Optional",
                    text: .constant(""),
                    keyboard: .numberPad
                )
            }
        }
        .sheet(isPresented: $showStartPicker) {
            DatePickerSheet(title: "Policy Start Date", selection: $entry.startDate)
        }
        .sheet(isPresented: $showExpiryPicker) {
            DatePickerSheet(title: "Expiry / Maturity Date", selection: $entry.expiryDate)
        }
    }
}


private typealias LifeDetails             = AssessmentInsuranceEntry.LifeDetails
private typealias HealthDetails           = AssessmentInsuranceEntry.HealthDetails
private typealias MotorDetails            = AssessmentInsuranceEntry.MotorDetails
private typealias TravelDetails           = AssessmentInsuranceEntry.TravelDetails
private typealias CriticalIllnessDetails  = AssessmentInsuranceEntry.CriticalIllnessDetails
private typealias ULIPDetails             = AssessmentInsuranceEntry.ULIPDetails

private struct InsSectionDivider: View {
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider().padding(.vertical, 16)
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .tracking(1.0)
                .padding(.bottom, 14)
        }
    }
}

private struct _InsSectionPickerField<Content: View>: View {
    let label: String
    var accentColor: Color = .orange
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.primary)
                .tracking(0.4)
            HStack {
                content
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct InsDateButtonField: View {
    let label: String
    @Binding var date: Date
    @Binding var showPicker: Bool

    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.primary)
                .tracking(0.4)
            Button { showPicker = true } label: {
                Text(Self.fmt.string(from: date))
                    .font(.body)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity)
    }
}
