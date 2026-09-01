# Note dal campo — quindici passate reali

> Raccolte usando `review-cycle` 0.1.0-beta.1 su PR reali di `elmisi/navigator`
> (dieci passate su cinque PR) e di `elmisi/claude-code-automation`
> (cinque passate sulla PR #29), il 27–28 agosto 2026. Sono osservazioni sul
> **plugin**, non sulle PR. Le review prodotte sono su GitHub.
> Esito: `navigator#6` e `claude-code-automation#29` entrambe mergiate.

## Passate eseguite

| Passata | Target | Corsia | Esito |
| --- | --- | --- | --- |
| 1 | navigator PR #2 (32 file, +8007) | `normal` → promossa `strict` | Fermata al gate d'intento: la descrizione copriva un quinto del cambiamento. PR chiusa e divisa dall'autore in #3 e #4. |
| 2 | navigator PR #3 (8 file, +63) | `normal` | 7 finding, 2 questioni aperte. Un test che non poteva passare, verificato eseguendone l'assertion. |
| 3 | navigator PR #3 dopo i fix | `normal` | 4 rilievi chiusi; un mio rilievo ritirato; rilievo nuovo verificato su Chrome reale. |
| 4 | navigator PR #4 (14–15 file, +704) | `normal` → promossa `strict`, due giri | Fallback silenziosi chiusi; il difetto centrale resta aperto. |
| 5 | navigator PR #5 (15 file, +744) — stesso branch della #4, richiusa e riaperta | `normal` → promossa `strict` | Il difetto centrale chiuso, ma non dal meccanismo che la PR si attribuisce. Rilievo nuovo bloccante sul threat model, misurato. |
| 6 | navigator PR #5 dopo i fix (`2f69126`) | `normal` → promossa `strict` | Il bound bloccante resta falso per una via diversa. Difetto nuovo su `selector`, trovato solo eseguendo. Primo commento pubblicato secondo la regola di pertinenza: 502 parole contro 1075. |
| 7 | navigator PR #6 (`6aef032`) — #5 richiusa e riaperta, terza volta | `normal` → promossa `strict` | Tutti i rilievi precedenti chiusi e verificati. Difetto nuovo bloccante: `reload` non ricarica mai, e il test che lo copre passa per corsa. Il passo di identità dell'artefatto ha evitato tre misure sbagliate. |
| 8 | navigator PR #6 dopo i fix (`080b446`) | `normal` → promossa `strict` | Il meccanismo corretto e misurato. Il test che lo copre è passato da impossibile a tautologico: stessa classe, segno invertito. |
| 9 | navigator PR #6 (`98107f4`) | `normal` → promossa `strict` | Suite E2E finalmente **eseguita**: 31/31. Ultimo rilievo residuo corretto da me e pushato. PR mergiata. |
| 10–14 | claude-code-automation PR #29, cinque giri (`220927c2` → `6482221`) | `normal` | Prima applicazione al repo del plugin stesso. Otto rilievi in tutto, tutti chiusi; ogni correzione verificata per mutazione. Due buchi nei test trovati mutando, non leggendo. PR mergiata. |

## Difetti del plugin da correggere

> Stato al 2026-08-28, `review-cycle` 0.2.0-beta.1: corretti il difetto 3 (segnali
> di capacità), il buco metodologico (passo di perturbazione), la soglia di
> copertura e `.gitignore` nel catalogo. Restano aperti 1, 2, 4, 5, 6, 7, 8, 9, 10.


1. **`runner_detect` guarda solo la radice del repository.** `server/pyproject.toml`
   e `tests/js/package.json` gli sono invisibili. Qualunque progetto col backend
   in una sottodirectory annulla il rilevamento delle suite, e con esso la
   hygiene lane.

2. **`rc-suites.sh discover` senza CI emette un'istruzione impossibile.**
   Restituisce `needs_model_extraction: true` con `ci_files: []`, cioè dice al
   modello di estrarre un comando da una lista vuota. Deve distinguere "la CI
   c'è, leggila" da "non c'è, chiedi all'utente una volta e memorizza".

3. **[CORRETTO in 0.2.0-beta.1]** **Il catalogo dei segnali non ha nulla per i
   confini di capacità.** In tutte e
   cinque le passate il pavimento non ha mai riconosciuto il cambiamento più
   consequenziale: un'estensione che acquisisce la capacità di eseguire JS
   arbitrario in un frame cross-origin che non possiede. Ho dovuto promuovere a
   mano ogni volta. I pattern attuali coprono migrazioni, auth, segreti,
   permessi, `.sql`, infrastruttura — nessuno descrive "nuova superficie di
   esecuzione" o "nuovo permesso richiesto da un manifest".
   Candidati: `**/manifest.json` con diff su `permissions`/`host_permissions`,
   `chrome.debugger`, `Target.setAutoAttach`, `Runtime.evaluate`, `eval(`,
   `new Function(`, `--allow-*`, `sudo`, `NOPASSWD`.

4. **`rc-recognize.sh` su un range vuoto restituisce `coverage: 1.0`.** Copertura
   vacua indistinguibile da copertura piena. Va segnalato come `total: 0`
   separatamente, o `coverage: null`.

5. **La hygiene lane non è mai partita.** Otto passate su `navigator`, zero fix
   applicati: quel repository non ha CI e nessuna baseline verde è stabilibile.
   È il comportamento corretto, ma significa che su un repository senza CI il
   plugin produce solo giudizi. Serve almeno un percorso: comando fornito
   dall'utente e memorizzato, che il protocollo già prevede ma che `discover`
   non sa chiedere (vedi 2).

   Ambito, dopo una attribuzione sbagliata da correggere: questo difetto è
   **solo** l'assenza di una baseline verde. Su `belt-configurator`, che la CI
   ce l'ha, non si è presentato — e nemmeno i difetti 1 e 2, perché il
   `package.json` di radice espone un `test` che copre i workspace e `discover`
   ha risposto con il file CI e un'istruzione sensata. Quello che lì ha bloccato
   l'esecuzione è un difetto diverso, il 10.

6. **Il registro conosce un solo modo di chiudere un rilievo.** Servono tre
   stati distinti, e nelle cinque passate si sono presentati tutti:
   - *chiuso perché risolto* — il caso ordinario;
   - *ritirato perché era sbagliato* — passata 3, un mio finding poggiava su un
     modello errato di `isContentEditable`;
   - *chiuso, ma non per la causa dichiarata* — passata 5. Il fallback
     silenzioso sui frame cross-site è davvero chiuso, ma non grazie alla
     guardia che la PR si attribuisce: è chiuso perché `Page.getFrameTree` non
     enumera affatto gli OOPIF, quindi la risoluzione fallisce molto prima.
     La differenza non è accademica: la guardia a cui l'autore attribuisce il
     merito è ancora nel posto sbagliato, dopo la valutazione anziché prima, e
     se un giorno quel ramo diventasse raggiungibile il difetto tornerebbe.
     Registrare solo "chiuso" perde esattamente questa informazione.

7. **Il commento pubblicato non è il `review.md`, e oggi lo è.** Feedback
   dell'utente dopo la passata 5, in due tempi. Primo: i commenti dicono cose
   giuste in circa il doppio delle parole necessarie. Secondo, più preciso e
   che corregge il primo: il problema non è la lunghezza ma la **pertinenza** —
   nei commenti finiscono dettagli di come ha lavorato il plugin, che non
   riguardano la PR. Il criterio dell'utente: il carico cognitivo di chi
   interpreta, umano o agentico, va tenuto il più basso possibile; la verbosità
   è accettabile se aiuta a formulare il contesto, ma tutto deve essere inerente
   al lavoro di review. Tolto ciò che non lo è, la lunghezza scende da sola.

   Fuori dal commento pubblicato, dentro il `review.md`: pavimento, corsia,
   promozione, copertura di riconoscimento, il campo `Lens` (dice da quale
   prompt viene il rilievo, non cosa farne) e la narrazione dell'ordine
   anti-anchoring.

   Dentro il commento, anche quando costa parole: severità e se blocca; ancore
   `path:riga` e numeri misurati; la conseguenza se lo si ignora; per le
   questioni aperte l'alternativa col suo costo, che è ciò che rende una domanda
   decidibile invece che retorica; e **cosa è stato eseguito e cosa no**, che
   non è metodologia ma la garanzia sul rilievo — senza, il lettore non può
   distinguere una misura da un'ipotesi. `Classification` resta: dice all'autore
   se può prendere il fix così com'è.

   La causa è strutturale, non stilistica: `rc-validate.sh` impone i campi e poi
   la prosa attorno li ripete in forma discorsiva; il validatore misura la
   presenza dei campi, mai la ridondanza fra campi e prosa, né la pertinenza di
   ciò che sta attorno. Intervento: il commento pubblicato diventa una
   **riduzione** dichiarata del `review.md`, con una lista chiusa di ciò che vi
   transita — e il resto resta nell'artefatto interno.

8. **La regola sull'evidenza non sa esprimere una dichiarazione.**
   `rc-validate.sh` esige almeno un'ancora `path:riga`. Alla passata 6 il
   rilievo "il corpo della PR non è stato aggiornato" è stato **rifiutato**:
   la sua evidenza è il corpo della PR, che non è un file del repository e non
   ha righe indirizzabili in quella forma. Ho aggirato aggiungendo un'ancora
   di codice, il che indebolisce il rilievo: punta a ciò che contraddice la
   dichiarazione, non alla dichiarazione.
   È strutturale, non incidentale: la lente di drift confronta il comportamento
   con ciò che è **dichiarato**, e le dichiarazioni vivono nel corpo della PR,
   nei messaggi di commit e nella documentazione. La forma dell'ancora deve
   ammettere anche una fonte non versionata — per esempio `pr#5 body:12` o
   `commit 2f69126 msg` — altrimenti la lente più caratteristica del metodo è
   l'unica che non riesce a citare la propria prova.

9. **Non esiste continuità del debito quando il cambiamento cambia identità.**
   La PR #4 è stata chiusa e riaperta come #5 sullo stesso branch. Il registro
   è indicizzato sulla PR, quindi il debito della passata precedente è
   scomparso: l'ho recuperato leggendo a mano i miei commenti in scratchpad.
   Su un branch di lunga durata — o su un autore che chiude e riapre per
   ripulire la storia — la review riparte da zero ogni volta. L'indice naturale
   è il branch, o la catena di commit, non il numero della PR.

10. **Il plugin non stabilisce mai la toolchain dichiarata.** Un progetto
    dichiara di quale interprete ha bisogno, e nessuno legge quella
    dichiarazione. Due avvistamenti:
    - `belt-configurator`: `package.json` dice `engines: {"node": ">=24 <25"}`;
      con Node 22 sul PATH `npm ci` rifiuta di installare e la suite è
      ineseguibile. La toolchain giusta era già sulla macchina, sotto
      `~/.nvm/versions/node/v24.13.1`.
    - `navigator`: `pyproject.toml` non dichiara nulla, ma il `python3` di
      sistema fallisce la collection per `httpx` mancante mentre
      `server/.venv/bin/python` dà 70/70 in tre secondi.

    In entrambi i casi, senza una ricerca manuale il plugin avrebbe dichiarato
    "suite non eseguita" su un progetto con una suite verde a portata di mano.
    Ed è il difetto che costa di più adesso: da 0.2.0-beta.1 la perturbazione è
    obbligatoria in corsia stretta, e la sua forma principale — eseguire — è
    proprio quella che una toolchain non stabilita rende impossibile.

    Intervento: prima di dichiarare una suite ineseguibile, cercare
    l'interprete. Le fonti sono poche e dichiarative: `engines` in
    `package.json`, `requires-python` in `pyproject.toml`, `rust-version` in
    `Cargo.toml`, `go` in `go.mod`, più i luoghi convenzionali dove una
    toolchain vive già (`.venv/`, `.nvm`, `.tool-versions`, `.python-version`,
    `.nvmrc`). Poche righe, non un gestore di versioni.

## Cosa ha funzionato, con evidenza

- **L'ordine anti-anchoring ha pagato tre volte.** Passata 1: la descrizione
  ometteva cinque filoni. Passata 2: la descrizione rivendicava una feature già
  su `main`, e la tabella file sbagliava sei righe su otto. Passata 4: la
  documentazione prometteva un comportamento cross-origin che il codice non ha.
  Nessuno dei tre sarebbe emerso leggendo prima le dichiarazioni: si sarebbero
  assorbite come vere.

- **Il gate d'intento in corsia stretta ha prodotto il risultato più utile della
  passata 1**, che non era un elenco di difetti ma la constatazione che il
  cambiamento non era ancora revisionabile. L'autore ha diviso la PR.

- **Il debito ha ripresentato da solo i giudizi aperti** all'inizio delle passate
  successive sulle stesse aree, ed è servito a verificare se fossero stati chiusi
  o solo spostati.

- **La promozione monotona della corsia** (il modello può solo alzare) è stata
  esercitata due volte e ha retto: un tentativo di declassamento resta bloccato
  dallo script.

- **`rc-validate.sh` ha intercettato una deviazione reale** su un output prodotto
  da un modello gratuito su opencode, e la regola sull'evidenza si è rivelata
  troppo stretta: ora richiede *almeno un'ancora* `path:riga` invece di esserlo.

## Il buco metodologico più grosso

**[CORRETTO in 0.2.0-beta.1 — passo di perturbazione, tre forme, sezione
obbligatoria in `review.md`.]** **La metodologia non prevede di far girare la
cosa.** Le lenti leggono file. Ma
in tre passate su cinque il rilievo decisivo è arrivato solo eseguendo il
software:

- passata 2: l'assertion di un test eseguita contro i file reali ha mostrato che
  non poteva passare, mentre il corpo dichiarava `70/70 ✓`;
- passata 4: il contrasto same-site / cross-site su Chrome reale ha mostrato che
  la feature legge la pagina ospite invece dell'iframe. Nessuna lettura statica
  ci sarebbe arrivata, e i 5 test E2E della PR non lo intercettano perché la loro
  fixture è same-origin.

- passata 5: entrambi gli esiti principali sono misurazioni, non letture. Che il
  difetto centrale fosse chiuso l'ho stabilito eseguendo le tre vie di selezione
  su un iframe cross-site e osservando che il titolo della pagina ospite restava
  invariato — cioè che l'espressione del chiamante non era girata da nessuna
  parte. E il rilievo nuovo bloccante — il threat model nega una modalità
  documentata della PR stessa — l'ho stabilito chiamando l'azione senza
  argomenti e leggendo `document.cookie` della pagina ospite. Entrambi
  irrefutabili proprio perché eseguiti; entrambi invisibili a chi legge.

  In più, una misura ha risolto una domanda di metodo che altrimenti restava
  aperta: **quale codice sto revisionando davvero.** Il default di `reload` è
  passato da `true` a `false` in questo cambiamento, quindi contando le
  richieste al server del frame durante una chiamata fallita (zero invece di
  tre) ho stabilito che l'estensione caricata nel browser era la versione sotto
  review e non la precedente. Senza quella verifica ogni misura successiva
  sarebbe stata attribuibile al codice sbagliato.

Proposta: in corsia stretta, un passo esplicito di **esercizio del cambiamento**,
con l'obbligo di dichiarare in `review.md` cosa è stato eseguito e cosa no. Oggi
lo si può fare, ma nulla lo chiede — e la sezione "Out of scope" è l'unico posto
in cui l'assenza si vede.

Corollario emerso alla passata 5: quando la verifica avviene contro un artefatto
vivo (un'estensione caricata, un servizio in esecuzione), il passo deve anche
**stabilire l'identità dell'artefatto** con una misura, non con un'assunzione.
Un discriminante osservabile fra la versione vecchia e la nuova è quasi sempre
disponibile nel diff stesso: qui era il cambio di un default.

Alla passata 7 il corollario ha pagato subito. Le prime tre misure davano
risultati incoerenti col diff; il discriminante — un campo del risultato che il
commit rimuove — ha mostrato che l'estensione caricata era ancora quella
precedente. Senza quel controllo avrei chiuso un rilievo come "non corretto"
misurando il codice sbagliato. Due lezioni per il passo di esercizio:
sceglierlo **prima** di misurare, non dopo aver visto risultati strani; e
cercare nel prodotto un modo di aggiornare l'artefatto — qui esisteva già
un'azione `reload_extension`, e non l'avevo cercata nelle due passate
precedenti, dove avevo chiesto il reload all'utente.

## Due controlli che nascono dal campo, non dal disegno

**Dopo un fix, chiedersi se l'asserzione distingue ancora i due mondi.** Alla
passata 7 il rilievo era: il test asserisce un valore che il codice non può
produrre. Alla passata 8 il meccanismo era corretto — misurato — ma il test
riscritto asserisce ora un valore che si ottiene *anche senza* il meccanismo.
Stessa classe di difetto, segno invertito, e il secondo è più insidioso perché la
suite è verde. Il controllo è meccanico: eseguire lo scenario **con e senza** la
cosa sotto test e confrontare ciò che il test guarda. Se le due colonne
coincidono, il test non sta verificando nulla. Nella passata 8 il discriminante
esisteva già nel risultato dell'azione e nessuno lo guardava.

**La mutazione è il modo di revisionare un test.** Sulla PR #29 di
claude-code-automation i test nuovi asserivano cose plausibili e la lettura non
bastava a distinguere quelli che mordono da quelli che no. Cinque mutazioni
mirate hanno chiuso la questione in un minuto: quattro producevano un solo
fallimento, quello giusto; una — togliere il campo `Recommendation` — ne
produceva zero, perché il grep cercava in un blocco troppo largo. Nessuna lettura
statica ci sarebbe arrivata. Per un cambiamento che aggiunge o modifica test, la
mutazione dovrebbe essere obbligatoria in corsia stretta, come l'esercizio lo è
per il codice.

## Osservazioni di processo, non sul plugin

- Dividere una PR ha avuto un effetto collaterale: tre dei cinque filoni sono
  finiti **direttamente su `main`** senza review.
- Ho ucciso due volte il bridge del progetto revisionato facendo `git checkout` e
  `git pull` nella sua directory mentre girava. Lezione: non mutare il working
  tree di un progetto mentre un suo processo è attivo. Alla passata 5 la regola
  ha retto: tutti i checkout sono avvenuti nel clone in scratchpad, il bridge è
  sopravvissuto all'intera sessione.
- Alla passata 5 l'autore ha chiuso la #4 e riaperto la #5 sullo stesso branch
  invece di continuare la stessa PR. La review non ne risente nel merito, ma
  spezza la continuità del debito (difetto 7) e rende la storia dei rilievi
  ricostruibile solo leggendo i commenti di una PR chiusa.
- `navigator` non ha CI. Metà dei difetti trovati nelle passate 2 e 3 — un test
  che non poteva passare, indentazioni perse che tornavano a ogni PR, cifre di
  suite dichiarate e non riproducibili — li chiuderebbe un workflow.

## Soglie: ora ci sono dati

Le tre soglie di `data/thresholds.json` sono ancora `null`, quindi il blocco per
stack ignoto e la promozione d'ufficio non hanno mai potuto scattare. Dalle
passate:

| Passata | File | Churn | Dispersione | Copertura riconoscimento |
| --- | --- | --- | --- | --- |
| 1 (PR #2) | 32 | 8065 | 5 | 0.9688 |
| 2 (PR #3) | 8 | 85 | 4 | 1.0000 |
| 3 (PR #3 fix) | 10 | 160 | 4 | 0.9000 |
| 4 (PR #4) | 15 | 713 | 5 | 0.9333 |
| 5 (PR #5) | 15 | 753 | 5 | 0.9333 |
| 6 (PR #5 fix) | 14 | 798 | 5 | 0.9286 |
| 7 (PR #6) | 14 | 865 | 5 | 0.9286 |
| 8 (PR #6 fix) | 14 | 894 | 5 | 0.9286 |
| 9 (PR #6 fix) | 3 | 19 | 3 | 1.0000 |
| 10–14 (cc-automation #29) | 9 → 3 | 275 → 24 | 5 → 3 | 1.0000 |

La copertura non è mai scesa sotto 0.90, e l'unico path mai non riconosciuto è
`.gitignore` — che andrebbe semplicemente aggiunto al catalogo dei ruoli.

## Le somme, dopo quindici passate

### Il principio unico che il campo ha prodotto

Le note sopra registrano due lezioni separate — *far girare il software* e
*mutare i test* — ma sono la stessa mossa applicata a due tipi di artefatto:
**perturbare e osservare**.

Su `navigator` l'artefatto è codice che gira, e ogni rilievo bloccante è venuto
dall'esecuzione: il fallback silenzioso al main frame, il threat model falso, il
`selector` che non risolve i `src` root-relative, il `reload` che non ricaricava.
Nessuno dei quattro è visibile a chi legge.

Su `claude-code-automation` l'artefatto sono prompt e test bash: non c'è niente
da eseguire. Lì la perturbazione è stata la **mutazione** — cancellare la cosa
che un test dichiara di proteggere e guardare se il test se ne accorge. Due
buchi trovati così: `STRUCT-PC-32` che non copriva `Recommendation` perché
cercava in un blocco troppo largo, e `STRUCT-PC-39` che falliva su una pura
riformulazione. Nessuno dei due è visibile a chi legge.

Lo stesso principio genera anche il terzo controllo, quello che ha preso il caso
più insidioso: **dopo un fix, eseguire lo scenario con e senza il meccanismo e
confrontare ciò che il test guarda.** Se le due colonne coincidono, il test non
verifica nulla. Alla passata 8 il test riscritto era passato da *impossibile* a
*tautologico*: la suite era verde ed era la seconda condizione a essere peggiore.

Conseguenza per il prodotto: in corsia stretta non serve un passo "esercizio del
cambiamento" e un passo "muta i test". Ne serve uno solo — **perturbazione** —
con tre forme dichiarate a seconda dell'artefatto: eseguire (codice), mutare
(test e regole), contrastare con e senza (fix). E l'obbligo di dichiarare in
`review.md` che cosa è stato perturbato e che cosa no, perché è la sola
differenza fra una misura e un'ipotesi.

Corollario già registrato sopra, che vale per tutte e tre le forme: prima di
perturbare, **stabilire l'identità dell'artefatto** con una misura. Ha evitato
tre misure sbagliate alla passata 7.

### Cosa ha guadagnato il pavimento deterministico

Poco, ed è la conclusione più scomoda. Su quindici passate:

- `rc-floor.sh` non ha **mai** riconosciuto il cambiamento più consequenziale.
  Cinque promozioni a mano, sempre per lo stesso motivo (confine di capacità).
- Le tre soglie sono `null`, quindi il blocco per stack ignoto e la promozione
  d'ufficio non sono mai scattati. Gli script hanno stampato `INERT:` come
  progettato — corretto, ma significa che quella parte non è stata collaudata.
- La hygiene lane non è mai partita: nessuna baseline verde stabilibile, perché
  il rilevamento delle suite non guarda oltre la radice (difetti 1, 2, 5).

Quel che ha guadagnato:

- `rc-validate.sh` ha intercettato una deviazione reale, e la sua stessa rigidità
  ha rivelato il difetto 8 (l'evidenza non sa citare una dichiarazione).
- La promozione monotona ha retto: un tentativo di declassamento è stato bloccato.
- `rc-recognize.sh` non è mai sceso sotto 0.90 e l'unico path mai riconosciuto è
  `.gitignore`: il catalogo di base regge, gli manca una riga.

### Cosa ha guadagnato la parte semantica

- L'ordine anti-anchoring ha pagato tre volte su tre PR diverse.
- Il gate d'intento ha prodotto l'esito singolo più utile di tutto il ciclo: la
  constatazione che la PR #2 non era revisionabile, e la sua divisione.
- Il debito ha funzionato finché l'identità del cambiamento è rimasta stabile, ed
  è svanito tre volte su tre quando la PR è stata chiusa e riaperta (difetto 9).
- La regola di pertinenza sui commenti, arrivata dall'utente e non dal disegno,
  ha dimezzato i commenti aumentando i rilievi dentro: 1075 → 502 parole.

### Ordine di intervento, per frequenza misurata

1. **Un solo passo di perturbazione in corsia stretta**, nelle tre forme sopra,
   con dichiarazione obbligatoria. È la fonte di quasi tutti i rilievi bloccanti.
2. **Segnali per i confini di capacità** (difetto 3). Cinque promozioni a mano su
   cinque occasioni: è il difetto con la frequenza più alta di tutti.
3. **Il commento pubblicato come riduzione dichiarata del `review.md`**
   (difetto 7). Già applicato a mano dalla passata 6 in poi; va codificato.
4. **Continuità del debito sul branch invece che sulla PR** (difetto 9). Colpito
   tre volte.
5. **Stabilire la toolchain dichiarata prima di dire "ineseguibile"** (difetto
   10). Due avvistamenti su tre repository, ed è quello che oggi costa di più:
   la perturbazione è obbligatoria in corsia stretta e la sua forma principale è
   eseguire.
6. **Rilevamento delle suite oltre la radice** (difetti 1, 2, 5). Sblocca la
   hygiene lane, che sul campo non è mai partita — ma solo dove manca la CI: su
   un repository che ce l'ha, `discover` ha già risposto correttamente.
7. **L'ancora dell'evidenza deve ammettere una dichiarazione** (difetto 8):
   `pr#5 body:12`, `commit 2f69126 msg`. Senza, la lente di drift non può citare
   la propria prova.
8. Il resto (difetti 4, 6): correzioni brevi, bassa frequenza.

### Errori miei, per completezza

Un rilievo **ritirato** perché poggiava su un modello sbagliato di
`isContentEditable`. Una teoria su IPv6 inseguita troppo a lungo. Il bridge del
progetto revisionato ucciso due volte da operazioni git nella sua directory. Una
mutazione tagliata male alla PR #29, che ha fatto fallire sette test invece di
uno e andava rifatta prima di poterne concludere qualcosa. Tutti e quattro sono
stati corretti dentro il ciclo, e tre dei quattro hanno prodotto una regola che
ora sta in queste note.
