#!/usr/bin/env python3
"""Create .icns file from PNG icons using PIL."""

from PIL import Image
import os
import struct
import io

def create_icns(input_dir, output_path):
    """Create .icns file from PNG images."""
    
    # ICNS file format:
    # Header: 4 bytes magic ('icns') + 4 bytes file length
    # Each image: 4 bytes icon type + 4 bytes data length + data
    
    # Icon types for macOS (from oldest to newest)
    icon_types = {
        16: b'icp4',      # 16x16
        32: b'icp5',      # 32x32
        48: b'icp6',      # 48x48
        128: b'ic07',     # 128x128
        256: b'ic08',     # 256x256
        512: b'ic09',     # 512x512
        1024: b'ic10',    # 1024x1024 (Retina)
    }
    
    images_data = []
    
    # Read all PNG files
    for size in [16, 32, 128, 256, 512, 1024]:
        filename = f"icon_{size}x{size}.png"
        filepath = os.path.join(input_dir, filename)
        
        if os.path.exists(filepath):
            with open(filepath, 'rb') as f:
                data = f.read()
                icon_type = icon_types.get(size, b'icnV')
                images_data.append((icon_type, data))
                print(f"Added: {filename} ({len(data)} bytes)")
    
    # Also add @2x versions for retina displays
    retina_map = {
        'icon_16x16@2x.png': b'icp5',    # 32x32 for 16@2x
        'icon_32x32@2x.png': b'icp6',    # 64x64 for 32@2x (use icp6 for 48, but it's 64)
        'icon_128x128@2x.png': b'ic08',  # 256x256 for 128@2x
        'icon_256x256@2x.png': b'ic09',  # 512x512 for 256@2x
        'icon_512x512@2x.png': b'ic10',  # 1024x1024 for 512@2x
    }
    
    for filename, icon_type in retina_map.items():
        filepath = os.path.join(input_dir, filename)
        if os.path.exists(filepath):
            with open(filepath, 'rb') as f:
                data = f.read()
                images_data.append((icon_type, data))
                print(f"Added: {filename} ({len(data)} bytes)")
    
    # Build ICNS file
    icns_data = io.BytesIO()
    
    # Write header
    icns_data.write(b'icns')
    
    # Calculate total size (will update later)
    header_pos = icns_data.tell()
    icns_data.write(struct.pack('>I', 0))  # Placeholder for file size
    
    # Write each image
    for icon_type, data in images_data:
        icns_data.write(icon_type)
        icns_data.write(struct.pack('>I', 8 + len(data)))  # 8 bytes header + data
        icns_data.write(data)
    
    # Update file size
    file_size = icns_data.tell()
    icns_data.seek(header_pos)
    icns_data.write(struct.pack('>I', file_size))
    
    # Write to file
    with open(output_path, 'wb') as f:
        f.write(icns_data.getvalue())
    
    print(f"\nCreated: {output_path} ({file_size} bytes)")
    print(f"Total images: {len(images_data)}")

if __name__ == '__main__':
    input_dir = "/Users/lilin/Downloads/Go2Claude/Resources/AppIcon.appiconset"
    output_path = "/Users/lilin/Downloads/Go2Claude/Resources/Go2Claude.icns"
    
    create_icns(input_dir, output_path)
