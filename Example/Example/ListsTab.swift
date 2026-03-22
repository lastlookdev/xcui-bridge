import SwiftUI

struct ListsTab: View {
    @State private var items = (0..<20).map { "Item \($0)" }
    @State private var showSheet = false
    @State private var showAlert = false
    @State private var showConfirmation = false
    @State private var alertMessage = ""
    @State private var selectedItem: String?
    @State private var contextMenuResult = ""

    var body: some View {
        NavigationStack {
            List {
                navigationSection
                sheetAlertSection
                contextMenuSection
                scrollSection
                listItemsSection
            }
            .navigationTitle("Lists")
            .accessibilityIdentifier("lists_view")
            .sheet(isPresented: $showSheet) {
                sheetContent
            }
            .alert("Alert Title", isPresented: $showAlert) {
                Button("OK") { alertMessage = "Alert dismissed" }
                    .accessibilityIdentifier("alert_ok")
                Button("Cancel", role: .cancel) {}
                    .accessibilityIdentifier("alert_cancel")
            } message: {
                Text("This is an alert message for testing.")
            }
            .confirmationDialog("Confirm Action", isPresented: $showConfirmation) {
                Button("Delete", role: .destructive) {
                    alertMessage = "Deleted"
                }
                .accessibilityIdentifier("confirm_delete")
                Button("Cancel", role: .cancel) {}
                    .accessibilityIdentifier("confirm_cancel")
            } message: {
                Text("Are you sure?")
            }
        }
    }

    // MARK: - Navigation

    private var navigationSection: some View {
        Section("Navigation") {
            NavigationLink("Detail View") {
                DetailView()
            }
            .accessibilityIdentifier("nav_link_detail")

            NavigationLink("Settings") {
                SettingsView()
            }
            .accessibilityIdentifier("nav_link_settings")
        }
    }

    // MARK: - Sheets & Alerts

    private var sheetAlertSection: some View {
        Section("Sheets & Alerts") {
            Button("Show Sheet") {
                showSheet = true
            }
            .accessibilityIdentifier("button_show_sheet")

            Button("Show Alert") {
                showAlert = true
            }
            .accessibilityIdentifier("button_show_alert")

            Button("Show Confirmation") {
                showConfirmation = true
            }
            .accessibilityIdentifier("button_show_confirmation")

            if !alertMessage.isEmpty {
                Text(alertMessage)
                    .font(.caption)
                    .accessibilityIdentifier("alert_result")
            }
        }
    }

    // MARK: - Context Menu

    private var contextMenuSection: some View {
        Section("Context Menus") {
            Text("Long press for menu")
                .contextMenu {
                    Button {
                        contextMenuResult = "Copied"
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .accessibilityIdentifier("context_copy")

                    Button {
                        contextMenuResult = "Shared"
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("context_share")

                    Button(role: .destructive) {
                        contextMenuResult = "Deleted"
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .accessibilityIdentifier("context_delete")
                }
                .accessibilityIdentifier("context_menu_target")

            if !contextMenuResult.isEmpty {
                Text("Result: \(contextMenuResult)")
                    .font(.caption)
                    .accessibilityIdentifier("context_menu_result")
            }
        }
    }

    // MARK: - Scroll Content

    private var scrollSection: some View {
        Section("Scroll Content") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<10) { i in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 100, height: 60)
                            .overlay(Text("Card \(i)"))
                            .accessibilityIdentifier("scroll_card_\(i)")
                    }
                }
                .padding(.horizontal, 4)
            }
            .accessibilityIdentifier("horizontal_scroll")
        }
    }

    // MARK: - List Items

    private var listItemsSection: some View {
        Section("List Items") {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack {
                    Text(item)
                    Spacer()
                    if selectedItem == item {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedItem = item
                }
                .contextMenu {
                    Button {
                        selectedItem = item
                    } label: {
                        Label("Select", systemImage: "checkmark.circle")
                    }
                    Button(role: .destructive) {
                        items.removeAll { $0 == item }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .accessibilityIdentifier("list_item_\(index)")
            }
            .onDelete { offsets in
                items.remove(atOffsets: offsets)
            }

            Text("Total: \(items.count) items")
                .font(.caption)
                .accessibilityIdentifier("list_count")
        }
    }

    // MARK: - Sheet Content

    private var sheetContent: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Sheet Content")
                    .font(.title)
                    .accessibilityIdentifier("sheet_title")

                Text("This is a modal sheet for testing.")
                    .accessibilityIdentifier("sheet_body")

                Button("Dismiss") {
                    showSheet = false
                }
                .accessibilityIdentifier("sheet_dismiss")
            }
            .padding()
            .navigationTitle("Modal Sheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showSheet = false
                    }
                    .accessibilityIdentifier("sheet_done")
                }
            }
        }
        .accessibilityIdentifier("sheet_content")
    }
}

// MARK: - Detail View

struct DetailView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Detail View")
                .font(.largeTitle)
                .accessibilityIdentifier("detail_title")

            Text("This is a navigation destination for testing navigation links and the back button.")
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("detail_body")

            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)
                .accessibilityIdentifier("detail_image")
        }
        .padding()
        .navigationTitle("Detail")
        .accessibilityIdentifier("detail_view")
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @State private var notificationsOn = true
    @State private var darkMode = false

    var body: some View {
        Form {
            Toggle("Notifications", isOn: $notificationsOn)
                .accessibilityIdentifier("settings_notifications")

            Toggle("Dark Mode", isOn: $darkMode)
                .accessibilityIdentifier("settings_dark_mode")
        }
        .navigationTitle("Settings")
        .accessibilityIdentifier("settings_view")
    }
}
