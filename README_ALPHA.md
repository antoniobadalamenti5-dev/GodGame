# God Game 2D — Pacchetto Alpha Godot 4.x (Progetto Completo)

Benvenuto nella build Alpha del tuo God Game 2D!
Questo archivio contiene **l'intero progetto Godot 4 pronto all'avvio** con tutti i sistemi implementati:

## ✨ Cosa troverai avviando il gioco (F5):
1. **Lupo Sacro Guardiano**: Posizionato vicino ad Aethelgard con la sua aura azzurra/dorata, pattuglia i confini ed evolve la sua indole in base alla cultura morale.
2. **Seconda Città Rivale (Kael-Thar)**: A Sud-Est con territorio color terracotta, falò e cittadini autonomi.
3. **Interfaccia Grafica HUD (CanvasLayer)**:
   - Indicatore numerico e barra grafica di **Fede Divina** (che aumenta con le preghiere al Tempio).
   - Contatore di **Giorno** (☀️ Giorno X).
   - Banner degli **Eventi Planetari** attivi (Siccità, Abbondanza, Festival, Tempesta).
   - Indicatore di **Relazione Diplomatica** con Kael-Thar.
   - 4 Pulsanti interattivi cliccabili a schermo (con notifiche toast).
4. **Scorciatoie da Tastiera**:
   - **[1]** Miracolo: Pioggia della Vita (costo: 20 Fede) -> Ricarica laghi e bacche.
   - **[2]** Miracolo: Crescita Silvana (costo: 25 Fede) -> Rigenera tutti gli alberi.
   - **[3]** Evento: Scatena Siccità Implacabile (EventSystem per 3 giorni).
   - **[4]** Miracolo: Benedizione Divina sul Lupo Sacro (costo: 15 Fede) -> Raddoppia velocità, dona aura dorata e +25 XP.
   - **[WASD o Frecce]** Sposta liberamente la visuale della Camera2D sulla mappa 4096x2560.

---

## 🚀 Come avviare il progetto:

### Metodo 1: Apri come Nuovo Progetto in Godot (CONSIGLIATO)
1. Estrai l'archivio ZIP in una cartella a tua scelta (es: `GodGameAlpha/`).
2. Apri **Godot Engine 4.x**.
3. Clicca su **"Importa"** (Import), seleziona il file `project.godot` all'interno della cartella estratta e clicca **"Importa e Modifica"**.
4. Premi **F5** (Avvia Progetto)! Tutto partirà all'istante con il Lupo, le due città e l'HUD!

### Metodo 2: Se vuoi aggiornare il tuo progetto Godot esistente
1. Copia i file della cartella `scripts/` nella cartella `scripts/` del tuo progetto.
2. Copia la cartella `scenes/` nella cartella `scenes/` del tuo progetto.
3. Apri `scenes/game.tscn` e premi **F6** (Esegui Scena Corrente).
*(Nota: il nostro script `scripts/game.gd` possiede un sistema di bootstrap intelligente: anche se un nodo non fosse presente nella tua scena, lo creerà automaticamente all'avvio in codice!)*
