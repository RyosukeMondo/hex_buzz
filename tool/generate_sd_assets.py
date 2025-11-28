#!/usr/bin/env -S bash -c '"$(dirname "$0")/venv/bin/python" "$0" "$@"'
# -*- coding: utf-8 -*-
"""
Generate game assets using Stable Diffusion Automatic1111 API.

Configuration:
- Model: DreamShaper XL Lightning (dreamshaperXL_lightningDPMSDE.safetensors)
- Resolution: 512x512
- Steps: 4 (Lightning model optimized)
- CFG Scale: 2.0
- API: Automatic1111 on port 7860
- Background removal: rembg for icons (transparent PNG)
"""

import base64
import io
import os
import requests
from pathlib import Path
from PIL import Image

try:
    from rembg import remove as remove_background
    REMBG_AVAILABLE = True
except ImportError:
    REMBG_AVAILABLE = False
    print("Warning: rembg not installed. Run 'pip install rembg' for transparent icons.")

# Configuration
API_URL = "http://localhost:7860"
OUTPUT_DIR = Path(__file__).parent.parent / "assets" / "images"

# SD settings for DreamShaper XL Lightning
SD_CONFIG = {
    "steps": 4,
    "cfg_scale": 2.0,
    "width": 512,
    "height": 512,
    "sampler_name": "DPM++ SDE",
    "scheduler": "Karras",
    "negative_prompt": "blurry, low quality, distorted, ugly, bad anatomy, text, watermark, signature, jpeg artifacts, noise",
}

# Asset definitions with prompts
ASSETS = {
    # App Icon - Main honeycomb/bee themed icon
    "app_icon.png": {
        "prompt": "game app icon, golden honeycomb hexagonal pattern, glowing amber honey texture, single cute cartoon bee mascot, warm golden yellow orange gradient, glossy 3D style, mobile game icon, centered composition, high quality, professional game art, no text",
        "negative": "text, letters, words, watermark, signature, multiple bees, realistic, photograph",
    },

    # Splash/Front screen background (seamless tile)
    "splash_background.png": {
        "prompt": "seamless tileable pattern, honeycomb hexagonal cells background, golden amber honey dripping texture, warm cream yellow gradient, soft glow, game UI background, vector style illustration, abstract geometric, high quality",
        "negative": "text, character, bee, figure, watermark, asymmetric",
    },

    # Level button/cell texture
    "level_button.png": {
        "prompt": "single hexagonal game button icon, golden honeycomb cell, glossy honey texture, warm amber glow, 3D embossed style, game UI element, centered, isolated on transparent, clean edges, high quality mobile game art",
        "negative": "text, numbers, multiple, pattern, background, watermark",
    },

    # Level button unlocked hover state
    "level_button_hover.png": {
        "prompt": "single hexagonal game button icon, bright glowing golden honeycomb cell, radiant honey amber, strong glow effect, 3D embossed style, game UI hover state, centered, isolated, luminous edges, high quality mobile game art",
        "negative": "text, numbers, multiple, pattern, background, watermark",
    },

    # Lock icon for locked levels
    "lock_icon.png": {
        "prompt": "game lock icon, vintage brass padlock, honey amber tint, stylized cartoon lock, game UI element, centered, clean design, glossy finish, mobile game art style, isolated icon",
        "negative": "text, key, chain, realistic, photograph, multiple, background",
        "remove_bg": True,
    },

    # Star filled (earned)
    "star_filled.png": {
        "prompt": "golden star game icon, shining glossy gold star, warm honey amber glow, sparkles, game achievement star, 3D cartoon style, centered, isolated, mobile game UI, high quality vector style",
        "negative": "text, multiple stars, background, realistic, dull",
        "remove_bg": True,
    },

    # Star empty (not earned)
    "star_empty.png": {
        "prompt": "empty star outline icon, silver grey star border, subtle shadow, game UI star placeholder, clean minimalist, centered, isolated, mobile game element, transparent center, outline only",
        "negative": "text, filled, gold, yellow, multiple, background, solid",
        "remove_bg": True,
    },

    # Victory/completion overlay background
    "victory_background.png": {
        "prompt": "celebration game victory screen background, golden light rays, honey drip decorations, warm amber gradient, confetti particles, festive game UI background, soft glow effect, high quality mobile game art",
        "negative": "text, character, face, realistic, dark, sad",
    },

    # Trophy icon for completion
    "trophy_icon.png": {
        "prompt": "golden trophy cup game icon, honey amber gold, glossy 3D cartoon style, small stars around, achievement reward icon, centered, isolated, mobile game UI element, warm glow",
        "negative": "text, realistic, photograph, multiple, background, engraving",
        "remove_bg": True,
    },

    # Hexagon cell - unvisited state
    "hex_cell_unvisited.png": {
        "prompt": "single hexagonal game cell, clean light cream colored honeycomb, subtle texture, soft shadow, game puzzle piece, minimalist flat design, centered, isolated, mobile game UI",
        "negative": "text, multiple, pattern, dark, visited mark, trail",
    },

    # Hexagon cell - visited state
    "hex_cell_visited.png": {
        "prompt": "single hexagonal game cell, golden amber honey filled honeycomb, glowing warm yellow, translucent honey texture, game puzzle visited state, centered, isolated, mobile game UI element",
        "negative": "text, multiple, pattern, empty, cream, white",
    },

    # Hexagon cell - start marker
    "hex_cell_start.png": {
        "prompt": "single hexagonal game cell, green glowing honeycomb, emerald game start marker, bright green glow effect, game puzzle start point, centered, isolated, mobile game UI",
        "negative": "text, multiple, pattern, red, yellow, bee",
    },

    # Hexagon cell - end marker
    "hex_cell_end.png": {
        "prompt": "single hexagonal game cell, red glowing honeycomb, ruby game end goal marker, warm red glow effect, game puzzle destination point, centered, isolated, mobile game UI",
        "negative": "text, multiple, pattern, green, yellow, bee",
    },

    # Play button
    "button_play.png": {
        "prompt": "play button game icon, golden hexagonal button with play triangle, honey amber glossy finish, 3D embossed style, game UI start button, centered, isolated, mobile game art, warm glow",
        "negative": "text, word play, multiple, background, realistic",
        "remove_bg": True,
    },

    # Retry/refresh button
    "button_retry.png": {
        "prompt": "retry refresh button game icon, circular arrow on hexagonal golden button, honey amber finish, 3D game UI element, centered, isolated, mobile game art style, clean design",
        "negative": "text, word, multiple, background, realistic",
        "remove_bg": True,
    },

    # Next level button
    "button_next.png": {
        "prompt": "next arrow button game icon, right arrow on hexagonal golden button, honey amber glossy finish, 3D game UI navigation, centered, isolated, mobile game art, forward chevron",
        "negative": "text, word next, multiple, background, realistic",
        "remove_bg": True,
    },

    # Back button
    "button_back.png": {
        "prompt": "back arrow button game icon, left arrow on hexagonal golden button, honey amber finish, 3D game UI navigation, centered, isolated, mobile game art, back chevron",
        "negative": "text, word back, multiple, background, realistic",
        "remove_bg": True,
    },

    # Menu/levels grid button
    "button_menu.png": {
        "prompt": "menu grid button game icon, 3x3 grid dots on hexagonal golden button, honey amber finish, game UI menu icon, centered, isolated, mobile game art, level select icon",
        "negative": "text, hamburger menu, lines, multiple, background",
        "remove_bg": True,
    },

    # Header banner texture
    "header_banner.png": {
        "prompt": "game header banner background, horizontal honeycomb pattern, golden amber gradient, honey drip decorations, warm game UI header, seamless horizontal tile, high quality mobile game art",
        "negative": "text, logo, character, vertical, square",
        "width": 1024,
        "height": 256,
    },

    # Bee mascot character
    "bee_mascot.png": {
        "prompt": "cute cartoon bee character mascot, adorable happy bee, chibi style, golden yellow and black stripes, tiny wings, big eyes, game character, centered, isolated, mobile game art, kawaii style",
        "negative": "realistic, scary, angry, multiple bees, background, text",
        "remove_bg": True,
    },

    # Honey drip decoration
    "honey_drip.png": {
        "prompt": "golden honey drip decoration, translucent amber honey drop, glossy liquid texture, game UI decorative element, isolated, vertical dripping honey, high quality",
        "negative": "text, background, solid, character, bee",
        "remove_bg": True,
    },

    # Progress bar fill texture (tileable)
    "progress_fill.png": {
        "prompt": "seamless horizontal tile, golden honey gradient texture, glossy amber fill, game progress bar texture, smooth gradient, warm yellow orange, game UI element",
        "negative": "text, pattern, hexagon, character, vertical",
        "width": 512,
        "height": 64,
    },

    # Settings gear icon
    "icon_settings.png": {
        "prompt": "settings gear icon, golden brass gear cogwheel, honey amber tint, game UI settings button, 3D cartoon style, centered, isolated, mobile game art, clean design",
        "negative": "text, multiple gears, background, realistic, rusty",
        "remove_bg": True,
    },

    # Sound on icon
    "icon_sound_on.png": {
        "prompt": "sound speaker icon with waves, golden amber game UI icon, 3D cartoon style, audio on indicator, centered, isolated, mobile game art element, clean design",
        "negative": "text, mute, x mark, background, realistic",
        "remove_bg": True,
    },

    # Sound off/mute icon
    "icon_sound_off.png": {
        "prompt": "muted speaker icon with X mark, golden amber game UI icon, 3D cartoon style, audio mute indicator, centered, isolated, mobile game art element",
        "negative": "text, waves, sound on, background, realistic",
        "remove_bg": True,
    },

    # Info/help icon
    "icon_info.png": {
        "prompt": "info help icon, golden circular i button, honey amber game UI icon, 3D cartoon style, information symbol, centered, isolated, mobile game art",
        "negative": "text, question mark, background, realistic, multiple",
        "remove_bg": True,
    },

    # Checkmark/complete icon
    "icon_checkmark.png": {
        "prompt": "checkmark tick icon, golden amber check symbol, game UI completion icon, 3D glossy style, success indicator, centered, isolated, mobile game art, green gold",
        "negative": "text, x mark, cross, background, realistic",
        "remove_bg": True,
    },
}


def ensure_model():
    """Ensure the correct model is loaded."""
    print("Checking current model...")
    response = requests.get(f"{API_URL}/sdapi/v1/options")
    current = response.json().get("sd_model_checkpoint", "")

    target_model = "dreamshaperXL_lightningDPMSDE.safetensors"
    if target_model not in current:
        print(f"Switching to {target_model}...")
        requests.post(
            f"{API_URL}/sdapi/v1/options",
            json={"sd_model_checkpoint": target_model}
        )
        print("Model switched.")
    else:
        print(f"Already using {target_model}")


def generate_image(prompt: str, negative: str, width: int = 512, height: int = 512) -> bytes:
    """Generate an image using the SD API."""
    payload = {
        "prompt": prompt,
        "negative_prompt": negative or SD_CONFIG["negative_prompt"],
        "steps": SD_CONFIG["steps"],
        "cfg_scale": SD_CONFIG["cfg_scale"],
        "width": width,
        "height": height,
        "sampler_name": SD_CONFIG["sampler_name"],
        "scheduler": SD_CONFIG["scheduler"],
        "batch_size": 1,
        "n_iter": 1,
    }

    response = requests.post(f"{API_URL}/sdapi/v1/txt2img", json=payload)
    response.raise_for_status()

    result = response.json()
    image_data = result["images"][0]
    return base64.b64decode(image_data)


def apply_background_removal(image_data: bytes) -> bytes:
    """Remove background from image using rembg, return transparent PNG."""
    if not REMBG_AVAILABLE:
        print("    Warning: rembg not available, skipping background removal")
        return image_data

    input_image = Image.open(io.BytesIO(image_data))
    output_image = remove_background(input_image)

    output_buffer = io.BytesIO()
    output_image.save(output_buffer, format="PNG")
    return output_buffer.getvalue()


def generate_all_assets():
    """Generate all game assets."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    ensure_model()

    total = len(ASSETS)
    for i, (filename, config) in enumerate(ASSETS.items(), 1):
        output_path = OUTPUT_DIR / filename

        print(f"\n[{i}/{total}] Generating {filename}...")

        width = config.get("width", SD_CONFIG["width"])
        height = config.get("height", SD_CONFIG["height"])
        negative = config.get("negative", SD_CONFIG["negative_prompt"])
        remove_bg = config.get("remove_bg", False)

        try:
            image_data = generate_image(
                prompt=config["prompt"],
                negative=negative,
                width=width,
                height=height
            )

            if remove_bg:
                print("    Removing background...")
                image_data = apply_background_removal(image_data)

            with open(output_path, "wb") as f:
                f.write(image_data)

            print(f"    Saved: {output_path}")

        except Exception as e:
            print(f"    ERROR: {e}")

    print(f"\n✅ Asset generation complete! Files saved to {OUTPUT_DIR}")


if __name__ == "__main__":
    generate_all_assets()
