import SwiftUI

enum Theme {
    static let accent = Color(red: 1.0, green: 0.48, blue: 0.0)
    static let purple = Color(red: 0.42, green: 0.36, blue: 0.95)
    /// Corner marks: bright pink so they show up on paper and on photos.
    static let mark = Color(red: 1.0, green: 0.18, blue: 0.55)
    static let ink = Color(red: 0.16, green: 0.15, blue: 0.27)

    static let homeBackground = LinearGradient(
        colors: [Color(red: 0.75, green: 0.89, blue: 1.0), Color(red: 1.0, green: 0.88, blue: 0.94)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

/// A big, colourful button label for the home screen.
struct BigButtonLabel: View {
    let title: String
    let systemImage: String
    var color: Color = Theme.accent

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .bold))
            Text(title)
                .font(.title2.weight(.bold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 76)
        .background(color, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: color.opacity(0.35), radius: 10, y: 5)
    }
}

/// A square button with an icon over a short word, used in the tracing controls.
struct ToolButton: View {
    let title: String
    let systemImage: String
    var isOn = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .frame(height: 26)
                Text(title)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isOn ? .white : Theme.ink)
            .frame(maxWidth: .infinity, minHeight: 62)
            .background(isOn ? Theme.purple : Color.white.opacity(0.9),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// A round button for the top of the tracing screen.
struct RoundButton: View {
    let systemImage: String
    let label: String
    var color: Color = .white
    var iconColor: Color = Theme.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 58, height: 58)
                .background(color, in: Circle())
                .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
