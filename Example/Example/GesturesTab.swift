import SwiftUI

struct GesturesTab: View {
    @State private var longPressCount = 0
    @State private var doubleTapCount = 0
    @State private var pinchScale: CGFloat = 1.0
    @State private var dragItems = ["Drag A", "Drag B", "Drag C", "Drag D", "Drag E"]
    @State private var lastGesture = "None"

    var body: some View {
        NavigationStack {
            Form {
                longPressSection
                doubleTapSection
                pinchSection
                dragSection
                gestureStatusSection
            }
            .navigationTitle("Gestures")
            .accessibilityIdentifier("gestures_scroll")
        }
    }

    // MARK: - Long Press

    private var longPressSection: some View {
        Section("Long Press") {
            Text("Long press the box below")
                .font(.caption)

            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.4))
                .frame(height: 80)
                .overlay(
                    Text("Long Press Here")
                        .font(.headline)
                )
                .onLongPressGesture(minimumDuration: 0.5) {
                    longPressCount += 1
                    lastGesture = "Long Press"
                }
                .accessibilityIdentifier("long_press_area")

            Text("Long press count: \(longPressCount)")
                .accessibilityIdentifier("long_press_count")
        }
    }

    // MARK: - Double Tap

    private var doubleTapSection: some View {
        Section("Double Tap") {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.4))
                .frame(height: 80)
                .overlay(
                    Text("Double Tap Here")
                        .font(.headline)
                )
                .onTapGesture(count: 2) {
                    doubleTapCount += 1
                    lastGesture = "Double Tap"
                }
                .accessibilityIdentifier("double_tap_area")

            Text("Double tap count: \(doubleTapCount)")
                .accessibilityIdentifier("double_tap_count")
        }
    }

    // MARK: - Pinch

    private var pinchSection: some View {
        Section("Pinch / Zoom") {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.3))
                .frame(height: 120)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .scaleEffect(pinchScale)
                )
                .accessibilityIdentifier("pinch_area")

            Text("Scale: \(String(format: "%.1f", pinchScale))x")
                .accessibilityIdentifier("pinch_scale")

            HStack {
                Button("Reset") {
                    pinchScale = 1.0
                    lastGesture = "Pinch"
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("pinch_reset")

                Button("Zoom In") {
                    pinchScale = min(pinchScale + 0.5, 5.0)
                    lastGesture = "Pinch"
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("pinch_zoom_in")

                Button("Zoom Out") {
                    pinchScale = max(pinchScale - 0.5, 0.5)
                    lastGesture = "Pinch"
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("pinch_zoom_out")
            }
        }
    }

    // MARK: - Drag & Drop Reorderable List

    private var dragSection: some View {
        Section("Drag & Reorder") {
            ForEach(Array(dragItems.enumerated()), id: \.element) { index, item in
                HStack {
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.secondary)
                    Text(item)
                    Spacer()
                    Text("#\(index)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("drag_item_\(index)")
            }
            .onMove { source, destination in
                dragItems.move(fromOffsets: source, toOffset: destination)
                lastGesture = "Drag Reorder"
            }

            Text("Order: \(dragItems.joined(separator: ", "))")
                .font(.caption)
                .accessibilityIdentifier("drag_order")
        }
    }

    // MARK: - Status

    private var gestureStatusSection: some View {
        Section("Gesture Status") {
            Text("Last gesture: \(lastGesture)")
                .accessibilityIdentifier("gesture_status")
        }
    }
}
