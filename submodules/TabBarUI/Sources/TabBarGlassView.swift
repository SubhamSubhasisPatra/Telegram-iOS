import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftUI
import CoreMotion

// MARK: - Motion Manager for Reflection Effect

@available(iOS 17.0, *)
private final class GlassMotionManager: ObservableObject {
    static let shared = GlassMotionManager()

    private let motionManager = CMMotionManager()
    private var isRunning = false

    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    @Published var yaw: Double = 0

    private init() {}

    func start() {
        guard !isRunning, motionManager.isDeviceMotionAvailable else { return }

        isRunning = true
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion = motion else { return }
            self?.pitch = motion.attitude.pitch
            self?.roll = motion.attitude.roll
            self?.yaw = motion.attitude.yaw
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        motionManager.stopDeviceMotionUpdates()
    }
}

// MARK: - iOS 26 Style Liquid Glass View

@available(iOS 17.0, *)
private struct LiquidGlassView: View {
    let cornerRadius: CGFloat
    let rimIntensity: CGFloat
    let innerGlowIntensity: CGFloat
    let chromaticOffset: CGFloat
    let reflectionIntensity: CGFloat
    let showDebugIndicator: Bool

    @StateObject private var motionManager = GlassMotionManager.shared
    @State private var animationPhase: CGFloat = 0
    @State private var appearAnimation: CGFloat = 0

    init(
        cornerRadius: CGFloat = 20.0,
        rimIntensity: CGFloat = 0.5,
        innerGlowIntensity: CGFloat = 0.4,
        chromaticOffset: CGFloat = 0.6,
        reflectionIntensity: CGFloat = 0.8,
        showDebugIndicator: Bool = false
    ) {
        self.cornerRadius = cornerRadius
        self.rimIntensity = rimIntensity
        self.innerGlowIntensity = innerGlowIntensity
        self.chromaticOffset = chromaticOffset
        self.reflectionIntensity = reflectionIntensity
        self.showDebugIndicator = showDebugIndicator
    }

    // Calculate reflection offset based on device motion
    private var reflectionOffset: CGSize {
        let sensitivity: CGFloat = 30.0
        return CGSize(
            width: CGFloat(motionManager.roll) * sensitivity,
            height: CGFloat(motionManager.pitch) * sensitivity
        )
    }

    // Calculate specular highlight position based on motion
    private var specularPosition: UnitPoint {
        let baseX = 0.3 + CGFloat(motionManager.roll) * 0.4
        let baseY = 0.2 + CGFloat(motionManager.pitch) * 0.3
        return UnitPoint(
            x: min(max(baseX, 0), 1),
            y: min(max(baseY, 0), 1)
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Base ultra-thin material (frosted glass base)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Layer 2: Environment reflection simulation
                // This creates the illusion of reflecting the environment
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15 * reflectionIntensity * appearAnimation),
                                Color.clear,
                                Color.white.opacity(0.05 * reflectionIntensity * appearAnimation)
                            ],
                            startPoint: UnitPoint(
                                x: 0.0 + reflectionOffset.width / geometry.size.width,
                                y: 0.0 + reflectionOffset.height / geometry.size.height
                            ),
                            endPoint: UnitPoint(
                                x: 1.0 + reflectionOffset.width / geometry.size.width,
                                y: 1.0 + reflectionOffset.height / geometry.size.height
                            )
                        )
                    )
                    .blendMode(.overlay)

                // Layer 3: Specular highlight (the bright "light source" reflection)
                // This moves based on device tilt like a real glass surface
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.6 * reflectionIntensity * appearAnimation),
                                Color.white.opacity(0.2 * reflectionIntensity * appearAnimation),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.4
                        )
                    )
                    .frame(width: geometry.size.width * 0.6, height: geometry.size.height * 1.5)
                    .position(
                        x: geometry.size.width * specularPosition.x,
                        y: geometry.size.height * specularPosition.y - geometry.size.height * 0.2
                    )
                    .blur(radius: 20)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

                // Layer 4: Secondary specular (softer, larger)
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.25 * reflectionIntensity * appearAnimation),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.8
                        )
                    )
                    .frame(width: geometry.size.width * 1.2, height: geometry.size.height * 0.8)
                    .position(
                        x: geometry.size.width * (1 - specularPosition.x) + reflectionOffset.width * 0.5,
                        y: geometry.size.height * 0.3 + reflectionOffset.height * 0.5
                    )
                    .blur(radius: 40)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

                // Layer 5: Chromatic aberration on edges (rainbow fringing)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.red.opacity(0.08 * chromaticOffset * appearAnimation),
                                Color.orange.opacity(0.06 * chromaticOffset * appearAnimation),
                                Color.yellow.opacity(0.04 * chromaticOffset * appearAnimation),
                                Color.green.opacity(0.04 * chromaticOffset * appearAnimation),
                                Color.blue.opacity(0.06 * chromaticOffset * appearAnimation),
                                Color.purple.opacity(0.08 * chromaticOffset * appearAnimation),
                                Color.red.opacity(0.08 * chromaticOffset * appearAnimation)
                            ],
                            center: UnitPoint(
                                x: 0.5 + CGFloat(motionManager.roll) * 0.3,
                                y: 0.5 + CGFloat(motionManager.pitch) * 0.3
                            )
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: 1.5)

                // Layer 6: Rim light (top edge highlight)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.7 * rimIntensity * appearAnimation),
                                Color.white.opacity(0.3 * rimIntensity * appearAnimation),
                                Color.white.opacity(0.1 * rimIntensity * appearAnimation),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.0
                    )

                // Layer 7: Inner rim (secondary highlight)
                RoundedRectangle(cornerRadius: max(0, cornerRadius - 1), style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35 * rimIntensity * appearAnimation),
                                Color.white.opacity(0.1 * rimIntensity * appearAnimation),
                                Color.clear
                            ],
                            startPoint: UnitPoint(
                                x: specularPosition.x,
                                y: 0
                            ),
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
                    .padding(1)

                // Layer 8: Inner glow (depth effect)
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.1 * innerGlowIntensity * appearAnimation),
                        Color.white.opacity(0.03 * innerGlowIntensity * appearAnimation),
                        Color.clear
                    ],
                    center: UnitPoint(
                        x: 0.5 + CGFloat(motionManager.roll) * 0.2,
                        y: 0.4 + CGFloat(motionManager.pitch) * 0.2
                    ),
                    startRadius: 0,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.6
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

                // Layer 9: Animated caustic-like patterns (subtle light refraction)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.03 * (1 + Darwin.sin(Double(animationPhase)) * 0.5) * Double(appearAnimation)),
                                Color.clear,
                                Color.white.opacity(0.02 * (1 + Darwin.cos(Double(animationPhase) * 1.3) * 0.5) * Double(appearAnimation)),
                                Color.clear,
                                Color.white.opacity(0.03 * (1 + Darwin.sin(Double(animationPhase) * 0.7) * 0.5) * Double(appearAnimation))
                            ],
                            startPoint: UnitPoint(
                                x: 0.2 + Darwin.sin(Double(animationPhase) * 0.5) * 0.3,
                                y: 0.1 + Darwin.cos(Double(animationPhase) * 0.7) * 0.2
                            ),
                            endPoint: UnitPoint(
                                x: 0.8 + Darwin.cos(Double(animationPhase) * 0.3) * 0.3,
                                y: 0.9 + Darwin.sin(Double(animationPhase) * 0.4) * 0.2
                            )
                        )
                    )

                // Layer 10: Bottom shadow/depth (gives floating appearance)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.05 * appearAnimation)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: 2)
                    .blur(radius: 3)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .blendMode(.multiply)

                // Debug indicator (small colored dot to show glass is active)
                if showDebugIndicator {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .position(x: 20, y: 20)
                        .shadow(color: .green, radius: 3)
                }
            }
        }
        .onAppear {
            motionManager.start()

            // Animate appearance
            withAnimation(.easeOut(duration: 0.5)) {
                appearAnimation = 1.0
            }

            // Continuous caustic animation
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                animationPhase = .pi * 2
            }
        }
        .onDisappear {
            // Don't stop motion manager as it's shared
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

    var rimIntensity: CGFloat = 0.5 {
        didSet {
            updateGlassView()
        }
    }

    var innerGlowIntensity: CGFloat = 0.4 {
        didSet {
            updateGlassView()
        }
    }

    var chromaticOffset: CGFloat = 0.6 {
        didSet {
            updateGlassView()
        }
    }

    var reflectionIntensity: CGFloat = 0.8 {
        didSet {
            updateGlassView()
        }
    }

    var showDebugIndicator: Bool = false {
        didSet {
            updateGlassView()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
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
            chromaticOffset: chromaticOffset,
            reflectionIntensity: reflectionIntensity,
            showDebugIndicator: showDebugIndicator
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
            chromaticOffset: chromaticOffset,
            reflectionIntensity: reflectionIntensity,
            showDebugIndicator: showDebugIndicator
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        hostingController?.view.frame = bounds
    }
}

// MARK: - Glass Effect Layer (Fallback for older iOS)

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

// MARK: - Glass Background View (UIKit Fallback for iOS 13-16)

public final class TabBarGlassBackgroundView: UIView {

    // Glass effect components
    private let blurEffectView: UIVisualEffectView
    private let vibrancyEffectView: UIVisualEffectView
    private let tintOverlayView: UIView
    private let rimHighlightLayer: CAGradientLayer
    private let innerHighlightLayer: CAGradientLayer
    private let innerGlowLayer: CAGradientLayer
    private let reflectionLayer: CAGradientLayer

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

        // Create rim highlight layer
        self.rimHighlightLayer = CAGradientLayer()

        // Create inner highlight layer
        self.innerHighlightLayer = CAGradientLayer()

        // Create inner glow layer
        self.innerGlowLayer = CAGradientLayer()

        // Create reflection layer
        self.reflectionLayer = CAGradientLayer()

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

        // Setup reflection layer (simulates environment reflection)
        reflectionLayer.colors = [
            UIColor.white.withAlphaComponent(0.15).cgColor,
            UIColor.white.withAlphaComponent(0.05).cgColor,
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.03).cgColor
        ]
        reflectionLayer.locations = [0.0, 0.3, 0.6, 1.0]
        reflectionLayer.startPoint = CGPoint(x: 0, y: 0)
        reflectionLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(reflectionLayer)

        // Setup rim highlight
        rimHighlightLayer.colors = [
            UIColor.white.withAlphaComponent(0.7).cgColor,
            UIColor.white.withAlphaComponent(0.2).cgColor,
            UIColor.white.withAlphaComponent(0.1).cgColor,
            UIColor.clear.cgColor
        ]
        rimHighlightLayer.locations = [0.0, 0.2, 0.5, 1.0]
        rimHighlightLayer.startPoint = CGPoint(x: 0.5, y: 0)
        rimHighlightLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(rimHighlightLayer)

        // Setup inner highlight (top edge)
        innerHighlightLayer.colors = [
            UIColor.white.withAlphaComponent(0.3).cgColor,
            UIColor.white.withAlphaComponent(0.1).cgColor,
            UIColor.clear.cgColor
        ]
        innerHighlightLayer.locations = [0.0, 0.3, 1.0]
        innerHighlightLayer.startPoint = CGPoint(x: 0.5, y: 0)
        innerHighlightLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(innerHighlightLayer)

        // Setup inner glow (radial from center-top)
        innerGlowLayer.type = .radial
        innerGlowLayer.colors = [
            UIColor.white.withAlphaComponent(0.1).cgColor,
            UIColor.white.withAlphaComponent(0.03).cgColor,
            UIColor.clear.cgColor
        ]
        innerGlowLayer.locations = [0.0, 0.4, 1.0]
        innerGlowLayer.startPoint = CGPoint(x: 0.5, y: 0.3)
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

        reflectionLayer.cornerRadius = glassCornerRadius
        rimHighlightLayer.cornerRadius = glassCornerRadius
        innerHighlightLayer.cornerRadius = glassCornerRadius
        innerGlowLayer.cornerRadius = glassCornerRadius
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let bounds = self.bounds

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Update reflection layer
        reflectionLayer.frame = bounds

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


    /// Set to true to show a small green dot indicating the glass effect is active
    public var showDebugIndicator: Bool = true {
        didSet {
            if #available(iOS 17.0, *) {
                (liquidGlassView as? LiquidGlassHostingView)?.showDebugIndicator = showDebugIndicator
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

        // Use SwiftUI liquid glass view for iOS 17+
        if #available(iOS 17.0, *) {
            let liquidGlassView = LiquidGlassHostingView(frame: self.bounds)
            liquidGlassView.glassCornerRadius = _glassCornerRadius
            liquidGlassView.showDebugIndicator = showDebugIndicator
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

        // For iOS 17+ SwiftUI view, the materials auto-adapt to light/dark mode
    }
}
