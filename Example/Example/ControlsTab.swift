import SwiftUI

struct ControlsTab: View {
    @State private var tapCount = 0
    @State private var wifiEnabled = true
    @State private var bluetoothEnabled = false
    @State private var airplaneMode = false
    @State private var volumeValue: Double = 0.5
    @State private var brightnessValue: Double = 0.75
    @State private var quantity = 1
    @State private var fontSize = 14
    @State private var selectedSegment = "First"
    @State private var progressValue: Double = 0.65
    @State private var isLoading = false

    private let segments = ["First", "Second", "Third"]

    var body: some View {
        NavigationStack {
            Form {
                buttonsSection
                togglesSection
                slidersSection
                steppersSection
                segmentedSection
                progressSection
                labelsSection
            }
            .navigationTitle("Controls")
            .accessibilityIdentifier("controls_scroll")
        }
    }

    // MARK: - Buttons

    private var buttonsSection: some View {
        Section("Buttons") {
            Button("Primary Action") {
                tapCount += 1
            }
            .accessibilityIdentifier("button_primary")

            Button("Destructive Action", role: .destructive) {
                tapCount = 0
            }
            .accessibilityIdentifier("button_destructive")

            Button {
                tapCount += 1
            } label: {
                Label("Star", systemImage: "star.fill")
            }
            .accessibilityIdentifier("button_icon")

            Button("Disabled Button") {}
                .disabled(true)
                .accessibilityIdentifier("button_disabled")

            Text("Tap Count: \(tapCount)")
                .accessibilityIdentifier("button_tap_count")
        }
    }

    // MARK: - Toggles

    private var togglesSection: some View {
        Section("Toggles") {
            Toggle("Wi-Fi", isOn: $wifiEnabled)
                .accessibilityIdentifier("toggle_wifi")

            Toggle("Bluetooth", isOn: $bluetoothEnabled)
                .accessibilityIdentifier("toggle_bluetooth")

            Toggle("Airplane Mode", isOn: $airplaneMode)
                .accessibilityIdentifier("toggle_airplane")

            Text(toggleStatusText)
                .font(.caption)
                .accessibilityIdentifier("toggle_status")
        }
    }

    private var toggleStatusText: String {
        var parts: [String] = []
        if wifiEnabled { parts.append("Wi-Fi") }
        if bluetoothEnabled { parts.append("Bluetooth") }
        if airplaneMode { parts.append("Airplane") }
        return parts.isEmpty ? "All off" : parts.joined(separator: ", ")
    }

    // MARK: - Sliders

    private var slidersSection: some View {
        Section("Sliders") {
            VStack(alignment: .leading) {
                Text("Volume: \(Int(volumeValue * 100))%")
                    .accessibilityIdentifier("slider_volume_label")
                Slider(value: $volumeValue, in: 0...1)
                    .accessibilityIdentifier("slider_volume")
            }

            VStack(alignment: .leading) {
                Text("Brightness: \(Int(brightnessValue * 100))%")
                    .accessibilityIdentifier("slider_brightness_label")
                Slider(value: $brightnessValue, in: 0...1)
                    .accessibilityIdentifier("slider_brightness")
            }
        }
    }

    // MARK: - Steppers

    private var steppersSection: some View {
        Section("Steppers") {
            Stepper("Quantity: \(quantity)", value: $quantity, in: 0...99)
                .accessibilityIdentifier("stepper_quantity")

            Stepper("Font Size: \(fontSize)", value: $fontSize, in: 8...72)
                .accessibilityIdentifier("stepper_font_size")
        }
    }

    // MARK: - Segmented Control

    private var segmentedSection: some View {
        Section("Segmented Control") {
            Picker("Segment", selection: $selectedSegment) {
                ForEach(segments, id: \.self) { segment in
                    Text(segment).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("segment_control")

            Text("Selected: \(selectedSegment)")
                .accessibilityIdentifier("segment_value")
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        Section("Progress") {
            VStack(alignment: .leading) {
                Text("Download: \(Int(progressValue * 100))%")
                    .accessibilityIdentifier("progress_label")
                ProgressView(value: progressValue)
                    .accessibilityIdentifier("progress_bar")
            }

            if isLoading {
                HStack {
                    ProgressView()
                        .accessibilityIdentifier("progress_spinner")
                    Text("Loading...")
                        .accessibilityIdentifier("progress_loading_text")
                }
            }

            Button(isLoading ? "Stop Loading" : "Start Loading") {
                isLoading.toggle()
            }
            .accessibilityIdentifier("button_toggle_loading")
        }
    }

    // MARK: - Labels

    private var labelsSection: some View {
        Section("Labels & Status") {
            Text("Status: Active")
                .foregroundStyle(.green)
                .accessibilityIdentifier("status_label")

            Label("Favorites", systemImage: "heart.fill")
                .accessibilityIdentifier("label_favorites")

            Label("Settings", systemImage: "gear")
                .accessibilityIdentifier("label_settings")

            HStack {
                Image(systemName: "info.circle")
                    .accessibilityIdentifier("image_info")
                Text("Version 1.0.0")
                    .accessibilityIdentifier("label_version")
            }
        }
    }
}
