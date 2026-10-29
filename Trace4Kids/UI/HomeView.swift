import PhotosUI
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var pickerItem: PhotosPickerItem?
    @State private var showsHowTo = false

    var body: some View {
        ZStack {
            Theme.homeBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    header

                    if let picture = model.picture {
                        continueCard(picture)
                    }

                    // The system photo picker shows only the pictures in this device's photo library,
                    // and needs no permission. Nothing is downloaded from the internet.
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        BigButtonLabel(title: model.hasSavedTracing ? "Pick a new picture" : "Pick a picture",
                                       systemImage: "photo.on.rectangle.angled")
                    }
                    .accessibilityIdentifier("pickPicture")

                    if model.isDemo, let sample = AppModel.samplePicture {
                        Button { model.start(with: sample) } label: {
                            BigButtonLabel(title: "Try the sample picture", systemImage: "star.fill", color: Theme.purple)
                        }
                        .accessibilityIdentifier("samplePicture")
                    }

                    Button { showsHowTo = true } label: {
                        Label("How to trace", systemImage: "questionmark.circle.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .accessibilityIdentifier("howTo")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }

            if model.isOpeningPicture {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView("Opening picture…")
                    .padding(24)
                    .background(.white, in: RoundedRectangle(cornerRadius: 20))
            }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                await model.open(item)
                pickerItem = nil
            }
        }
        .sheet(isPresented: $showsHowTo) { HowToView() }
        .alert("Oops", isPresented: Binding(get: { model.errorMessage != nil },
                                            set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.white)
                    .frame(width: 104, height: 104)
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            Text("Trace4Kids")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text("Copy any picture onto paper")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.ink.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 6)
    }

    private func continueCard(_ picture: UIImage) -> some View {
        Button { model.resume() } label: {
            HStack(spacing: 16) {
                Image(uiImage: picture)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keep tracing")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.ink)
                    Text("Your picture is right where you left it")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.ink.opacity(0.65))
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.accent)
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("keepTracing")
    }
}
