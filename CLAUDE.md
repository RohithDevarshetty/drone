Project: Cinematic Scope Mobile Video Feed


Upload, processing and scrolling are focus
Target Platform: iOS (fullly funded hign quality app)

1. Introduction and Goals

Name: Cinescope, we focus on short high quality videos lesser than 1minnute 30seconds in horizontal formats

1.1 Purpose

The purpose of this document is to define the functional and non-functional requirements for the "Cinematic Scope Mobile Video Feed" application. It serves as the single source of truth for the engineering, design, and QA teams regarding the iOS MVP development.

1.2 Product Scope

The product is a high-fidelity mobile video streaming application designed to deliver a premium, "cinema-first" viewing experience. Unlike standard social feeds that prioritize vertical content, this application enforces a landscape-first, immersive environment specifically optimized for theatrical aspect ratios on mobile devices.

1.3 Key Goals

Premium Viewing Experience: Deliver uncompromised visual fidelity, supporting cinematic aspect ratios without cropping.

Zero Frame-Drop Performance: Achieve strictly fluid 60fps animations and scrolling, regardless of video resolution (up to 4K 60fps).

Immersive Interface: Remove UI clutter and enforce orientation constraints to ensure the content is viewed exactly as the director intended.

2. Functional Requirements (FRs)

This section outlines the specific behaviors and functions the system must support, focusing on the user interaction and video presentation logic.

FR1: Cinematic Video Feed

Description: The core interface is a full-screen, vertically scrollable container listing video content.

Behavior: Users swipe vertically (up/down) to navigate between videos.

Constraint: The scrolling physics must mimic standard native list behavior but applied to full-screen paging.

FR2: Orientation Control (Lock)

Description: The application functions strictly in Landscape Mode.

Constraint: The app must programmatically override auto-rotate settings to prevent the interface from shifting to Portrait mode during active viewing.

FR3: Orientation Prompt & Animation

Description: If the user launches the app or rotates the device into Portrait mode, the video feed must be obscured or paused.

UI Requirement: A high-quality opening animation must trigger, visually instructing the user to rotate their device 90 degrees.

State Handling: The actual video feed is inaccessible until the device sensors detect a Landscape orientation.

FR4: Vertical Paging

Description: The scroll mechanism implements strict "snapping" logic.

Behavior: A swipe gesture must result in the viewport settling exactly on the next or previous video. There should be no free-scrolling where the view stops halfway between two clips.

Implementation Note: Equivalent to Flutter’s PageView behavior.

FR5: Dynamic Aspect Ratio Support

Description: The player must dynamically adapt to the aspect ratio of the source content.

Supported Ratios: The system must explicitly support and correctly render:

1.85:1 (Standard Widescreen)

2.39:1 (Anamorphic/Scope)

2.00:1 (Univisium)

Constraint: Zero Cropping. The video must never be zoomed or cropped to fill the screen if it cuts off image data.

FR6: Correct Letterboxing

Description: To support FR5, the application must implement adaptive letterboxing.

Behavior: If the video's aspect ratio is wider than the mobile device's screen ratio, black bars must appear at the top and bottom. If the video is narrower (though rare in cinema), pillar-boxing (side bars) is acceptable.

Aesthetic: The bars must be strictly black (#000000) to blend with the device bezel.

3. Non-Functional Requirements (NFRs)

This section defines the system attributes, such as performance, reliability, and quality standards.

NFR1: Performance (Frame Rate)

Requirement: The application UI and scrolling animations must maintain a steady 60 Frames Per Second (FPS).

Tolerance: Zero noticeable "jank" or frame drops are permitted during the transition between video clips.

NFR2: Video Quality (Fidelity & Compression)

Requirement: The system must support high-fidelity playback up to 4K resolution at 60fps.

Compression Strategy:

While compression is necessary for streaming, the visual quality must rival "lossless" perception on mobile screens.

To achieve this (similar to high-end Instagram/YouTube uploads but with higher bitrate caps), the pipeline must utilize advanced coding efficiency.

Bitrate: Support for high-bitrate streams (adaptive based on network, but uncapped for high-speed connections).

Artifacts: Zero visible macro-blocking or banding in dark gradients.

NFR3: Decoding Efficiency

Requirement: Video decoding must occur exclusively via Hardware Acceleration.

Implementation:

iOS: Must utilize AVPlayer / AVFoundation to leverage the device's native GPU/Neural Engine decoders.

Constraint: Software decoding (e.g., FFMpeg software rendering) is strictly prohibited due to battery drain and thermal risks.

NFR4: Intelligent Pre-fetching

Requirement: Eliminate buffering latency during scroll.

Logic:

While Video N (current) is playing, Video N+1 (next) must effectively pre-load/buffer in the background.

Limit: Pre-fetching is strictly limited to the immediate next item (index + 1) to conserve bandwidth and memory.

NFR5: Resource Disposal

Requirement: Aggressive memory management for off-screen content.

Logic:

As soon as Video N-1 (previous) leaves the viewport completely, its player instance must be paused and its heavy resources (surface textures, decoders) disposed of.

The app must not keep more than 3 active player instances in memory (Current, Next, Previous-cached-state) at any time.

4. Technical Constraints and MVP Scope

TCR1: Technology Stack

Frontend Framework: Flutter (Dart).

Native Interop:

iOS: AVPlayer (accessed via Platform Channels or a high-performance wrapper plugin).

TCR2: MVP Target

Scope: The initial release and engineering efforts are strictly limited to the iOS Platform, but it is high quality project.

Device Support: iPhone models supporting iOS 16+.

TCR3: Codec Standards

Primary Codec: H.265 (HEVC).

Reasoning: H.265 offers superior compression efficiency (approx. 50% bit-rate savings over H.264 for the same quality) and supports 4K/HDR content natively on modern iOS hardware.

Fallback: H.264 (AVC) only for legacy compatibility if strictly necessary, but the pipeline prioritizes HEVC for the "Cinematic" quality goal.
