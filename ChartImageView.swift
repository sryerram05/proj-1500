import SwiftUI

#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
#else
import UIKit
typealias PlatformImage = UIImage
#endif


struct ChartImageView: View {
    let imageName: String
    var tapToZoomWholeImage: Bool = true

    @State private var isZoomedViewPresented = false

    var body: some View {
        if let platformImage = Self.loadImage(named: imageName) {
            if tapToZoomWholeImage {
                Button {
                    isZoomedViewPresented = true
                } label: {
                    imageContent(platformImage)
                }
                .buttonStyle(.plain)
                .modifier(ZoomPresentation(platformImage: platformImage, isPresented: $isZoomedViewPresented))
            } else {
                imageContent(platformImage, zoomIconIsButton: true)
                    .modifier(ZoomPresentation(platformImage: platformImage, isPresented: $isZoomedViewPresented))
            }
        } else {
 
            HStack {
                Image(systemName: "photo")
                Text("Chart image \"\(imageName)\" not found in bundle")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }


    @ViewBuilder
    private func imageContent(_ platformImage: PlatformImage, zoomIconIsButton: Bool = false) -> some View {
        platformImage.swiftUIImage
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.gray.opacity(0.25), lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if zoomIconIsButton {
                    Button {
                        isZoomedViewPresented = true
                    } label: {
                        zoomIcon
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                } else {
                    zoomIcon
                        .padding(8)
                }
            }
    }

    private var zoomIcon: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.caption)
            .padding(6)
            .background(.ultraThinMaterial, in: Circle())
    }

    private static func loadImage(named name: String) -> PlatformImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return PlatformImage(data: data)
    }
}


private struct ZoomPresentation: ViewModifier {
    let platformImage: PlatformImage
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        #if os(iOS)
        content.fullScreenCover(isPresented: $isPresented) {
            ChartZoomView(platformImage: platformImage)
        }
        #else
        content.sheet(isPresented: $isPresented) {
            ChartZoomView(platformImage: platformImage)
                .frame(minWidth: 640, minHeight: 520)
        }
        #endif
    }
}

private extension PlatformImage {
    var swiftUIImage: Image {
        #if os(macOS)
        Image(nsImage: self)
        #else
        Image(uiImage: self)
        #endif
    }
}


struct ChartZoomView: View {
    let platformImage: PlatformImage

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZoomableImage(image: platformImage.swiftUIImage)
                .background(Color.black)
                .navigationTitle("Chart")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Text("Pinch or double-tap to zoom, drag to pan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                }
        }
    }
}


struct ZoomableImage: View {
    let image: Image

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1
    private let maxScale: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(magnificationGesture)
                .simultaneousGesture(dragGesture)
                .onTapGesture(count: 2, perform: toggleZoom)
                .clipped()
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, minScale), maxScale)
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= minScale {
                    resetZoom()
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > minScale else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func toggleZoom() {
        withAnimation {
            if scale > minScale {
                resetZoom()
            } else {
                scale = 2.5
                lastScale = 2.5
            }
        }
    }

    private func resetZoom() {
        withAnimation {
            scale = minScale
            lastScale = minScale
            offset = .zero
            lastOffset = .zero
        }
    }
}

