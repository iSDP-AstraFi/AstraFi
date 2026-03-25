import SwiftUI
internal import UniformTypeIdentifiers

struct InvestmentDetailsScreen: View {
    @Bindable var data: CompleteAssessmentData
    @Environment(\.dismiss) private var dismiss
    @State private var goNext        = false
    @State private var importSource: String?
    @State private var selectedFile: String?
    @State private var showFilePicker = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    StepBadge(current: 2, total: 4, title: "Investments")
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)

                    FormCard {
                        CardHeader(icon: "rays", title: "Smart Import Insights")

                        Text("Connect accounts to accurately estimate net worth and performance.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        HStack(spacing: 12) {
                            Button { importSource = "CAS" } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 26))
                                        .foregroundColor(.blue)
                                    Text("CAS Upload")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(importSource == "CAS" ? Color.blue.opacity(0.15) : Color.blue.opacity(0.06))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(importSource == "CAS" ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            }

                            Button { importSource = "MFCentral" } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "banknote.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(.green)
                                    Text("MF Central")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(importSource == "MFCentral" ? Color.green.opacity(0.15) : Color.green.opacity(0.06))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(importSource == "MFCentral" ? Color.green : Color.clear, lineWidth: 2)
                                )
                            }
                        }

                        if let src = importSource {
                            Text(src == "CAS" ? "Tap below to attach your NSDL/CDSL CAS." : "Login securely to MF Central.")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .padding(.top, 6)

                            UploadDropZone(fileName: selectedFile) {
                                showFilePicker = true
                            }
                        }
                    }

                    OrDivider()

                    // ── Manual Entry Card ──────────────────────────────
                    FormCard {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(AppTheme.primaryGreen.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "square.and.pencil")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.primaryGreen)
                            }
                            Text("Manual Entry")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Spacer()
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    data.investmentEntries.append(AssessmentInvestmentEntry())
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

                    // ── Investment Entries ─────────────────────────────
                    if data.investmentEntries.isEmpty {
                        FormCard {
                            EmptyRowHint()
                        }
                    } else {
                        ForEach($data.investmentEntries) { $entry in
                            FormCard {
                                _InvestmentRow(
                                    entry: $entry,
                                    onRemove: {
                                        if let index = data.investmentEntries.firstIndex(where: { $0.id == entry.id }) {
                                            data.investmentEntries.remove(at: index)
                                        }
                                    }
                                )
                            }
                        }
                    }

                    Spacer().frame(height: 90)
                }
            }

            SingleNavFooter(isLast: false) {
                goNext = true
            }
        }
        .navigationTitle("Investments")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
        .navigationDestination(isPresented: $goNext) {
            LoanDetailsScreen(data: data)
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf, .commaSeparatedText, .spreadsheet],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                selectedFile = url.lastPathComponent
            }
        }
    }
}

private struct _InvestmentRow: View {
    @Binding var entry: AssessmentInvestmentEntry
    var onRemove: () -> Void

    @State private var searchResults: [MFScheme] = []
    @State private var showSearch = false
    
    private let green = AppTheme.primaryGreen

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // ── Row Header ───────────────────────────────────────────
            HStack {
                Text("Investment Details")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(green)

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

            Divider()

            VStack(spacing: 16) {

                // Investment Type Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Investment Type")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(green.opacity(0.12))
                                .frame(width: 30, height: 30)
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(green)
                        }

                        Picker("Type", selection: $entry.type) {
                            ForEach(AssessmentInvestmentEntry.InvestmentType.allCases, id: \.self) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .tint(green)

                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                // Investment Mode Segmented
                VStack(alignment: .leading, spacing: 6) {
                    Text("Investment Mode")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Picker("Mode", selection: $entry.mode) {
                        ForEach(AssessmentInvestmentEntry.InvestmentMode.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 6) {
                    NativeField(
                        label: "Name / Fund",
                        placeholder: "e.g. Parag Parikh Flexi Cap",
                        text: $entry.fundName
                    )
                    .onChange(of: entry.fundName) { _, newValue in
                        if entry.type == .mutualFund && !newValue.isEmpty && entry.schemeCode == nil {
                            searchResults = MFService.shared.searchSchemes(query: newValue)
                            showSearch = !searchResults.isEmpty
                        } else {
                            showSearch = false
                        }
                    }
                    
                    if showSearch && entry.type == .mutualFund {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(searchResults) { scheme in
                                    Button {
                                        entry.fundName = scheme.name
                                        entry.schemeCode = scheme.schemeCode
                                        entry.isin = scheme.isin
                                        showSearch = false
                                    } label: {
                                        VStack(alignment: .leading) {
                                            Text(scheme.name)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            Text("NAV: ₹\(String(format: "%.2f", scheme.nav)) | \(scheme.isin)")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    Divider()
                                }
                            }
                            .padding(.horizontal, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .frame(maxHeight: 150)
                        .transition(.opacity)
                    }
                }

                NativeField(
                    label: "Invested Amount (₹)",
                    placeholder: "e.g. 50000",
                    text: $entry.amount,
                    keyboard: .numberPad
                )

                // Start Date
                VStack(alignment: .leading, spacing: 5) {
                    Text("Start Date")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    DatePicker(
                        "",
                        selection: $entry.startDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .tint(green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                // Associated Goal
                NativeField(
                    label: "Associated Goal (Optional)",
                    placeholder: "e.g. Retirement, Home Purchase",
                    text: $entry.associatedGoal
                )
            }
        }
    }
}
