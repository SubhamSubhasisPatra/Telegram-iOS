import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftUI

// MARK: - SwiftUI Glass View (iOS 17+)

@available(iOS 17.0, *)
private struct LiquidGlassView: View {
    let cornerRadius: CGFloat
    let rimIntensity: CGFloat
    let innerGlowIntensity: CGFloat
    let chromaticOffset: CGFloat

    @State private var animationPhase: CGFloat = 0

    init(
        cornerRadius: CGFloat = 20.0,
        rimIntensity: CGFloat = 0.4,
        innerGlowIntensity: CGFloat = 0.3,
        chromaticOffset: CGFloat = 0.5
    ) {
        self.cornerRadius = cornerRadius
        self.rimIntensity = rimIntensity
        self.innerGlowIntensity = innerGlowIntensity
        self.chromaticOffset = chromaticOffset
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base glass material
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Chromatic aberration simulation - subtle color fringing
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.red.opacity(0.05 * chromaticOffset),
                                Color.clear,
                                Color.blue.opacity(0.05 * chromaticOffset)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: 1)

                // Rim highlight - top-left bright edge
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6 * rimIntensity),
                                Color.white.opacity(0.2 * rimIntensity),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )

                // Inner rim - subtle inner stroke
                RoundedRectangle(cornerRadius: cornerRadius - 1, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25 * rimIntensity),
                                Color.white.opacity(0.05 * rimIntensity),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .center
                        ),
                        lineWidth: 0.5
                    )
                    .padding(1)

                // Inner glow - radial gradient from center
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.08 * innerGlowIntensity),
                        Color.white.opacity(0.02 * innerGlowIntensity),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.7
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

                // Fresnel-like edge brightening
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.03)
                            ],
                            center: .center,
                            startRadius: min(geometry.size.width, geometry.size.height) * 0.3,
                            endRadius: max(geometry.size.width, geometry.size.height) * 0.6
                        )
                    )

                // Animated subtle refraction simulation
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.02 * (1 + Darwin.sin(Double(animationPhase)) * 0.5)),
                                Color.clear,
                                Color.white.opacity(0.02 * (1 + Darwin.cos(Double(animationPhase)) * 0.5))
                            ],
                            startPoint: UnitPoint(
                                x: 0.3 + Darwin.sin(Double(animationPhase) * 0.5) * 0.2,
                                y: 0.2 + Darwin.cos(Double(animationPhase) * 0.7) * 0.1
                            ),
                            endPoint: UnitPoint(
                                x: 0.7 + Darwin.cos(Double(animationPhase) * 0.3) * 0.2,
                                y: 0.8 + Darwin.sin(Double(animationPhase) * 0.4) * 0.1
                            )
                        )
                    )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                animationPhase = .pi * 2
            }
        }
    }
}

// MARK: - SwiftUI Hosting Wrapper for iOS 17+

@available(iOS 17.0, *)
private final class LiquidGlassHostingView: UIView {
    private var hostingController: UIHostingController<LiquidGlassView>?

    var glassCornerRadius: CGFloat = 20.0 {
        didSet {
            updateGlassView()
        }
    }

    var rimIntensity: CGFloat = 0.4 {
        didSet {
            updateGlassView()
        }
    }

    var innerGlowIntensity: CGFloat = 0.3 {
        didSet {
            updateGlassView()
        }
    }

    var chromaticOffset: CGFloat = 0.5 {
        didSet {
            updateGlassView()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupGlassView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupGlassView() {
        let glassView = LiquidGlassView(
            cornerRadius: glassCornerRadius,
            rimIntensity: rimIntensity,
            innerGlowIntensity: innerGlowIntensity,
            chromaticOffset: chromaticOffset
        )
        let hostingController = UIHostingController(rootView: glassView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.frame = bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(hostingController.view)
        self.hostingController = hostingController
    }

    private func updateGlassView() {
        hostingController?.rootView = LiquidGlassView(
            cornerRadius: glassCornerRadius,
            rimIntensity: rimIntensity,
            innerGlowIntensity: innerGlowIntensity,
            chromaticOffset: chromaticOffset
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        hostingController?.view.frame = bounds
    }
}

// MARK: - Glass Effect Layer (Fallback)

private final class GlassRefractionLayer: CALayer {

    var glassCornerRadius: CGFloat = 25.0 {
        didSet {
            self.cornerRadius = glassCornerRadius
            setNeedsDisplay()
        }
    }

    override init() {
        super.init()
        self.needsDisplayOnBoundsChange = true
        self.drawsAsynchronously = true
    }

    override init(layer: Any) {
        super.init(layer: layer)
        if let other = layer as? GlassRefractionLayer {
            self.glassCornerRadius = other.glassCornerRadius
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Glass Background View (UIKit Fallback for iOS < 17)

public final class TabBarGlassBackgroundView: UIView {

    // Glass effect components
    private let blurEffectView: UIVisualEffectView
    private let vibrancyEffectView: UIVisualEffectView
    private let tintOverlayView: UIView
    private let rimHighlightLayer: CAGradientLayer
    private let innerHighlightLayer: CAGradientLayer
    private let innerGlowLayer: CAGradientLayer

    public var glassCornerRadius: CGFloat = 0.0 {
        didSet {
            updateCornerRadius()
        }
    }

    public var tintStrength: CGFloat = 0.5 {
        didSet {
            updateTintOverlay()
        }
    }

    public var isDarkMode: Bool = false {
        didSet {
            updateBlurEffect()
            updateTintOverlay()
        }
    }

    public override init(frame: CGRect) {
        // Create blur effect
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        self.blurEffectView = UIVisualEffectView(effect: blurEffect)

        // Create vibrancy effect for content
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect, style: .fill)
        self.vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)

        // Create tint overlay for glass color
        self.tintOverlayView = UIView()

        // Create rim highlight layer (top-left to bottom-right gradient stroke)
        self.rimHighlightLayer = CAGradientLayer()

        // Create inner highlight layer (top edge glow)
        self.innerHighlightLayer = CAGradientLayer()

        // Create inner glow layer (center brightness)
        self.innerGlowLayer = CAGradientLayer()

        super.init(frame: frame)

        self.isUserInteractionEnabled = false
        self.backgroundColor = .clear

        setupLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayers() {
        // Add blur effect view as base
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurEffectView)

        // Add vibrancy inside blur
        vibrancyEffectView.frame = blurEffectView.contentView.bounds
        vibrancyEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.contentView.addSubview(vibrancyEffectView)

        // Add tint overlay
        tintOverlayView.frame = bounds
        tintOverlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(tintOverlayView)

        // Setup rim highlight
        rimHighlightLayer.colors = [
            UIColor.white.withAlphaComponent(0.6).cgColor,
            UIColor.white.withAlphaComponent(0.1).cgColor,
            UIColor.white.withAlphaComponent(0.3).cgColor
        ]
        rimHighlightLayer.locations = [0.0, 0.5, 1.0]
        rimHighlightLayer.startPoint = CGPoint(x: 0, y: 0)
        rimHighlightLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(rimHighlightLayer)

        // Setup inner highlight (top edge)
        innerHighlightLayer.colors = [
            UIColor.white.withAlphaComponent(0.25).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor
        ]
        innerHighlightLayer.locations = [0.0, 1.0]
        innerHighlightLayer.startPoint = CGPoint(x: 0.5, y: 0)
        innerHighlightLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(innerHighlightLayer)

        // Setup inner glow (radial from center)
        innerGlowLayer.type = .radial
        innerGlowLayer.colors = [
            UIColor.white.withAlphaComponent(0.08).cgColor,
            UIColor.white.withAlphaComponent(0.02).cgColor,
            UIColor.clear.cgColor
        ]
        innerGlowLayer.locations = [0.0, 0.5, 1.0]
        innerGlowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        innerGlowLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        layer.addSublayer(innerGlowLayer)

        updateTintOverlay()
    }

    private func updateBlurEffect() {
        let style: UIBlurEffect.Style = isDarkMode ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
        let blurEffect = UIBlurEffect(style: style)
        blurEffectView.effect = blurEffect

        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect, style: .fill)
        vibrancyEffectView.effect = vibrancyEffect
    }

    private func updateTintOverlay() {
        let baseColor = isDarkMode
            ? UIColor(white: 0.15, alpha: 0.3 * tintStrength)
            : UIColor(red: 0.94, green: 0.96, blue: 1.0, alpha: 0.15 * tintStrength)
        tintOverlayView.backgroundColor = baseColor
    }

    private func updateCornerRadius() {
        layer.cornerRadius = glassCornerRadius
        layer.masksToBounds = true

        blurEffectView.layer.cornerRadius = glassCornerRadius
        blurEffectView.layer.masksToBounds = true

        tintOverlayView.layer.cornerRadius = glassCornerRadius
        tintOverlayView.layer.masksToBounds = true

        rimHighlightLayer.cornerRadius = glassCornerRadius
        innerHighlightLayer.cornerRadius = glassCornerRadius
        innerGlowLayer.cornerRadius = glassCornerRadius
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let bounds = self.bounds

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Update rim highlight as a border stroke
        let rimInset: CGFloat = 0.5
        rimHighlightLayer.frame = bounds.insetBy(dx: rimInset, dy: rimInset)

        // Create stroke mask for rim highlight
        let rimPath = UIBezierPath(roundedRect: rimHighlightLayer.bounds, cornerRadius: max(0, glassCornerRadius - rimInset))
        let rimInnerPath = UIBezierPath(roundedRect: rimHighlightLayer.bounds.insetBy(dx: 1.5, dy: 1.5), cornerRadius: max(0, glassCornerRadius - rimInset - 1.5))
        rimPath.append(rimInnerPath.reversing())

        let rimMask = CAShapeLayer()
        rimMask.path = rimPath.cgPath
        rimMask.fillRule = .evenOdd
        rimHighlightLayer.mask = rimMask

        // Update inner highlight (top portion only)
        let innerHighlightHeight = min(bounds.height * 0.4, 30.0)
        innerHighlightLayer.frame = CGRect(x: 2, y: 2, width: bounds.width - 4, height: innerHighlightHeight)

        // Create inner stroke mask
        let innerPath = UIBezierPath(roundedRect: innerHighlightLayer.bounds, cornerRadius: max(0, glassCornerRadius - 2))
        let innerInnerPath = UIBezierPath(roundedRect: innerHighlightLayer.bounds.insetBy(dx: 1, dy: 1), cornerRadius: max(0, glassCornerRadius - 3))
        innerPath.append(innerInnerPath.reversing())

        let innerMask = CAShapeLayer()
        innerMask.path = innerPath.cgPath
        innerMask.fillRule = .evenOdd
        innerHighlightLayer.mask = innerMask

        // Update inner glow
        innerGlowLayer.frame = bounds.insetBy(dx: 4, dy: 4)

        CATransaction.commit()
    }

    public func update(size: CGSize, cornerRadius: CGFloat, transition: ContainedViewLayoutTransition) {
        self.glassCornerRadius = cornerRadius

        let frame = CGRect(origin: .zero, size: size)
        transition.updateFrame(view: self, frame: frame)

        setNeedsLayout()
        layoutIfNeeded()
    }

    public func updateColor(color: UIColor, transition: ContainedViewLayoutTransition) {
        // Determine if dark mode based on color brightness
        var brightness: CGFloat = 0
        color.getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)
        self.isDarkMode = brightness < 0.5

        // Adjust tint strength based on color alpha
        var alpha: CGFloat = 0
        color.getRed(nil, green: nil, blue: nil, alpha: &alpha)
        self.tintStrength = alpha
    }
}

// MARK: - ASDisplayNode Wrapper

public final class TabBarGlassBackgroundNode: ASDisplayNode {

    private var glassView: TabBarGlassBackgroundView?
    private var liquidGlassView: UIView? // For iOS 17+ SwiftUI glass view
    private var fallbackBackgroundNode: NavigationBackgroundNode?

    private var _glassCornerRadius: CGFloat = 0.0
    public var glassCornerRadius: CGFloat {
        get { return _glassCornerRadius }
        set {
            _glassCornerRadius = newValue
            glassView?.glassCornerRadius = newValue
            if #available(iOS 17.0, *) {
                (liquidGlassView as? LiquidGlassHostingView)?.glassCornerRadius = newValue
            }
        }
    }

    public override init() {
        super.init()

        self.isOpaque = false
        self.backgroundColor = nil
    }

    public override func didLoad() {
        super.didLoad()

        // Use SwiftUI glass view for iOS 17+
        if #available(iOS 17.0, *) {
            let liquidGlassView = LiquidGlassHostingView(frame: self.bounds)
            liquidGlassView.glassCornerRadius = _glassCornerRadius
            liquidGlassView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(liquidGlassView)
            self.liquidGlassView = liquidGlassView
        } else if #available(iOS 13.0, *) {
            // Use UIKit glass effect for iOS 13-16
            let glassView = TabBarGlassBackgroundView(frame: self.bounds)
            glassView.glassCornerRadius = _glassCornerRadius
            glassView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(glassView)
            self.glassView = glassView
        } else {
            // Fallback for older iOS
            let fallbackNode = NavigationBackgroundNode(color: UIColor.black.withAlphaComponent(0.5), enableBlur: true)
            self.addSubnode(fallbackNode)
            self.fallbackBackgroundNode = fallbackNode
        }
    }

    public func update(size: CGSize, cornerRadius: CGFloat, transition: ContainedViewLayoutTransition) {
        self._glassCornerRadius = cornerRadius

        let frame = CGRect(origin: .zero, size: size)

        if #available(iOS 17.0, *) {
            if let liquidGlassView = self.liquidGlassView as? LiquidGlassHostingView {
                liquidGlassView.glassCornerRadius = cornerRadius
                transition.updateFrame(view: liquidGlassView, frame: frame)
            }
        }

        if let glassView = self.glassView {
            glassView.update(size: size, cornerRadius: cornerRadius, transition: transition)
        }

        if let fallbackNode = self.fallbackBackgroundNode {
            fallbackNode.update(size: size, cornerRadius: cornerRadius, transition: transition)
            transition.updateFrame(node: fallbackNode, frame: frame)
        }
    }

    public func updateColor(color: UIColor, transition: ContainedViewLayoutTransition) {
        if let glassView = self.glassView {
            glassView.updateColor(color: color, transition: transition)
        }

        if let fallbackNode = self.fallbackBackgroundNode {
            fallbackNode.updateColor(color: color, transition: transition)
        }

        // For iOS 17+ SwiftUI view, we could add color theming here if needed
        // The current implementation uses system materials which auto-adapt
    }
}
