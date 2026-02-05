# Game Design Document (GDD) - IronClash

## 1. Resumen General
**Título Provisional:** IronClash  
**Género:** 2D Auto-Battle RPG / Estrategia Turn-Based (1vs1)  
**Plataformas:** PC, Android, iOS (Cross-platform). **NO Web.**  
**Modelo:** Free-to-Play con Monetización Premium (No Pay-to-Win).  
**Modo:** Single Player (PvE) y Multiplayer (PvP Asíncrono y Torneos en Vivo).  
**Cuenta:** Single Account, Multi-device.

### Concepto Principal
Un juego de batallas automáticas 1vs1 donde el jugador gestiona guerreros, define su equipamiento y mejoras, pero no controla el combate directamente. El foco está en la estrategia de preparación (stats, gear) y la gestión de recursos, complementado con un sistema de Housing social.

---

## 2. Mecánicas de Juego (Gameplay)

### 2.1 Sistema de Combate
*   **Tipo:** Automático por turnos. El servidor simula el combate para evitar trampas.
*   **Duración:** Batallas cortas y rápidas (~15-25 segundos).
*   **Turnos (ATB Mixto):** Basado en velocidad (SPD). Una barra de acción se llena; quien llega a 100 ataca. Personajes rápidos pueden atacar más veces.
*   **Acciones Automáticas:**
    *   **Ataque:** Daño basado en ATK y mitigado por DEF.
    *   **Crítico:** Chance de daño aumentado (x1.5).
    *   **Dodge (Evasión):** Probabilidad de evitar el 100% del daño.
    *   **Block (Bloqueo):** Probabilidad de reducir el daño recibido (40-70%).
    *   **Pasivas de Arma:** Efectos especiales (ej. Stun, Doble ataque) activados por RNG.
*   **Resolución:**
    1.  Check Dodge.
    2.  Check Block (si falla Dodge).
    3.  Check Crit.
    4.  Cálculo de Daño.

### 2.2 Stats y Personajes
*   **Stats Base:**
    *   `HP`: Vida.
    *   `ATK`: Daño base.
    *   `DEF`: Reducción de daño.
    *   `SPD`: Velocidad de turno.
    *   `CRIT`: Probabilidad de golpe crítico.
    *   `EVA`: Probabilidad de evasión.
*   **Progresión (Level Up):**
    *   Al subir de nivel, el jugador elige **1 de 3 mejoras aleatorias** (Roguelike style).
    *   Opciones posibles: Buff de Stats, Nueva Arma, Nueva Armadura.

### 2.3 Equipamiento (Gear)
*   **Slots:** 1 Arma, 1 Armadura (Máximo).
*   **Rarezas:** Común (Gris), Poco Común (Verde), Raro (Azul), Épico (Violeta), Legendario (Dorado).
*   **Mecánica:** Las armas y armaduras otorgan stats planos y pasivas, pero NO habilidades activas complejas en la versión inicial (MVP).

---

## 3. Modos de Juego

### 3.1 PvP Asíncrono (Modo Principal)
*   **Funcionamiento:** El jugador ataca "Snapshots" (copias guardadas) de otros jugadores. No requiere que el rival esté conectado.
*   **Matchmaking:**
    *   El jugador recibe **3 opciones de rivales** (Fácil, Medio, Difícil).
    *   Puede refrescar la lista pagando **Coins**.
*   **Coste:** Sistema de Vidas.
    *   Ganar: -1 Vida.
    *   Perder: -2 Vidas.
*   **Ranking:** Sistema de Ligas (Bronce a Master).
    *   En este modo, **perder NO baja ranking** (solo se sube por victorias).
    *   Soft cap diario para recompensas (diminishing returns) para evitar farmeo excesivo.

### 3.2 Torneos en Vivo (Live)
*   **Funcionamiento:** Eventos en tiempo real mediante WebSockets.
*   **Estructura:** Eliminación directa (Brackets de 32/64 jugadores).
*   **Competitivo:** Aquí **SÍ** se pierde rating/puntos al perder.
*   **Requisitos:** Sin bots, matchmaking estricto por nivel/liga.

### 3.3 PvE
*   Campaña o peleas contra la IA para progresar al inicio y farmear recursos básicos.

---

## 4. Meta-Juego y Economía

### 4.1 Sistema de Housing (Casas & Main Hub)
*   **Concepto:** Espacio personal decorable en Grid 2D que funciona como la **Pantalla Principal (Hub)** del juego.
*   **Perspectiva y Capas:** Vista lateral (Side View).
    *   **Capa Suelo (Floor):** Items con gravedad (mesas, sillas, camas). Los personajes caminan sobre esta capa.
    *   **Capa Pared (Wall):** Items colgados (cuadros, ventanas, estanterías). Fondo visual detrás de los personajes.
    *   **Personalización de Superficies:** Existen items consumibles o reutilizables (Papeles Tapiz, Cerámicas, Alfombras completas) que permiten cambiar la textura, diseño y color del fondo (pared) y del suelo base.
    *   **Restricción de Colocación:** Cada mueble tiene un tipo de anclaje definido (Suelo vs. Pared) que determina dónde se puede soltar en la grilla.
*   **Personajes:** Los guerreros del jugador están visibles dentro de la casa (idle/walking).
*   **Interacción (UI/UX):**
    *   **Control Central:** Desde la casa se gestiona todo.
    *   **Clic en Personaje:** Al tocar un guerrero, se abre su menú para ver Stats, Equipar Armas/Armaduras o **Enviarlo a Pelear**.
    *   **Modo Edición:** Botón específico para reorganizar muebles (con inventario inferior drag & drop).
    *   **Feedback Visual (Animaciones):**
        *   **Selección:** Al tocar/arrastrar un mueble, este realiza un efecto de "pop" (escala o brillo) para indicar que está activo.
        *   **Colocación (Drop):** Al soltarlo, reproduce una animación de asentamiento (ej. rebote suave o polvo) para confirmar la acción.
*   **Impacto en Gameplay:** **NULO** (Buffs). Es puramente estético, social y funcional como menú principal.
*   **Funciones:**
    *   Gestión de personajes y combate desde el entorno visual.
    *   Colocar muebles y decoraciones respetando capas.
    *   Visitar casas de amigos o aleatorias.

### 4.2 Economía (Monetización)
**Filosofía:** Pay-to-Fast / Pay-for-Cosmetics. **NO Pay-to-Win.**

*   **Monedas:**
    *   **Coins (Soft Currency):** Se gana jugando. Para comprar muebles básicos, refrescar rivales, mejoras estándar.
    *   **Gems (Hard Currency):** **Solo con dinero real.** Para cosméticos premium, recargar vidas, abrir cofres instantáneamente.
*   **Sistema de Vidas (Energía):**
    *   Cada personaje tiene sus propias vidas (Max 5).
    *   Regeneración por tiempo (ej. 25 min/vida).
    *   Recarga completa pagando Gems.
*   **Cofres (Loot Boxes):**
    *   Ganados en PvP.
    *   Requieren tiempo para abrirse (Time-gated).
    *   Slots limitados (5 por personaje).
    *   Contienen: Gear, Coins.
    *   Sistema **Pity**: Garantiza rareza alta tras X aperturas sin suerte.

### 4.3 Publicidad
*   **NO ADS.** Experiencia limpia y premium.

---

## 5. Arquitectura Técnica

### 5.1 Stack Tecnológico
*   **Cliente (Frontend):** Godot 4 (GDScript).
    *   Exportación: Android, iOS, PC.
*   **Backend:** Python (FastAPI).
    *   Arquitectura limpia (Domain, Services, API).
*   **Base de Datos:** PostgreSQL (Persistencia) + Redis (Caché y sesiones torneos).
*   **Comunicaciones:**
    *   REST API: Para la mayoría de acciones (Login, Setup batalla, Housing, Shop).
    *   WebSockets: Exclusivo para Torneos en Vivo.

### 5.2 Lógica de Servidor
*   **Autoritativo:** El combate se simula 100% en el servidor. El cliente solo recibe el "Replay" (JSON) para visualizarlo.
*   **Seguridad:** Validación de recibos de pago, prevención de manipulación de stats, anti-cheat por diseño.

---

## 6. Roadmap de Desarrollo (MVP)

**Fase 1: Core (MVP)**
*   Setup del proyecto (Godot + FastAPI).
*   Sistema de Login/Auth.
*   Combate básico (Cálculo de daño, turnos automáticos).
*   1 Personaje jugable, equipamiento básico.

**Fase 2: Progresión**
*   Sistema de Level Up y elección de mejoras.
*   Inventario y gestión de Gear.
*   Sistema de Vidas y regeneración.

**Fase 3: Social & PvP Async**
*   Implementación de Housing (Grid placement).
*   Matchmaking asíncrono y sistema de Snapshots.
*   Tienda básica (Coins/Gems).

**Fase 4: Live & Polish**
*   Torneos via WebSockets.
*   Ranking y Ligas.
*   Ajustes de UI/UX y efectos visuales.
