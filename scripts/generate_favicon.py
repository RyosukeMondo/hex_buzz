import os
from PIL import Image

def generate_favicons():
    # Define paths
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    source_icon_path = os.path.join(base_dir, 'assets', 'icons', 'master_icon.png')
    web_dir = os.path.join(base_dir, 'web')
    
    # Target files
    favicon_ico_path = os.path.join(web_dir, 'favicon.ico')
    favicon_png_path = os.path.join(web_dir, 'favicon.png')
    
    # Check if source exists
    if not os.path.exists(source_icon_path):
        print(f"Error: Source icon not found at {source_icon_path}")
        return

    try:
        # Open source image
        img = Image.open(source_icon_path)
        
        # Generate favicon.ico
        # Standard sizes for ico: 16x16, 32x32, 48x48
        # High DPI sizes could also be included: 64x64, 128x128, 256x256
        icon_sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
        img.save(favicon_ico_path, sizes=icon_sizes)
        print(f"Generated: {favicon_ico_path}")
        
        # Generate favicon.png (32x32)
        favicon_png = img.resize((32, 32), Image.Resampling.LANCZOS)
        favicon_png.save(favicon_png_path)
        print(f"Generated: {favicon_png_path}")
        
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    generate_favicons()
