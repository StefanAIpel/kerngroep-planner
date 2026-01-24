# Werkgeheugen - Development Roadmap

## MVP (Huidige Versie) ✅

### Core Features
- [x] Quick Add (tekst capture)
- [x] Voice capture + transcriptie
- [x] Inbox met swipe-triage
- [x] Taak categorisatie (6 vaste categorieën)
- [x] Microstappen per taak
- [x] Focus Mode (fullscreen 1 stap)
- [x] "Nu" view met max 3 taken
- [x] Basic suggestie-engine
- [x] Avond check-in flow
- [x] Lokale data opslag (SwiftData)

### Gamification
- [x] Punten systeem
- [x] Streaks
- [x] Levels
- [x] 10 badges
- [x] Confetti animatie
- [x] Haptic feedback

### Notifications
- [x] Ochtend/middag/avond notificaties
- [x] Instelbare tijden
- [x] 3 "strictness" niveaus

---

## V1.0 - Polish & Refinement

### UX Verbeteringen
- [ ] Onboarding flow voor nieuwe gebruikers
- [ ] Tutorial tooltips
- [ ] Animatie bij eerste taak toevoegen
- [ ] Dark mode optimalisaties
- [ ] iPad ondersteuning
- [ ] Landscape mode (optioneel)

### Functionaliteit
- [ ] Custom categorieën toevoegen
- [ ] Taak herhaling (dagelijks/wekelijks)
- [ ] Subtaken/checklist binnen taak
- [ ] Tags naast categorieën
- [ ] Zoeken in taken
- [ ] Archief view (afgeronde taken)

### Gamification Uitbreidingen
- [ ] Meer badges (20+)
- [ ] Wekelijkse challenges
- [ ] "Perfect Week" achievement
- [ ] Mascotte met meer persoonlijkheid
- [ ] Seizoensgebonden badges

### Technisch
- [ ] Unit tests
- [ ] UI tests
- [ ] Performance optimalisatie
- [ ] Crash reporting (lokaal)
- [ ] Analytics (privacy-friendly, opt-in)

---

## V1.5 - Smart Features

### AI-Powered Suggestions
- [ ] Slimme microstap suggesties (ML)
- [ ] Taak prioritering op basis van gedrag
- [ ] Beste tijd om taken te doen
- [ ] "Energy level" tracking
- [ ] Focus score per dag

### Voice Verbeteringen
- [ ] Real-time transcriptie tijdens opname
- [ ] Voice commands ("Klaar", "Snooze")
- [ ] Siri Shortcuts integratie
- [ ] Audio notities afspelen

### Calendar Integratie
- [ ] Deadline sync met iOS Calendar
- [ ] Beschikbare tijd slots detectie
- [ ] Meeting-aware suggesties
- [ ] Herinneringen aan deadlines

---

## V2.0 - Ecosystem

### Widgets
- [ ] Home screen widget (Quick Add)
- [ ] Lock screen widget (volgende microstap)
- [ ] Today extension
- [ ] Interactive widgets (iOS 17+)

### Apple Watch
- [ ] Complicaties
- [ ] Voice capture vanaf Watch
- [ ] Haptic reminders
- [ ] Microstap afvinken

### Sync & Backup
- [ ] iCloud sync (optioneel)
- [ ] Handoff tussen devices
- [ ] Automatische backups
- [ ] Import/restore functie

### Sharing
- [ ] Taken delen met anderen
- [ ] Gezamenlijke inbox (gezin)
- [ ] "Accountability buddy" feature

---

## Toekomstige Ideeën (Backlog)

### Community Features
- [ ] Anonieme statistieken vergelijken
- [ ] Tips van andere ADHD'ers
- [ ] Template taken bibliotheek

### Integraties
- [ ] Shortcuts app acties
- [ ] Focus mode sync (iOS)
- [ ] Apple Health (stress/energy)
- [ ] Externe kalenders (Google)

### Accessibility
- [ ] VoiceOver optimalisatie
- [ ] Dynamic Type ondersteuning
- [ ] Reduced Motion respecteren
- [ ] Kleurenblind-vriendelijke UI

### Monetization (indien nodig)
- [ ] Gratis basis versie
- [ ] Pro: meer categorieën, themes
- [ ] Pro: geavanceerde statistieken
- [ ] Geen abonnement, eenmalige koop

---

## Principes voor Development

1. **ADHD-first**: Elke feature moet frictie verlagen, niet verhogen
2. **Offline-first**: Alles moet zonder internet werken
3. **Privacy-first**: Geen tracking, data lokaal
4. **Simple by default**: Features uitbreidbaar, niet complex
5. **Test with real users**: ADHD'ers betrekken bij development

---

## Tech Stack

- **UI**: SwiftUI
- **Data**: SwiftData
- **Audio**: AVFoundation
- **Speech**: Speech framework
- **Notifications**: UserNotifications
- **Analytics**: None (privacy)
- **Backend**: None (local-first)

---

## Versie Historie

| Versie | Status | Focus |
|--------|--------|-------|
| MVP | ✅ Done | Core functionaliteit |
| V1.0 | 🔄 Next | Polish & feedback |
| V1.5 | 📋 Planned | Smart features |
| V2.0 | 💭 Future | Ecosystem |
