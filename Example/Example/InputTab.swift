import SwiftUI

struct InputTab: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var notes = ""
    @State private var searchText = ""
    @State private var selectedColor = "Red"
    @State private var selectedSize = "Medium"
    @State private var selectedDate = Date()

    private let colors = ["Red", "Green", "Blue", "Yellow", "Purple"]
    private let sizes = ["Small", "Medium", "Large", "X-Large"]

    var body: some View {
        NavigationStack {
            Form {
                textFieldsSection
                secureFieldSection
                textEditorSection
                pickersSection
                datePickerSection
            }
            .navigationTitle("Input")
            .accessibilityIdentifier("input_scroll")
        }
    }

    // MARK: - Text Fields

    private var textFieldsSection: some View {
        Section("Text Fields") {
            TextField("Name", text: $name)
                .textContentType(.name)
                .accessibilityIdentifier("textfield_name")

            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .accessibilityIdentifier("textfield_email")

            TextField("Search", text: $searchText)
                .accessibilityIdentifier("textfield_search")

            if !name.isEmpty || !email.isEmpty {
                Text("Name: \(name), Email: \(email)")
                    .font(.caption)
                    .accessibilityIdentifier("textfield_output")
            }
        }
    }

    // MARK: - Secure Field

    private var secureFieldSection: some View {
        Section("Secure Field") {
            SecureField("Password", text: $password)
                .textContentType(.password)
                .accessibilityIdentifier("securefield_password")

            Text("Password length: \(password.count)")
                .font(.caption)
                .accessibilityIdentifier("password_length")
        }
    }

    // MARK: - Text Editor

    private var textEditorSection: some View {
        Section("Notes") {
            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .accessibilityIdentifier("texteditor_notes")

            Text("Characters: \(notes.count)")
                .font(.caption)
                .accessibilityIdentifier("notes_char_count")
        }
    }

    // MARK: - Pickers

    private var pickersSection: some View {
        Section("Pickers") {
            Picker("Color", selection: $selectedColor) {
                ForEach(colors, id: \.self) { color in
                    Text(color).tag(color)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            .accessibilityIdentifier("picker_color")

            Text("Selected color: \(selectedColor)")
                .accessibilityIdentifier("picker_color_value")

            Picker("Size", selection: $selectedSize) {
                ForEach(sizes, id: \.self) { size in
                    Text(size).tag(size)
                }
            }
            .accessibilityIdentifier("picker_size")

            Text("Selected size: \(selectedSize)")
                .accessibilityIdentifier("picker_size_value")
        }
    }

    // MARK: - Date Picker

    private var datePickerSection: some View {
        Section("Date Picker") {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .accessibilityIdentifier("datepicker_date")

            DatePicker(
                "Select Time",
                selection: $selectedDate,
                displayedComponents: [.hourAndMinute]
            )
            .accessibilityIdentifier("datepicker_time")

            Text("Selected: \(selectedDate.formatted())")
                .font(.caption)
                .accessibilityIdentifier("datepicker_value")
        }
    }
}
