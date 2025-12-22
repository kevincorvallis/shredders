#!/usr/bin/env python3
"""
Generate a professional app icon for PowderTracker/Shredders
Design: Mountain peak with powder snow and dynamic ski trail
"""

from PIL import Image, ImageDraw, ImageFont
import math

def create_icon(size=1024):
    # Create image with dark blue background
    base_color = (26, 35, 50)  # #1a2332
    img = Image.new('RGB', (size, size), base_color)
    draw = ImageDraw.Draw(img, 'RGBA')

    # Scale factor for responsive design
    s = size / 1024

    # Background gradient (dark to slightly lighter blue)
    for y in range(size):
        gradient_factor = y / size
        r = int(base_color[0] + 20 * gradient_factor)
        g = int(base_color[1] + 20 * gradient_factor)
        b = int(base_color[2] + 20 * gradient_factor)
        draw.rectangle([(0, y), (size, y+1)], fill=(r, g, b))

    # Main mountain (large, centered)
    mountain_base_y = int(750 * s)
    mountain_peak = (size // 2, int(200 * s))
    mountain_left = (int(200 * s), mountain_base_y)
    mountain_right = (int(824 * s), mountain_base_y)

    # Mountain layers for depth
    # Back mountain (darker)
    back_mountain = [
        (int(280 * s), mountain_base_y),
        (int(450 * s), int(280 * s)),
        (int(620 * s), mountain_base_y)
    ]
    draw.polygon(back_mountain, fill='#2c4a7c')

    # Main mountain (blue gradient)
    main_mountain = [mountain_left, mountain_peak, mountain_right]
    draw.polygon(main_mountain, fill='#4a7ba7')

    # Snow cap on peak (crisp white)
    snow_cap = [
        (mountain_peak[0] - int(120 * s), int(350 * s)),
        mountain_peak,
        (mountain_peak[0] + int(120 * s), int(350 * s)),
        (mountain_peak[0] + int(80 * s), int(380 * s)),
        (mountain_peak[0] - int(80 * s), int(380 * s))
    ]
    draw.polygon(snow_cap, fill='#ffffff')

    # Snow texture on mountain (lighter blue areas)
    left_snow = [
        (int(280 * s), int(500 * s)),
        (int(380 * s), int(400 * s)),
        (int(420 * s), int(520 * s))
    ]
    draw.polygon(left_snow, fill='#6ba3d0')

    # Dynamic ski trail (vibrant green/cyan curve)
    # Draw thick curved line representing fresh tracks
    trail_points = []
    start_x = int(720 * s)
    start_y = int(380 * s)

    for i in range(50):
        t = i / 49
        # Bezier-like curve
        x = start_x - int(300 * s * t)
        y = start_y + int(300 * s * t) + int(50 * s * math.sin(t * math.pi * 2))
        trail_points.append((x, y))

    # Draw trail with varying width
    for i in range(len(trail_points) - 1):
        width = int((15 - i * 0.15) * s)
        if width < int(3 * s):
            width = int(3 * s)

        # Gradient from bright green to cyan
        green_val = 230 - int(i * 1.5)
        blue_val = 100 + int(i * 2)
        color = (green_val, 200, blue_val) if green_val > 100 else (61, 214, 140)

        draw.line([trail_points[i], trail_points[i+1]], fill=color, width=width)

    # Add subtle shadow/depth to mountain
    shadow_overlay = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_overlay)

    # Right side shadow
    shadow_polygon = [
        mountain_peak,
        mountain_right,
        (mountain_peak[0], mountain_base_y)
    ]
    shadow_draw.polygon(shadow_polygon, fill=(0, 0, 0, 40))
    img.paste(Image.alpha_composite(img.convert('RGBA'), shadow_overlay).convert('RGB'))

    # Optional: Add powder spray effect (small dots near trail)
    for i in range(30):
        px = int((650 - i * 8) * s + (i % 3) * 10 * s)
        py = int((450 + i * 6) * s + (i % 2) * 15 * s)
        radius = int((3 - i * 0.05) * s)
        if radius > 0:
            alpha = 200 - i * 6
            draw.ellipse([(px-radius, py-radius), (px+radius, py+radius)],
                        fill=(200, 240, 220, alpha))

    return img

if __name__ == '__main__':
    print("Generating PowderTracker app icon...")
    icon = create_icon(1024)
    icon.save('/Users/kevin/Downloads/shredders/logo_master.png', 'PNG', quality=100)
    print("✓ Master icon saved: logo_master.png (1024x1024)")
