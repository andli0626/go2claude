#!/usr/bin/env python3
"""Generate app icons for Go2Claude with Claude brand colors."""

from PIL import Image, ImageDraw
import os

# Claude brand colors
CLAUDE_PURPLE = (204, 120, 92)  # #CC785C
CLAUDE_ORANGE = (217, 119, 87)  # #D97757
DARK_BG = (30, 30, 35)  # Dark background
WHITE = (255, 255, 255)

def create_gradient(size, color1, color2):
    """Create a linear gradient image."""
    img = Image.new('RGB', (size, size))
    for y in range(size):
        for x in range(size):
            ratio = (x + y) / (2 * size)
            r = int(color1[0] * (1 - ratio) + color2[0] * ratio)
            g = int(color1[1] * (1 - ratio) + color2[1] * ratio)
            b = int(color1[2] * (1 - ratio) + color2[2] * ratio)
            img.putpixel((x, y), (r, g, b))
    return img

def generate_icon(size, output_path):
    """Generate a single icon size."""
    # Create base image with rounded corners
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw rounded rectangle background
    corner_radius = int(size * 0.22)
    draw.rounded_rectangle([0, 0, size, size], radius=corner_radius, fill=DARK_BG)
    
    # Draw gradient circle
    circle_margin = size // 6
    circle_size = size - 2 * circle_margin
    
    # Create gradient for circle
    gradient = create_gradient(circle_size, CLAUDE_PURPLE, CLAUDE_ORANGE)
    
    # Create circular mask
    mask = Image.new('L', (circle_size, circle_size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.ellipse([0, 0, circle_size, circle_size], fill=255)
    
    # Apply mask to gradient
    gradient_circle = Image.new('RGBA', (circle_size, circle_size), (0, 0, 0, 0))
    gradient_circle.paste(gradient, (0, 0))
    gradient_circle.putalpha(mask)
    
    # Paste gradient circle onto base image
    img.paste(gradient_circle, (circle_margin, circle_margin), gradient_circle)
    
    # Draw simple "G" shape using circles and rectangles instead of text
    center_x = size // 2
    center_y = size // 2
    g_size = int(size * 0.25)
    
    # Draw white "G" shape
    line_width = max(2, size // 16)
    
    # G shape: outer circle arc + inner line
    # Draw arc for G
    arc_bbox = [
        center_x - g_size,
        center_y - g_size,
        center_x + g_size,
        center_y + g_size
    ]
    draw.arc(arc_bbox, start=45, end=315, fill=WHITE, width=line_width)
    
    # Draw horizontal line for G
    line_y = center_y
    line_start = center_x
    line_end = center_x + g_size
    draw.line([(line_start, line_y), (line_end, line_y)], fill=WHITE, width=line_width)
    
    # Draw vertical line for G
    draw.line([(line_end, line_y - line_width), (line_end, line_y + line_width//2)], fill=WHITE, width=line_width)
    
    # Save image
    img.save(output_path, 'PNG')
    print(f"Generated icon: {output_path} ({size}x{size})")

# Generate all required icon sizes
icon_sizes = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
    (1024, "icon_1024x1024.png")
]

output_dir = "."
if len(os.sys.argv) > 1:
    output_dir = os.sys.argv[1]

for size, filename in icon_sizes:
    output_path = os.path.join(output_dir, filename)
    generate_icon(size, output_path)

print("All icons generated successfully!")
