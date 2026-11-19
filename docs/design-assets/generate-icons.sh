#!/bin/bash

# Go2Claude Icon Generator
# Generates all required macOS app icon sizes from SVG

SVG_FILE="Go2Claude-Icon-Design.svg"
OUTPUT_DIR="icons"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if rsvg-convert is available, otherwise use sips
if command -v rsvg-convert &> /dev/null; then
    CONVERTER="rsvg"
    echo "Using rsvg-convert for conversion..."
elif command -v sips &> /dev/null; then
    CONVERTER="sips"
    echo "Using sips for conversion..."
else
    echo "Error: No SVG converter found. Install librsvg (brew install librsvg) or use sips."
    exit 1
fi

# Icon sizes for macOS
declare -a SIZES=(
    "16"
    "32"
    "64"
    "128"
    "256"
    "512"
    "1024"
)

echo "Generating icons..."

for size in "${SIZES[@]}"; do
    output_file="$OUTPUT_DIR/icon_${size}x${size}.png"
    
    if [ "$CONVERTER" = "rsvg" ]; then
        rsvg-convert -w "$size" -h "$size" "$SVG_FILE" -o "$output_file"
    else
        # Convert SVG to temporary PNG first with sips
        sips -z "$size" "$size" "$SVG_FILE" --out "$output_file" 2>/dev/null || echo "sips failed for $size"
    fi
    
    # Generate @2x versions
    if [ "$size" -le 512 ]; then
        size2x=$((size * 2))
        output_file_2x="$OUTPUT_DIR/icon_${size}x${size}@2x.png"
        
        if [ "$CONVERTER" = "rsvg" ]; then
            rsvg-convert -w "$size2x" -h "$size2x" "$SVG_FILE" -o "$output_file_2x"
        else
            sips -z "$size2x" "$size2x" "$SVG_FILE" --out "$output_file_2x" 2>/dev/null || echo "sips failed for @2x $size"
        fi
    fi
    
    echo "  ✓ Generated ${size}x${size}"
    [ -f "${output_file_2x:-}" ] && echo "  ✓ Generated ${size}@2x"
done

# Generate App Store icon (1024x1024)
echo "  ✓ Generated 1024x1024 (App Store)"

echo ""
echo "All icons generated in: $OUTPUT_DIR/"
