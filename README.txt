SHADER SHOWCASE

Six hand-written HLSL shaders running on Unity 6 / URP 17, plus a creative scene combining several of them. Each shader lives in its own scene so the technique can be inspected in isolation.


SCENE 01 VertexShader_Scene

Subject: a high-poly UV sphere (96 by 128 segments) with the ShaderShowcase/VertexWave material.

The vertex stage adds three sine and cosine waves and a radial ripple to the local position along the surface normal. Normals are recomputed via finite differences from the wave field so that lighting reacts correctly to the deformation. The fragment stage is intentionally minimal (Lambert plus SH ambient plus a fresnel highlight) to make clear that all the visual interest comes from the vertex pass.

Notable material parameters:
Wave Amplitude     height of the displacement
Wave Frequency     density of the waves across the surface
Wave Speed         how fast the wave field animates
Ripple Strength    weight of the radial pulse
Normal Curvature   how aggressive the rebuilt normals are
Crest Color        colour blended in on wave crests


SCENE 02 FragmentShader_Scene

Subject: a flat plane facing the camera using ShaderShowcase/FragmentSwirl.

The vertex shader is a pure pass-through (object to clip). The fragment computes a polar-coordinate spiral with arms, layered fbm value noise, animated time offsets and three blended colours for a galaxy or nebula look. Pure procedural; no textures are sampled at all.

Notable material parameters:
Color A B C D       palette used by the colour blends
Swirl Speed         rotation speed of the spiral pattern
Pattern Scale       zoom on the noise field
Swirl Strength      how much the radius twists the angle
Arm Count           number of bright spiral arms
Fractal Iterations  octaves of fbm (cost vs detail)


SCENE 03 ItemShader_Scene

Subject: a spinning cube hovering over a dark plane, driven by DissolveController.cs which animates Dissolve Amount from 0 to 1 and back.

3D fbm noise is sampled in object space; pixels whose noise value falls below a threshold are clipped (alpha-tested) so the mesh appears to disintegrate from the inside out. A narrow band of pixels just above the threshold receives a bright edge colour so the dissolve front glows. A fresnel rim plus a sin pulse provides a permanent highlight so the item reads as important or pickable. A separate DepthOnly pass runs the same clip math so depth writes stay consistent during the dissolve.

Notable material parameters:
Dissolve Amount    0 is solid, 1 is fully gone
Edge Width         thickness of the glowing dissolve front
Edge Color         colour of that front
Rim Color, Power   fresnel highlight band
Pulse Speed        rate of the breathing highlight
Highlight Strength extra additive pop on the silhouette


SCENE 04 EnvironmentShader_Scene

Subject: a 16 by 16 unit procedural plane (180 by 180 grid) with rocks scattered around, foggy ambient tint, low warm directional light.

Two scrolling fbm noise layers at different scales and speeds are mixed; their combined value drives a heat field. A sharp smoothstep around a configurable threshold splits the surface into cool crust and hot magma cells. Crack highlights are reconstructed from the difference between the two noise layers, giving the bright veins. Vertex bubbles displace the surface vertically using a sin times cos pattern in object space. HDR emissive output (values above 1) blooms naturally once the post-process volume Bloom is on.

Notable material parameters:
Crust Threshold, Sharpness   balance of cool vs hot
Emissive Strength            how bright the magma glows
Flow Speed                   global flow rate
Noise Scale A, B             large vs fine detail
Bubble Amplitude, Speed      vertex pop strength and rate
Crack Power                  sharpness of the bright veins


SCENE 05 PostProcessing_Scene

Subject: eight emissive props orbiting a dark centerpiece on a smooth metallic floor. Two coloured directional lights.

The look is defined entirely by the post-processing stack rather than the materials.

Built-in URP volume overrides:
Tonemapping       ACES
Color Adjustments more contrast, more saturation
Bloom             threshold 0.9, intensity 1.1
Vignette          intensity 0.35

A custom volume override (RetroPostProcessVolume) drives a custom ScriptableRendererFeature using the URP 17 RenderGraph API. Once Enable Effect is on, the feature blits the camera color through PostProcessRetro.shader which applies, in order: barrel distortion (CRT screen curvature), per-channel chromatic aberration along the radial direction, a 3 by 3 box-blur threshold-extracted bloom on top of URP bloom, a color tint, scanlines (sin of vertical UV), per-pixel temporal noise, contrast, saturation, exposure, and a soft vignette.

Notable RetroPostProcessVolume parameters:
Enable Effect              master switch for the custom pass
Chromatic                  radial RGB split amount
Scanline Intensity         0 disables scanlines, 1 is full bands
Scanline Count             number of bands across the screen
Curvature                  barrel strength
Bloom Threshold, Intensity secondary bloom on top of URP
Vignette Intensity, Smoothness  darkening towards edges
Noise, Saturation, Contrast, Exposure  final grade
Color Tint                 HDR tint multiplier


SCENE 06 CreativeShowcase_Scene

Subject: a tall floating crystal slowly bobbing and rotating, with six smaller orbiters parented to it, sitting on a glowing toon ground inside a starfield skydome. A small lava pool sits to the side as a callback to scene 4.

Shaders used together:
ShaderShowcase/MagicCrystal     on the crystal and orbiters
ShaderShowcase/StarSky          on a 60-unit inverted sphere acting as a sky dome
ShaderShowcase/ToonGround       on the ground plane
ShaderShowcase/EnvironmentLava  on the offset disc

Crystal: transparent (SrcAlpha, OneMinusSrcAlpha, ZWrite off). Fresnel-driven shell colour with an iridescent rainbow band (cos of NdotV plus phase offsets). Two layered 3D fbm noise sampled in object space, slowly drifting with time, gives the inner growth. A view-direction offset on the second layer fakes refraction by sliding the inner pattern as you orbit.

Sky: three star layers at different densities; a per-cell hash chooses sparse pixels and a sin twinkle modulates them. Two fbm passes multiplied together form the nebula clouds, coloured by a lerp between Nebula A and B. A vertical gradient runs between Sky Top and Sky Bottom. Drift Speed scrolls the entire sky horizontally over time.

Ground: world-space fbm picks between three grass tones plus a path tone above a high noise threshold. NdotL is quantized into Toon Steps bands. A travelling sin times sin pulse lights a glow strip across non-path tiles.

The volume in this scene reuses the same custom retro feature but with softer parameters (lower chromatic, lighter vignette, less curvature) so the painterly scene still reads clearly.
