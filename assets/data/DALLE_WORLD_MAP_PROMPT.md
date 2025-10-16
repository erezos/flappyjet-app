# 🎨 **DALL-E PROMPT FOR FLAPPYJET WORLD MAP**

## **Main Prompt**

```
Create a vibrant, colorful game world map for a mobile game in a top-down isometric view. The map shows a winding path connecting 50 level nodes across 5 distinct zones:

ZONE 1 (Bottom): Tropical beach paradise with palm trees, white sand, turquoise ocean, and wooden pier structures. Sunny and bright with coconuts and beach umbrellas.

ZONE 2 (Lower-middle): Sandy desert oasis with golden dunes, cacti, ancient pyramids, palm trees around water pools, and warm orange/yellow tones.

ZONE 3 (Middle): Volcanic lava mountains with dark rocky peaks, flowing orange lava rivers, smoke plumes, red-hot rocks, and dramatic fire effects.

ZONE 4 (Upper-middle): Stormy valley with dark storm clouds, lightning bolts, heavy rain, purple-gray skies, and wind-swept terrain.

ZONE 5 (Top): Frozen mountain peaks with snow-covered summits, ice crystals, glaciers, northern lights in the sky, and blue-white color palette.

The path winds upward from bottom to top like a snake, connecting all zones. The style should be:
- Cartoon/stylized art (not realistic)
- Bright, saturated colors
- Mobile game aesthetic (like Candy Crush or Angry Birds maps)
- Top-down 45-degree angle view
- Clear visual separation between zones
- Playful and inviting atmosphere
- No text or UI elements
- Square format (1:1 ratio, 2048x2048 pixels)

The path should have clear space for placing circular level nodes along it. Background should fade to transparent or solid color at edges.
```

---

## **Alternative Shorter Prompt**

```
Vibrant mobile game world map, top-down isometric view, winding path through 5 zones: tropical beach (bottom), desert oasis, lava mountains, storm valley, frozen peaks (top). Cartoon style, bright colors, playful aesthetic like Candy Crush. Square format 2048x2048px, clear path for level nodes, no text.
```

---

## **Style References to Mention**

If DALL-E asks for clarification or you want to refine:

- **Art Style:** "Candy Crush Saga map style"
- **Color Palette:** "Saturated, vibrant, family-friendly"
- **Perspective:** "Isometric top-down, 45-degree angle"
- **Mood:** "Adventurous, inviting, fun"

---

## **Technical Requirements**

- **Resolution:** 2048x2048 pixels (square)
- **Format:** PNG with transparency (if possible)
- **File Size:** Optimize to <2MB for mobile
- **Color Space:** sRGB
- **Aspect Ratio:** 1:1

---

## **After Generation**

Once you have the image:

1. **Save as:** `world_map_background.png`
2. **Place in:** `/assets/images/backgrounds/`
3. **Optimize:** Use TinyPNG or similar to compress
4. **Test:** Load in Flutter to ensure it displays correctly
5. **Backup:** Keep original high-res version

---

## **Fallback Plan**

If DALL-E doesn't produce the desired result:

1. **Option A:** Generate each zone separately and composite in Photoshop/GIMP
2. **Option B:** Use a solid gradient background and add zone decorations programmatically
3. **Option C:** Commission from Fiverr ($20-50, 2-3 days)
4. **Option D:** Use a simple colored path on solid background (fastest)

---

## **Zone Color Palette Reference**

For consistency with existing assets:

- **Zone 1 (Tropical):** `#4FC3F7` (cyan blue), `#FFD54F` (sand yellow)
- **Zone 2 (Desert):** `#FFB74D` (orange), `#FFF59D` (light yellow)
- **Zone 3 (Lava):** `#FF5722` (red-orange), `#424242` (dark gray)
- **Zone 4 (Storm):** `#5E35B1` (purple), `#78909C` (blue-gray)
- **Zone 5 (Frozen):** `#4FC3F7` (ice blue), `#E1F5FE` (light blue)

---

**Last Updated:** October 5, 2025
**Status:** Ready for Generation 🎨
