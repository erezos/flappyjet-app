#!/usr/bin/env python3
"""
Convert FlappyJet assets to base64 for embedding in playable ad
"""
import base64
from PIL import Image
import io
import sys

def optimize_and_encode_image(image_path, max_width=100, max_height=100, quality=85):
    """Optimize image and convert to base64"""
    try:
        # Open image
        img = Image.open(image_path)
        
        # Convert RGBA to RGB if needed (for JPEG)
        if img.mode == 'RGBA':
            # Create white background
            background = Image.new('RGB', img.size, (255, 255, 255))
            background.paste(img, mask=img.split()[3])  # Use alpha channel as mask
            img = background
        
        # Resize while maintaining aspect ratio
        img.thumbnail((max_width, max_height), Image.Resampling.LANCZOS)
        
        # Save to bytes
        buffer = io.BytesIO()
        img.save(buffer, format='PNG', optimize=True)
        buffer.seek(0)
        
        # Convert to base64
        img_base64 = base64.b64encode(buffer.read()).decode('utf-8')
        
        # Return data URL
        return f"data:image/png;base64,{img_base64}"
    
    except Exception as e:
        print(f"Error processing {image_path}: {e}", file=sys.stderr)
        return None

def main():
    # Paths
    jet_path = "../../assets/images/jets/green_lightning.png"
    obstacle_path = "../../assets/images/obstacles/phase1_wooden_pipes.png"
    
    print("Converting FlappyJet assets to base64...")
    print("=" * 50)
    
    # Convert jet (smaller for playable ad)
    print("\n1. Converting jet sprite...")
    jet_data = optimize_and_encode_image(jet_path, max_width=80, max_height=60)
    if jet_data:
        print(f"   ✅ Jet converted ({len(jet_data)} bytes)")
        print(f"\n   const jetImage = '{jet_data[:100]}...';\n")
    
    # Convert obstacle (taller for pipes)
    print("2. Converting obstacle sprite...")
    obstacle_data = optimize_and_encode_image(obstacle_path, max_width=60, max_height=200)
    if obstacle_data:
        print(f"   ✅ Obstacle converted ({len(obstacle_data)} bytes)")
        print(f"\n   const obstacleImage = '{obstacle_data[:100]}...';\n")
    
    # Save to file for easy copying
    with open('embedded_assets.txt', 'w') as f:
        f.write("// Embedded FlappyJet Assets\n\n")
        f.write(f"const jetImageData = '{jet_data}';\n\n")
        f.write(f"const obstacleImageData = '{obstacle_data}';\n")
    
    print("=" * 50)
    print("✅ Assets saved to: embedded_assets.txt")
    print("\nTotal size:", len(jet_data) + len(obstacle_data), "bytes")
    print("(Well under 5MB limit!)")

if __name__ == "__main__":
    main()
