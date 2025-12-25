#!/usr/bin/env python3
"""Generate app icon set for Casey Craps - dice showing 7 (4+3)"""

from PIL import Image, ImageDraw
import os

# Colors matching the game
FELT_GREEN = (13, 92, 13)  # 0x0d5c0d
DIE_WHITE = (255, 255, 255)
DOT_BLACK = (20, 20, 20)
BORDER_GOLD = (201, 162, 39)  # 0xc9a227

def draw_die(draw, x, y, size, value, rotation=0):
    """Draw a single die with dots"""
    # Die dimensions
    die_size = size * 0.35
    corner_radius = die_size * 0.15
    dot_radius = die_size * 0.08

    # Draw rounded rectangle for die
    x1, y1 = x - die_size/2, y - die_size/2
    x2, y2 = x + die_size/2, y + die_size/2

    # Draw die background with rounded corners (approximate with regular rect + circles)
    draw.rounded_rectangle([x1, y1, x2, y2], radius=corner_radius, fill=DIE_WHITE, outline=(200, 200, 200), width=2)

    # Dot positions (relative to center, scaled by die_size)
    dot_offset = die_size * 0.25

    # Define dot patterns for each value
    dot_patterns = {
        1: [(0, 0)],
        2: [(-dot_offset, -dot_offset), (dot_offset, dot_offset)],
        3: [(-dot_offset, -dot_offset), (0, 0), (dot_offset, dot_offset)],
        4: [(-dot_offset, -dot_offset), (dot_offset, -dot_offset),
            (-dot_offset, dot_offset), (dot_offset, dot_offset)],
        5: [(-dot_offset, -dot_offset), (dot_offset, -dot_offset), (0, 0),
            (-dot_offset, dot_offset), (dot_offset, dot_offset)],
        6: [(-dot_offset, -dot_offset), (dot_offset, -dot_offset),
            (-dot_offset, 0), (dot_offset, 0),
            (-dot_offset, dot_offset), (dot_offset, dot_offset)],
    }

    # Draw dots
    for dx, dy in dot_patterns.get(value, []):
        dot_x = x + dx
        dot_y = y + dy
        draw.ellipse([dot_x - dot_radius, dot_y - dot_radius,
                      dot_x + dot_radius, dot_y + dot_radius], fill=DOT_BLACK)

def create_icon(size):
    """Create icon at specified size"""
    # Create image with green background
    img = Image.new('RGBA', (size, size), FELT_GREEN)
    draw = ImageDraw.Draw(img)

    # Add subtle rounded corner effect for macOS icon style
    # Draw a slightly darker border
    margin = size * 0.05
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=size * 0.18,
        fill=FELT_GREEN,
        outline=BORDER_GOLD,
        width=max(2, int(size * 0.02))
    )

    # Position dice - slightly offset and rotated appearance
    center = size / 2
    die_offset = size * 0.18

    # Draw die showing 4 (top-left position)
    draw_die(draw, center - die_offset, center - die_offset * 0.3, size, 4)

    # Draw die showing 3 (bottom-right position)
    draw_die(draw, center + die_offset, center + die_offset * 0.3, size, 3)

    return img

def main():
    # Output directory
    output_dir = "Casey Craps/Casey Craps/Assets.xcassets/AppIcon.appiconset"

    # macOS icon sizes: (filename, pixel_size)
    sizes = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]

    print("Generating Casey Craps app icons...")

    for filename, pixel_size in sizes:
        img = create_icon(pixel_size)
        filepath = os.path.join(output_dir, filename)
        img.save(filepath, 'PNG')
        print(f"  Created {filename} ({pixel_size}x{pixel_size})")

    # Update Contents.json with filenames
    contents_json = '''{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}'''

    with open(os.path.join(output_dir, "Contents.json"), 'w') as f:
        f.write(contents_json)
    print("  Updated Contents.json")

    print("\nDone! Rebuild the app to see the new icon.")

if __name__ == "__main__":
    main()
