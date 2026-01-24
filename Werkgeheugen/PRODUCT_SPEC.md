# Werkgeheugen - Product Specification

## Vision
Een ADHD-vriendelijke taak-app die frictie minimaliseert. Eerst dumpen, dan pas organiseren. Speels, empathisch, en helpt door weerstand heen met microstappen.

## Core Principles
1. **Frictie = 0**: Alles moet in <3 seconden gedumpt kunnen worden
2. **Microstappen eerst**: Niet "doe de hele taak", maar "wat is de allereerste actie?"
3. **Geen schuld/schaamte**: Speelse toon, geen oordeel
4. **Proactief helpen**: De app stelt voor, jij kiest

---

## User Flows

### Flow 1: Quick Capture (Tekst)
```
Home → Tik tekstveld → Type "Belastingaangifte" → Tik "Opslaan"
→ Taak in Inbox (uncategorized) → Haptic feedback ✓
```

### Flow 2: Voice Capture
```
Home → Houd Voice knop ingedrukt → Spreek in → Laat los
→ Automatische transcriptie → Taak + audio bijlage in Inbox
→ Confetti als bonus ✓
```

### Flow 3: Inbox Triage (1 taak per keer)
```
Inbox → Zie 1 taak groot in beeld
→ Swipe rechts: Kies categorie (Werk/Gezin/etc)
→ Swipe omhoog: Stel prio in (P1/P2/P3)
→ Tik "Microstap": Voeg eerste actie toe
→ Volgende taak verschijnt automatisch
```

### Flow 4: "Nu" View (Dagelijks gebruik)
```
Open app → Zie max 3 microstappen
→ "1. Open mail van accountant"
→ "2. Bel mama terug"
→ "3. Zoek paspoort"
→ Tik op stap → Focus Mode (fullscreen)
→ Done / Snooze 1u / Splits in kleinere stap
```

### Flow 5: Avond Check-in (21:30 notificatie)
```
Notificatie → Open Check-in scherm
→ "Vandaag afgevinkt: 5 items 🎉"
→ "Top 1 voor morgen:" [suggestie]
→ "Brain dump:" [tekstveld voor laatste gedachten]
→ "Welterusten!" → Confetti
```

### Flow 6: Proactieve Suggesties
```
Home → Sectie "Wat kan ik oppakken?"
→ 🏢 Werk: "Mail beantwoorden" (5 min)
→ 👨‍👩‍👧 Gezin: "Boodschappenlijst maken" (2 min)
→ ⚡ Quick win: "1 rekening betalen" (1 min)
→ Tik → Start Focus Mode
```

---

## Categories (Default + Custom)
| Icon | Naam | Standaard micro-actie |
|------|------|----------------------|
| 🏢 | Werk | "Check 1 mail" |
| 📱 | Apps | "Open project, lees 1 TODO" |
| ⚽ | Voetbal | "Check teamapp" |
| 🚶 | Straatambassadeurs | "Plan 1 wandeling" |
| 👨‍👩‍👧 | Gezin | "Stuur 1 berichtje" |
| 💰 | Financiën | "Check 1 rekening" |

---

## Gamification Rules

### Points
| Actie | Punten |
|-------|--------|
| Microstap afvinken | +10 |
| Hele taak done | +25 |
| 5 inbox items triaged | +15 |
| Avond check-in voltooid | +20 |
| Voice capture gebruikt | +5 |

### Badges
- 🔥 **Op Dreef**: 3 dagen op rij check-in
- 💰 **Financiën Ninja**: 5 financiën-taken afgerond
- ⚡ **Micro Master**: 25 microstappen gedaan
- 📥 **Inbox Zero**: Inbox volledig leeg
- 🎯 **Focus Held**: 10 Focus Mode sessies voltooid

### Mascotte: "Brein" (simpele blob)
- Zegt bemoedigende dingen: "Je kan dit!", "Eén stapje maar!"
- Wordt blij bij successen
- Zegt 's avonds: "Tijd om te rusten, morgen weer!"

---

## Notification Schedule (Instelbaar)

| Tijd | Type | Bericht |
|------|------|---------|
| 08:30 | Ochtend | "Goeiemorgen! 3 microstappen voor vandaag?" |
| 13:00 | Middag | "Even 1 quick win pakken? 💪" |
| 21:30 | Avond | "Check-in tijd! Wat is gelukt vandaag?" |

---

## Screen Inventory

1. **HomeView** - "Nu" met 1-3 microstappen + Quick Add
2. **InboxView** - Swipe-triage, 1 taak per keer
3. **CategoriesView** - Overzicht per categorie
4. **CategoryDetailView** - Taken in 1 categorie
5. **TaskDetailView** - Bewerk taak volledig
6. **FocusModeView** - Fullscreen 1 microstap
7. **CheckInView** - Avond samenvatting
8. **StatsView** - Punten, streaks, badges
9. **SettingsView** - Notificaties, categorieën, export

---

## Technical Stack
- **Platform**: iOS 17+
- **UI**: SwiftUI
- **Data**: SwiftData (local-first)
- **Audio**: AVAudioRecorder
- **Speech**: Speech framework (on-device)
- **Notifications**: UNUserNotificationCenter
- **Haptics**: UIImpactFeedbackGenerator
- **Architecture**: MVVM

---

## Privacy
- Geen account vereist
- Geen tracking
- Alle data lokaal op device
- Export: JSON/CSV optioneel
