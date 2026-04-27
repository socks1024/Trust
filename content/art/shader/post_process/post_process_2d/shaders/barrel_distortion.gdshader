shader_type canvas_item;

// ============================================
// 桶形畸变后处理效果 (Barrel Distortion Post-Processing)
// ============================================
// 使用方法：
// 1. 创建一个覆盖全屏的 ColorRect 或 TextureRect
// 2. 为其创建 ShaderMaterial 并赋予此 shader
// 3. 调整参数以模拟 CRT 电视的曲面屏效果

// --- 畸变参数 ---
// 畸变强度（值越大边缘弯曲越明显）
uniform float warp_strength : hint_range(0.0, 0.1, 0.001) = 0.02;

// --- 屏幕纹理（Godot 4.x 标准写法） ---
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// 计算桶形畸变后的 UV 坐标（向外膨胀，模拟 CRT 凸面屏）
vec2 barrel_distort(vec2 uv) {
	// 将 UV 映射到 [-1, 1] 范围，以中心为原点
	vec2 centered = uv * 2.0 - 1.0;
	// 向外膨胀：边缘采样点向外推，画面看起来向外鼓起
	float dist_sq = dot(centered, centered);
	centered *= 1.0 + dist_sq * warp_strength;
	// 映射回 [0, 1] 范围
	return centered * 0.5 + 0.5;
}

void fragment() {
	// --- 用节点自身 UV 计算畸变（确保中心点在屏幕正中心） ---
	vec2 warped_uv = barrel_distort(UV);

	// --- 计算采样坐标 ---
	vec2 sample_uv = SCREEN_UV + (warped_uv - UV);

	// --- 超出屏幕范围的部分显示黑色（CRT 圆角黑边） ---
	if (sample_uv.x < 0.0 || sample_uv.x > 1.0 || sample_uv.y < 0.0 || sample_uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		vec3 color = texture(SCREEN_TEXTURE, sample_uv).rgb;
		COLOR = vec4(color, 1.0);
	}
}
