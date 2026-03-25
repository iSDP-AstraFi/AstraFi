// OnboardingComponents.swift
import SwiftUI
import PhotosUI

// MARK: - Step Badge
struct StepBadge: View {
    let current: Int
    let total: Int
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentGradient)
                    .frame(width: 36, height: 36)
                Text("\(current)").font(.headline).fontWeight(.bold).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.title3).fontWeight(.bold).foregroundStyle(.primary)
                Text("Step \(current) of \(total)").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(1...total, id: \.self) { i in
                    Capsule()
                        .fill(i == current ? AppTheme.primaryGreen : Color.tableBorder)
                        .frame(width: i == current ? 18 : 6, height: 6)
                        .animation(.spring(response: 0.4), value: current)
                }
            }
        }
    }
}

// MARK: - Form Card
struct FormCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(
            color: AppTheme.adaptiveShadow,
            radius: 8,
            x: 0,
            y: 2
        )
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }
}

// MARK: - Card Header
struct CardHeader: View {
    let icon: String
    let title: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.subheadline).fontWeight(.semibold).foregroundStyle(AppTheme.primaryGreen)
            Text(title).font(.subheadline).fontWeight(.semibold).foregroundStyle(.primary)
        }
    }
}

// MARK: - Native Field
struct NativeField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.footnote).foregroundStyle(.primary).tracking(0.4)
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .font(.body)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color.tableHeaderBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

// MARK: - Stepper Label
struct StepperLabel: View {
    let label: String
    let count: Int
    var body: some View {
        HStack(spacing: 0) {
            Text(label).font(.subheadline).foregroundStyle(.primary)
            Spacer()
            Text("\(count)").font(.headline).fontWeight(.bold).foregroundStyle(AppTheme.primaryTeal).frame(minWidth: 28, alignment: .trailing).padding(.trailing, 8)
        }
    }
}

// MARK: - Hint
struct Hint: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.caption).foregroundStyle(.secondary).lineSpacing(3)
    }
}

// MARK: - Divider
struct CustomDivider: View {
    var body: some View {
        Divider().padding(.vertical, 2)
    }
}

// MARK: - Single Nav Footer
struct SingleNavFooter: View {
    let isLast: Bool
    var completeText: String = "Complete"
    var nextText: String = "Next"
    let onNext: () -> Void
    
    var body: some View {
        Button(action: onNext) {
            Text(isLast ? completeText : nextText)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.accentGradient)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Upload Drop Zone
struct UploadDropZone: View {
    let fileName: String?
    var placeholderText: String = "Tap to upload PDF or CSV"
    var supportText: String = "Supports: PDF, CSV, Excel"
    var changeFileText: String = "Tap to change file"
    var action: (() -> Void)? = nil

    @State private var isPressed = false

    private let green = AppTheme.primaryGreen

    var body: some View {
        Button {
            action?()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        green.opacity(isPressed ? 0.8 : 0.4),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(green.opacity(isPressed ? 0.10 : 0.05))
                    )
                    .frame(height: 110)

                VStack(spacing: 8) {
                    Image(systemName: fileName == nil ? "arrow.down.doc.fill" : "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(green.opacity(0.75))

                    Text(fileName == nil ? placeholderText : fileName!)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(green.opacity(0.85))

                    Text(fileName == nil ? supportText : changeFileText)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        ._onButtonGesture(pressing: { isPressed = $0 }, perform: {})
    }
}

// MARK: - Or Divider
struct OrDivider: View {
    var text: String = "or"
    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color.tableBorder).frame(height: 1)
            Text(text).font(.footnote).fontWeight(.medium).foregroundStyle(.secondary).padding(.horizontal, 4)
            Rectangle().fill(Color.tableBorder).frame(height: 1)
        }
        .padding(.horizontal, 24).padding(.vertical, 6)
    }
}

// MARK: - Empty Hints
struct EmptyRowHint: View {
    var text: String = "Tap + to add your first investment"
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle").font(.caption).foregroundStyle(.secondary)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
    }
}

struct LoanEmptyHint: View {
    var text: String = "Tap + to add a loan"
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle").font(.caption).foregroundStyle(.secondary)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
    }
}

struct InsuranceEmptyHint: View {
    var text: String = "Tap + to add a policy"
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle").font(.caption).foregroundStyle(.secondary)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
    }
}

// MARK: - Summary Tile
struct SummaryTile: View {
    let label: String; let value: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(color)
            Text(value).font(.subheadline).fontWeight(.bold).foregroundStyle(.primary)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section Label
struct SectionLabel: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title).font(.caption).fontWeight(.bold).foregroundStyle(.secondary).textCase(.uppercase).tracking(1.0).padding(.bottom, 2)
    }
}

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    let title: String
    var buttonText: String = "Done"
    var pickerLabel: String = "Select Date"
    @Binding var selection: Date
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(pickerLabel, selection: $selection, displayedComponents: .date).datePickerStyle(.wheel).labelsHidden().padding()
                Spacer()
            }
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(buttonText) { dismiss() } } }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = ""
        @State private var date = Date()
        
        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    StepBadge(current: 1, total: 4, title: "Basic Details")
                    
                    FormCard {
                        CardHeader(icon: "person.fill", title: "Personal Info")
                        NativeField(label: "Full Name", placeholder: "e.g. Rahul Sharma", text: $text)
                        CustomDivider()
                        StepperLabel(label: "Adult dependents", count: 2)
                        Hint("This is a hint for the user.")
                    }
                    
                    OrDivider()
                    
                    FormCard {
                        UploadDropZone(fileName: nil)
                        UploadDropZone(fileName: "statement.pdf")
                    }
                    
                    FormCard {
                        HStack(spacing: 0) {
                            SummaryTile(label: "Total Cover", value: "₹50L", icon: "shield.fill", color: .green)
                            SummaryTile(label: "Policies", value: "3", icon: "doc.text.fill", color: .blue)
                        }
                    }
                    
                    SingleNavFooter(isLast: false, onNext: {})
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    return PreviewWrapper()
}
