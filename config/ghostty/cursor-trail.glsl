// ADHD-Friendly Cursor Trail Shader for Ghostty
// Creates a subtle trail effect to help track cursor movement

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 color = texture(iChannel0, uv);

    // Get cursor position (normalized)
    vec2 cursor = iMouse.xy / iResolution.xy;

    // Calculate distance from cursor
    float dist = distance(uv, cursor);

    // Create a subtle glow/trail effect
    float trail = smoothstep(0.05, 0.0, dist);

    // Add a subtle highlight near the cursor
    vec3 highlight = vec3(0.2, 0.3, 0.4) * trail * 0.3;

    // Combine original color with highlight
    fragColor = vec4(color.rgb + highlight, color.a);
}