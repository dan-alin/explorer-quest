# ActionPanel - Tactical RPG Action Control UI

Il pannello delle azioni è un'interfaccia utente ispirata ai giochi tattici come Final Fantasy Tactics e Fire Emblem, che permette al giocatore di scegliere le azioni per il personaggio attualmente selezionato.

## 🎮 Come Usare

### Controlli Mouse
- **Clicca sui pulsanti** nell'interfaccia per selezionare un'azione
- **Tasto destro** per eseguire attacchi quando è selezionata la modalità attacco

### Scorciatoie da Tastiera (per test)
- **1** - Move (Movimento)
- **2** - Attack (Attacco)
- **3** - Defend (Difesa)
- **4** - Magic (Magia)
- **5** - Wait (Aspetta)
- **6** - End Turn (Termina Turno)

### Controlli di Test
- **T** - Esegui tutti i test automaticamente
- **H** - Mostra aiuto

## ⚔️ Azioni Disponibili

### 🚶 Move (Movimento)
- Attiva la modalità movimento del giocatore
- Mostra le celle raggiungibili evidenziate
- Il giocatore può cliccare su una cella valida per muoversi

### ⚔️ Attack (Attacco)
- Entra in modalità targeting per attacchi
- Usa tasto destro per attaccare nella posizione del mouse
- Per ora stampa solo output in console

### 🛡️ Defend (Difesa)
- Il personaggio assume una posizione difensiva
- Per ora stampa solo output in console
- In futuro ridurrà i danni ricevuti

### ✨ Magic (Magia)
- Sistema di magia (non ancora implementato)
- Per ora stampa solo output in console

### ⏸️ Wait (Aspetta)
- Il personaggio aspetta senza fare azioni
- Per ora stampa solo output in console

### 🔄 End Turn (Termina Turno)
- Termina il turno del personaggio corrente
- Per ora stampa solo output in console

## 🏗️ Architettura

### File Principali
- **ActionPanel.gd** - Script principale del pannello
- **ActionPanel.tscn** - Scena dell'interfaccia utente
- **ActionPanelTest.gd** - Script per test automatizzati

### Stati delle Azioni
```gdscript
enum ActionMode {
    NONE,        # Nessuna azione selezionata
    MOVE,        # Modalità movimento
    ATTACK,      # Modalità attacco
    DEFEND,      # Modalità difesa
    MAGIC,       # Modalità magia
    TARGETING    # Modalità targeting generica
}
```

### Integrazione con Player
Il pannello si connette automaticamente al Player tramite `set_player_reference()` e aggiorna:
- Informazioni del personaggio (HP, MP, Movimento)
- Stato dei pulsanti (abilitato/disabilitato)
- Feedback visuale

## 🎨 Interfaccia

Il pannello include:
- **Nome del personaggio**
- **Barra HP** (Punti Vita)
- **Barra MP** (Punti Magia)
- **Contatore movimento** (es. "Movement: 3/5")
- **Griglia di azioni** (2x3 pulsanti)
- **Pulsante End Turn** separato

## 🔧 Personalizzazione

### Colori e Stile
- I pulsanti selezionati diventano gialli
- I pulsanti disabilitati sono grigi
- Le barre HP/MP usano colori standard di Godot

### Posizionamento
Il pannello è ancorato nell'angolo in basso a destra dello schermo con:
- `anchors_preset = 3` (bottom-right)
- Offset per spaziatura dai bordi

## 🐛 Debug e Test

### Output Console
Ogni azione stampa un messaggio colorato:
- 🚶 Move
- ⚔️ Attack  
- 🛡️ Defend
- ✨ Magic
- ⏸️ Wait
- 🔄 End Turn

### Test Automatici
Usa `ActionPanelTest.gd` per test completi:
```gdscript
# Trova e testa automaticamente il pannello
run_all_tests()
```

## 📋 TODO Future

1. **Implementare sistema difensivo** completo
2. **Aggiungere sistema magico** con spell selection
3. **Migliorare targeting** con preview dell'area d'effetto
4. **Animazioni** per feedback visivo
5. **Suoni** per le azioni
6. **Supporto multi-personaggio** per RPG completi
7. **Personalizzazione temi** per diversi stili visuali

## 🔗 Dipendenze

- **Player.gd** - Per riferimenti al personaggio
- **CharacterStats.gd** - Per informazioni HP/MP/movimento
- **GridOverlay.gd** - Per evidenziazione movimento (opzionale)
