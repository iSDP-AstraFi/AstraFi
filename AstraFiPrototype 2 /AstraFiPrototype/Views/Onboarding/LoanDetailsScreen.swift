import SwiftUI
import Charts
internal import UniformTypeIdentifiers

struct LoanDetailsScreen: View {
    @Bindable var data: CompleteAssessmentData
    @State private var goNext      = false
    @State private var showRBIInfo  = false
    @State private var showFilePicker = false
    @State private var uploadedFileName: String? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    StepBadge(current: 3, total: 4, title: "Loan Details")
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)

                    // ── Upload Document (just below Add Loan) ───────────────
                    FormCard {
                        CardHeader(icon: "doc.badge.arrow.up.fill", title: "Upload Loan Document")
                        Text("We'll use it to import all loan details securely and reduce manual work.")
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
                                    .fill(AppTheme.primaryGreen.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "banknote.fill")
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
                                    data.loanEntries.append(AssessmentLoanEntry())
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

                    // ── Loan Entries ─────────────────────────────────────
                    if data.loanEntries.isEmpty {
                        FormCard {
                            LoanEmptyHint()
                        }
                    } else {
                        ForEach($data.loanEntries) { $entry in
                            FormCard {
                                _LoanRow(
                                    entry: $entry,
                                    onRemove: {
                                        if let index = data.loanEntries.firstIndex(where: { $0.id == entry.id }) {
                                            data.loanEntries.remove(at: index)
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
        .navigationTitle("Financial Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $goNext) {
            InsuranceDetailsScreen(data: data)
        }
        .sheet(isPresented: $showRBIInfo) {
            _RBISheet()
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

// MARK: - Loan Row (Full Detail Form)

private struct _LoanRow: View {
    @Binding var entry: AssessmentLoanEntry
    var onRemove: () -> Void

    @State private var showStartDatePicker = false
    @State private var showEMIDatePicker   = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Row Header ──────────────────────────────────────────────
            HStack {
                Text("Loan Details")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primaryGreen)

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

            // ──────────────────────────────────────────────────────────
            // SECTION 1 — Loan Type / Bank / Principal
            // ──────────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 14) {

                // Loan Type Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Loan Type")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(AppTheme.primaryGreen.opacity(0.12))
                                .frame(width: 30, height: 30)
                            Image(systemName: "banknote.fill")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.primaryGreen)
                        }

                        Picker("Loan Type", selection: $entry.type) {
                            ForEach(AssessmentLoanEntry.LoanType.allCases, id: \.self) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .tint(AppTheme.primaryGreen)

                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                // Bank / Lender Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bank / Lender")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Select the financial institution that provided this loan.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(AppTheme.primaryGreen.opacity(0.12))
                                .frame(width: 30, height: 30)
                            Image(systemName: "building.columns.fill")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.primaryGreen)
                        }

                        Picker("Bank", selection: $entry.bank) {
                            Text("Select Bank").tag("")
                            Text("SBI").tag("SBI")
                            Text("HDFC Bank").tag("HDFC Bank")
                            Text("ICICI Bank").tag("ICICI Bank")
                            Text("Axis Bank").tag("Axis Bank")
                            Text("Kotak Mahindra").tag("Kotak Mahindra")
                            Text("PNB").tag("PNB")
                            Text("Bank of Baroda").tag("Bank of Baroda")
                            Text("Yes Bank").tag("Yes Bank")
                            Text("Other").tag("Other")
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .tint(AppTheme.primaryGreen)

                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                // Principal Amount
                NativeField(
                    label: "Principal Amount (₹)",
                    placeholder: "e.g. 2500000",
                    text: $entry.amount,
                    keyboard: .numberPad
                )
            }

            _LoanSectionDivider(title: "INTEREST & TENURE")

            VStack(alignment: .leading, spacing: 14) {

                // Interest Rate + Tenure in 2 columns
                HStack(spacing: 12) {
                    NativeField(
                        label: "Interest Rate (%)",
                        placeholder: "e.g. 8.5",
                        text: $entry.interestRate,
                        keyboard: .decimalPad
                    )
                    NativeField(
                        label: "Tenure (Years)",
                        placeholder: "e.g. 20",
                        text: $entry.timePeriod,
                        keyboard: .numberPad
                    )
                }

                // Interest Type + Frequency in 2 columns
                HStack(spacing: 12) {
                    _PickerField(label: "Interest Type") {
                        Picker("Interest Type", selection: $entry.interestType) {
                            ForEach(AstraInterestType.allCases, id: \.self) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppTheme.primaryGreen)
                    }
                    _PickerField(label: "Frequency") {
                        Picker("Frequency", selection: $entry.compoundingFrequency) {
                            ForEach(AstraCompoundingFrequency.allCases, id: \.self) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppTheme.primaryGreen)
                    }
                }

                // Installments Already Paid
                NativeField(
                    label: "Installments Already Paid (EMIs)",
                    placeholder: "e.g. 24",
                    text: $entry.installmentsPaid,
                    keyboard: .numberPad
                )

                Text("Remaining tenure will be automatically calculated.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            _LoanSectionDivider(title: "EMI DETAILS")

            // ──────────────────────────────────────────────────────────
            // SECTION 3 — EMI Details
            // ──────────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 14) {

                // EMI Amount + EMI Frequency
                HStack(spacing: 12) {
                    NativeField(
                        label: "EMI Amount (₹)",
                        placeholder: "Optional",
                        text: $entry.emiAmount,
                        keyboard: .numberPad
                    )
                    _PickerField(label: "EMI Frequency") {
                        Picker("EMI Frequency", selection: $entry.emiFrequency) {
                            ForEach(AstraEMIFrequency.allCases, id: \.self) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppTheme.primaryGreen)
                    }
                }

                // Loan Start Date + First EMI Date
                HStack(spacing: 12) {
                    _DateButtonField(
                        label: "Loan Start Date",
                        date: $entry.startDate,
                        showPicker: $showStartDatePicker
                    )
                    _DateButtonField(
                        label: "First EMI Date",
                        date: $entry.firstEMIDate,
                        showPicker: $showEMIDatePicker
                    )
                }
            }

            _LoanSectionDivider(title: "RATES & PREPAYMENT")

            // ──────────────────────────────────────────────────────────
            // SECTION 4 — Rates & Prepayment
            // ──────────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 14) {

                // Floating Interest Rate Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Floating Interest Rate")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Toggle("", isOn: $entry.isFloatingRate)
                        .labelsHidden()
                        .tint(.green)
                }

                // Prepayment Penalty
                NativeField(
                    label: "Prepayment Penalty (%)",
                    placeholder: "e.g. 2.0",
                    text: $entry.prepaymentPenalty,
                    keyboard: .decimalPad
                )
            }

            _LoanSectionDivider(title: "CHARGES & HIDDEN COSTS")

            // ──────────────────────────────────────────────────────────
            // SECTION 5 — Charges & Hidden Costs
            // ──────────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 14) {

                HStack(spacing: 12) {
                    NativeField(
                        label: "Processing Fee (₹)",
                        placeholder: "0",
                        text: $entry.processingFee,
                        keyboard: .numberPad
                    )
                    NativeField(
                        label: "Insurance Cost (₹)",
                        placeholder: "0",
                        text: $entry.insuranceCost,
                        keyboard: .numberPad
                    )
                }

                HStack(spacing: 12) {
                    NativeField(
                        label: "Late Penalty (₹)",
                        placeholder: "0",
                        text: $entry.latePaymentPenalty,
                        keyboard: .numberPad
                    )
                    NativeField(
                        label: "Other Charges (₹)",
                        placeholder: "0",
                        text: $entry.otherCharges,
                        keyboard: .numberPad
                    )
                }
            }

            _LoanSectionDivider(title: "ADVANCED OPTIONS")

            // ──────────────────────────────────────────────────────────
            // SECTION 6 — Advanced Options
            // ──────────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 14) {

                // Moratorium Period
                NativeField(
                    label: "Moratorium Period (Months)",
                    placeholder: "e.g. 6",
                    text: $entry.moratoriumDuration,
                    keyboard: .numberPad
                )

                // Track Tax Benefits Toggle
                HStack {
                    Text("Track Tax Benefits (80C / Sec 24)")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Toggle("", isOn: $entry.trackTaxBenefits)
                        .labelsHidden()
                        .tint(.green)
                }
            }
        }
        // Date pickers presented as sheets
        .sheet(isPresented: $showStartDatePicker) {
            DatePickerSheet(title: "Loan Start Date", selection: $entry.startDate)
        }
        .sheet(isPresented: $showEMIDatePicker) {
            DatePickerSheet(title: "First EMI Date", selection: $entry.firstEMIDate)
        }
    }
}

// MARK: - Helper: Section Divider with Title
private struct _LoanSectionDivider: View {
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .padding(.vertical, 16)
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .tracking(1.0)
                .padding(.bottom, 14)
        }
    }
}

// MARK: - Helper: Picker Field (uniform height with text fields)
private struct _PickerField<Content: View>: View {
    let label: String
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

// MARK: - Helper: Date Button Field
private struct _DateButtonField: View {
    let label: String
    @Binding var date: Date
    @Binding var showPicker: Bool

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.primary)
                .tracking(0.4)
            Button {
                showPicker = true
            } label: {
                Text(Self.dateFormatter.string(from: date))
                    .font(.body)
                    .foregroundStyle(AppTheme.primaryGreen)
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

// MARK: - RBI Sheet
private struct _RBISheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .padding(.top, 40)

                Text("Secure RBI Sync")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("AstraFi connects through Account Aggregator to fetch read-only bank data. No credentials stored.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 30)

                Spacer()

                Button("Proceed to Auth (Demo)") {
                    dismiss()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
