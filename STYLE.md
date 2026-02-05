🎨 PROMPT MAESTRO – ESTILO VISUAL DEL JUEGO (TIPO HADES)
📌 ESTILO GENERAL

Video game concept art in the style of Hades (Supergiant Games), high-quality 2D digital illustration, semi-realistic stylized art, hand-painted look, strong outlines, dynamic lighting, dramatic atmosphere, mythological fantasy theme.

📌 PERSONAJES

Stylized characters with sharp facial features, expressive eyes, heroic proportions, slightly exaggerated anatomy, detailed clothing and armor, Greek mythology inspired design, glowing accents, strong silhouette, clean readable shapes.

High detail portrait + full body view, dynamic pose, confident posture, cinematic framing.

📌 COLORES

Vibrant but controlled color palette, dominant reds, purples, blues, gold accents, dark backgrounds with glowing highlights, high contrast, moody lighting, magical aura.

📌 ILUMINACIÓN

Dramatic lighting, rim light, soft glow effects, fire and magic light sources, volumetric light, high contrast shadows, cinematic mood.

📌 ESCENARIOS

Mythological underworld environments, ancient ruins, lava caves, dark temples, floating platforms, mystical fog, glowing symbols, broken statues, fantasy architecture.

2D isometric / side-view / top-down game environment.

📌 UI / HUD

Clean fantasy UI, gold and stone textures, runic symbols, elegant borders, subtle animations, magical effects, readable fonts, polished game interface.

📌 EFECTOS

Magical particles, fire sparks, smoke trails, slash effects, energy waves, glowing projectiles, impact flashes, smooth animation frames.

📌 ANIMACIÓN

Fluid 2D animation, 12–24 fps style, squash and stretch, dynamic combat motion, responsive character movement, expressive idle animations.

📌 CALIDAD

Ultra high resolution, professional game art, AAA indie quality, sharp details, clean rendering, no blur, no artifacts.

---

## 📏 ESPECIFICACIONES TÉCNICAS (ASSETS HOUSING)

Para que el juego se vea coherente en Godot ("Side View" con profundidad), usa estas medidas y guías.

### 1. WALL (Pared de Fondo)
La pared es el fondo plano detrás de los personajes.
*   **Tamaño Standard:** `1920 x 1080` (Full Screen) o `1024 x 1024` (Tileable).
*   **Perspectiva:** **FRONTAL (Front View)**. Totalmente plana, sin fugas extremas.
*   **Propiedad Clave:** **Seamless Horizontal** (debe repetirse hacia los lados sin cortes).
*   **Prompt Keyword:** `straight front view`, `flat background`, `seamless horizontal pattern`.

### 2. FLOOR (Suelo / Plataforma)
El suelo donde pisan los personajes. Para dar "profundidad" en 2D, usamos una vista ligeramente superior.
*   **Tamaño Standard:** `1024 x 256` (Tira larga) o `512 x 512` (Tileable cuadrado).
*   **Perspectiva:** **Top-Down (Vista superior)** o **High-Angle (30-45 grados)**.
    *   *Tip:* No uses "Isométrico puro" (45 grados diagonal) porque tu juego es Side-View. Usa "Top-down" y estira un poco la imagen en Godot si es necesario.
*   **Propiedad Clave:** **Seamless Horizontal**.
*   **Prompt Keyword:** `top-down view texture`, `floor texture`, `horizontal tiling`.

### 3. ITEMS & MUEBLES (Furniture)

**ESTRATEGIA "MASTER SIZE"**: Genera todo en alta resolución y escala en el motor.

*   **Tamaño de Generación:** `512 x 512 px` (o `1024 x 1024` si usas Midjourney).
    *   Genera el objeto **centrado** y con **fondo liso** (negro o blanco) para recortarlo fácil.
*   **Perspectiva:** **Side View (2.5D)**. Vista lateral pero mostrando un poco de la parte superior/lateral para dar volumen.
*   **Escalado en Juego (Godot):**
    *   **Pequeño (Decoración):** Escala `0.25` (aprox 128px).
    *   **Mediano (Sillas/Mesas):** Escala `0.5` (aprox 256px).
    *   **Grande (Camas/Armarios):** Escala `1.0` (Full size).

*   **Sombras (Shadows):**
    *   **Drop Shadow (Suelo):** Idealmente **NO incluir sombra proyectada en el sprite** (o muy suave). Es mejor agregarla por código (un óvalo negro semitransparente debajo) para que siempre coincida con el suelo del juego.
    *   **Self-Shadow (Propia):** Sí, el objeto debe tener sus propias sombras y volumen.

---

## 🧠 PROMPTS ESPECÍFICOS PARA GENERACIÓN

Copia y pega estos bloques en tu IA generadora (Midjourney, DALL-E 3, Stable Diffusion).

### 🧱 PROMPT: PARED (WALL)
Usa esto para generar el fondo de la habitación.

```text
2D game texture, seamless dungeon wall background, style of Hades (Supergiant Games), hand-painted art style, straight front view (flat perspective), dark grey stone bricks with ancient greek carvings, faint purple ambient lighting, high contrast, sharp details, seamless horizontal tiling, no floor shown, no perspective depth, 4k resolution
```

### 🪵 PROMPT: SUELO (FLOOR)
Usa esto para generar la superficie donde caminan.

```text
2D game texture, seamless dungeon floor tiles, style of Hades (Supergiant Games), hand-painted art style, top-down view (flat surface), cracked stone pavement pattern, cold blue and dark grey tones, slight wet reflection, clean texture, seamless horizontal tiling, no walls shown, no isometric angle, 4k resolution
```
### 🪵 PROMPT: SUELO (FLOOR) - Opción Diagonal (45°)
Usa esto si quieres que las baldosas se vean en rombo/diamante para dar más dinamismo.

```text
2D game texture, seamless dungeon floor tiles, style of Hades (Supergiant Games), hand-painted art style, top-down view, 45-degree diagonal tile pattern (diamond shape), cracked stone pavement, cold blue and dark grey tones, slight wet reflection, clean texture, seamless horizontal tiling, no walls shown, 4k resolution
```



### 🪑 PROMPT: MUEBLES (Furniture)
Para sillas, mesas, etc.
```text
2D game asset, sprite of a [wooden throne / ancient table],
style of Hades, hand-painted,
side view with slight depth (2.5D),
dark wood with gold ornaments,
isolated on black background,
sharp edges, game icon style
```

---

🧠 PROMPT BASE COMPLETO (GENERAL)
Este es el que usás siempre y solo cambiás lo que esté entre []:

2D game art in the style of Hades (Supergiant Games), 
hand-painted digital illustration, semi-realistic stylized art,
dramatic lighting, high contrast, vibrant colors,
fantasy mythological theme, Greek underworld inspired,
sharp outlines, clean shapes, strong silhouette,
glowing accents, cinematic atmosphere,

[character / enemy / environment / item / UI],

dynamic pose, detailed design,
magical particles, soft glow, fire light,
professional indie game quality,
ultra high resolution, no blur, no artifacts
