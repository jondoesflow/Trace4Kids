import SwiftUI

struct HowToView: View {
    @Environment(\.dismiss) private var dismiss

    private let steps: [(icon: String, title: String, text: String)] = [
        ("photo.on.rectangle.angled", "Pick a picture",
         "Choose a picture from your photos. A cartoon or a picture with clear shapes is easiest."),
        ("books.vertical.fill", "Set up your stand",
         "Ask a grown-up to prop the screen up over your paper, about a ruler's height above it, on a stand or a pile of books. The camera on the back should look down at the paper."),
        ("hand.draw.fill", "Fit the picture",
         "Slide See-through until you can see your paper and the picture together. Drag to move the picture and pinch to change its size."),
        ("viewfinder", "Mark the corners",
         "Draw a small dot on your paper under each pink corner. Then tap Lock so the picture stays still."),
        ("pencil.tip", "Trace!",
         "Look at the screen and draw over the picture's lines on your paper. Tap Lines to see just the outlines."),
        ("arrow.uturn.backward.circle.fill", "Come back later",
         "Your picture is saved. Tap Keep tracing, then move the picture until the pink corners sit on your dots again."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 16) {
                            ZStack {
                                Circle().fill(Theme.accent).frame(width: 52, height: 52)
                                Image(systemName: step.icon)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(index + 1). \(step.title)")
                                    .font(.title3.weight(.heavy))
                                Text(step.text)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Theme.ink.opacity(0.75))
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("No stand?", systemImage: "lightbulb.fill")
                            .font(.headline)
                        Text("Turn on Light box, lay thin paper on the screen and trace gently with a crayon or soft pencil. Ask a grown-up first.")
                        Label("Tip for grown-ups", systemImage: "info.circle.fill")
                            .font(.headline)
                            .padding(.top, 6)
                        Text("Turn on Rotation Lock in Control Centre so the picture doesn't turn when the device lies flat.")
                    }
                    .font(.body.weight(.medium))
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
                }
                .foregroundStyle(Theme.ink)
                .padding(24)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("How to trace")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.headline)
                }
            }
        }
    }
}
