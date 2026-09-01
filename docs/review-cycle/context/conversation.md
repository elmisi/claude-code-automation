# Conversazione originale normalizzata

> Stato: materiale di discovery, non specifica approvata.
>
> Trascrizione normalizzata della conversazione ChatGPT “Code review nell'era
> AI” del 26 agosto 2026, fornita dall'utente come input per questo prodotto.
> La sessione originale si è svolta in gran parte in modalità vocale: le
> trascrizioni audio sono state ricomposte e ripulite dalle esitazioni, dalle
> sovrapposizioni e dai riempitivi, conservando proposte, esempi e preferenze.
> L'ultima parte della sessione è una deep research con citazioni, riportata
> qui in forma condensata.
>
> Non trasformare una proposta dell'assistente in un requisito approvato senza
> conferma esplicita dell'utente.

## 1. Tesi della conversazione

Si passa dalla review del **codice** alla verifica del **cambiamento**. Meno
caccia al refuso, più domande su intenzione, coerenza architetturale e rischio.
I nit diventano patch automatizzate o batch; l'attenzione umana si concentra su
ciò che non è banale invertire.

Formulata in negativo, che è la forma che l'utente ha ritenuto più forte: non
automatizzare la vecchia code review, ma ridisegnarla per un mondo in cui
produrre e modificare codice costa molto meno.

## 2. Il problema di partenza

L'utente descrive uno scenario concreto e ricorrente. Sta revisionando codice
che va sostanzialmente bene, ma contiene piccoli refusi, documentazione che
cita cose sbagliate, minuzie.

Il modello classico produceva una pioggia di micro-commenti; l'autore li
leggeva, sistemava, faceva un commit, e la review si chiudeva. Con gli agenti
quel flusso degenera:

```text
reviewer → agente che scrive N commenti sulla PR
        → autore → agente che legge i commenti e produce i fix
        → nuovo push → reviewer deve rivedere di nuovo
```

L'utente identifica due costi: perdita di tempo su entrambi i lati e consumo di
risorse inutile. Ma rifiuta anche la soluzione opposta: se quei refusi vengono
trascurati sistematicamente, si accumulano fino a diventare un debito costoso.

## 3. Cambio di paradigma: i nit diventano fix, non thread

La proposta dell'utente è cambiare il paradigma del commento di review. Invece
di aprire commenti, applicare direttamente i fix e aggiungere due o tre commit
alla PR dell'autore.

L'assistente accetta la proposta con una condizione: i fix devono essere
davvero meccanici e non cambiare il comportamento, e vanno separati in commit
etichettati, così che l'autore sappia cosa è stato toccato e perché senza
dover decifrare dieci commenti. I commenti umani restano solo dove serve
davvero un giudizio.

L'utente aggiunge quattro vincoli propri per il prompt che guiderà l'agente:

1. modifiche non logiche, solo aggiustamenti;
2. circoscritte alle modifiche presenti nella PR, senza uscire dal perimetro;
3. concise, sintetiche, chiare e facilmente comprensibili;
4. un commit per ogni gruppo di miglioramenti.

L'assistente osserva che il prompt deve essere un contratto operativo, non una
richiesta generica, e che a livello di team va reso esplicito che aggiungere
commit alla PR altrui è accettato, altrimenti si genera attrito.

## 4. Contratto operativo della hygiene lane

Checklist prodotta nella conversazione per una “AI hygiene review”.

| # | Voce | Contenuto |
| --- | --- | --- |
| 1 | Scopo | Distinguere review decisionale da review di igiene. Commentare solo quando serve un giudizio. |
| 2 | Perimetro | Solo file e righe cambiate dalla PR, più il minimo contesto. Niente pulizie fuori scope. |
| 3 | Modifiche consentite | Refusi, commenti obsoleti se ovvi, docstring chiare, lint, formattazione, import, naming locale non pubblico. |
| 4 | Modifiche vietate | Logica di business, API, schema, dipendenze, configurazioni, ottimizzazioni speculative. |
| 5 | Strategia di commit | Pochi commit tematici, messaggi chiari, reversibili, mai mescolati con la logica. |
| 6 | Output richiesto | Fix applicati più un riepilogo breve: file toccati, tipo di modifiche, conferma di nessun cambio comportamentale, punti lasciati volutamente aperti. |
| 7 | Policy di team | I nit non diventano thread: si automatizzano o si raggruppano. I commenti restano per le decisioni. Aggiungere commit alla PR altrui deve essere norma condivisa. |
| 8 | Red flag | Troppi micro-commit, refactor fuori scopo, commenti soggettivi. Se devi spiegare perché “non cambia la logica”, probabilmente non è un nit. |

L'ottava voce è il criterio di confine più utile emerso nella conversazione:
la necessità di argomentare l'assenza di impatto comportamentale è essa stessa
il segnale che la modifica richiede giudizio umano.

## 5. Le tre corsie di profondità

L'utente introduce il secondo asse: con gli LLM cambiare il codice è
facilissimo, quindi su codice non critico — inizio progetto, intranet non
ancora rilasciata, pochi utenti — si può far scorrere molto.

L'assistente riformula il punto in modo che l'utente adotta: gli LLM rendono
economico cambiare il codice, non rendono economico cambiare una direzione
sbagliata. La domanda non è più “questo è pulito?” ma “quanto è costoso se
sbagliamo qui?”.

| Corsia | Esempio | Obiettivo della review |
| --- | --- | --- |
| Veloce | Pagina demo su intranet con dati finti. | Non rompere nulla e mantenere leggibilità minima. Merge anche se non è perfetto. |
| Normale | Flusso che salva dati veri ma non sensibili. | Modello dati, gestione errori, test, coerenza con i pattern. I nit si automatizzano, l'umano guarda il disegno. |
| Stretta | Permessi e ruoli, migrazione di database. | Piano di rollback, test negativi, threat modeling, approvazione umana obbligatoria. |

Conclusione esplicita: non tutte le review diventano più leggere, diventano
**selettive**. Molte più veloci, alcune più attente di prima.

## 6. Le tre lenti

L'utente chiede di riprendere i tre punti cardine enunciati all'inizio della
conversazione. Sono intenzione, architettura e rischio, e nella parte finale
della sessione ricevono questa definizione:

- **Intento** — verifica che la modifica risolva davvero il problema che doveva
  risolvere, in modo coerente con l'obiettivo dichiarato. Domanda guida:
  *stiamo costruendo la cosa giusta?*
- **Architettura** — verifica che la soluzione si inserisca correttamente nel
  sistema, rispettandone confini, pattern, responsabilità e direzione tecnica.
  Domanda guida: *la stiamo costruendo nel posto e nel modo giusto?*
- **Rischio** — valuta le conseguenze di un errore: probabilità, impatto, blast
  radius, rilevabilità e reversibilità. Domanda guida: *se questa scelta è
  sbagliata, quanto ci costa?*

Le tre lenti **non si sovrappongono**. Una PR può avere intento corretto,
essere architetturalmente sbagliata e avere comunque rischio basso perché
facilmente reversibile. Oppure essere perfettamente progettata e ad alto
rischio perché tocca autenticazione, dati o contratti pubblici.

Forma compatta: *intento = perché; architettura = come e dove; rischio = cosa
succede se sbagliamo.*

## 7. Il passaggio di consegne d'intento

L'utente osserva che in teoria l'intenzione dovrebbe già essere esplicita nella
card da cui nasce la modifica o nei commenti di chi apre la PR.

L'assistente contesta il “in teoria”: molta intenzione resta implicita nelle
teste e non arriva nella descrizione della card. Nella nuova review la prima
attività non è leggere il diff, ma **ricostruire il contratto di intenzione**.
Se quello è debole, il primo commento non riguarda il codice ma la chiarezza
dell'obiettivo.

L'utente aggiunge il caso che lo riguarda direttamente: spesso è lui il
committente della task, quindi conosce l'intenzione meglio di chi ha scritto il
codice. In quel caso il suo ruolo è rendere l'intenzione **ispezionabile, non
presunta**: prima o durante la PR deve esserci un passaggio di consegne che
contenga intento, criteri di accettazione, vincoli e focus della review. Così
chi implementa — umano o AI — non indovina, e chi verifica non valida contro un
fantasma ma contro un contratto condiviso.

Nasce qui l'ipotesi di una sezione “Intent Review” obbligatoria.

## 8. I tre prompt abbozzati

### 8.1 Intent Review

- **Ruolo**: verificare se la PR implementa davvero l'intenzione dichiarata.
  Non fare una review generica.
- **Input obbligatorio**: intenzione dichiarata fra virgolette, più diff o
  riassunto del diff.
- **Processo**: riscrivere l'intento con parole proprie; estrarre comportamento
  atteso e non-intenzioni, se presenti; confrontare ogni cambiamento con quel
  contenuto; segnalare mismatch, assunzioni non dichiarate e rischi introdotti;
  non commentare stile, naming o formattazione salvo impatto sull'intento.
- **Output**: riformulazione dell'intento; verdetto sintetico fra *allineata*,
  *parziale*, *non allineata*, *non determinabile*; elenco puntato dei soli
  problemi ad alto impatto con severità; domande aperte se mancano
  informazioni; cosa è esplicitamente fuori ambito.
- **Frase chiave da includere**: *ottimizza per poche osservazioni ad alto
  segnale, non per quantità.*

### 8.2 Architecture Review

Input: principi architetturali dichiarati, o una breve descrizione dello stile
atteso, più il diff. Output: la modifica rispetta confini e pattern stabiliti?
Se devia, spiegare l'impatto e suggerire alternative — poche, ad alto impatto.

### 8.3 Risk Review

Input: diff più contesto d'uso. Output: livello di rischio basso, medio o alto;
perché; cosa succede se è sbagliato; come lo si rileva; come si fa rollback.
Evitare stile e micro-fix. Obiettivo dichiarato: massimizzare la segnalazione
per riga, non il numero di commenti.

## 9. Ricognizione della letteratura recente

L'utente chiede una ricerca su contributi non più vecchi di tre mesi, con
impatto e punto di vista significativo. La ricerca copre il periodo dal
26 maggio al 26 agosto 2026 e scarta il materiale che tratta l'“AI code review”
come semplice automazione del vecchio processo.

Convergenze rilevate, con le fonti principali:

| # | Convergenza | Fonti |
| --- | --- | --- |
| C-1 | Il collo di bottiglia si è spostato dalla produzione alla verifica. | Thoughtworks, *Supervisory engineering: orchestrating software's middle loop* (3 giugno); Pragmatic Engineer, *concern about massive increase in code review load* (23 luglio). |
| C-2 | La review sale di livello: intento, architettura, rischio. | Thoughtworks, *The code review is dead; long live the code review* (25 giugno); David Poll, GitHub Code & Review (13 agosto). |
| C-3 | La profondità della review non dovrebbe più essere uniforme. | GitHub, livelli di review; Qodo, *Building an Adaptive Router for Code Review Depth* (30 luglio), con corsie Fast, Balanced, Deep e Skip. |
| C-4 | Ciò che è deterministico deve smettere di essere conversazione. | Cisco AI Harness Toolkit, classificazione `auto-fixable` / `needs-human` (30 giugno); Tessl, *verifiers*; GitHub Agentic Autofix. |
| C-5 | L'AI-to-AI review esiste già su larga scala, ma non è dimostrata efficiente. | Studio del 21 agosto: 248.641 PR AI-authored con review AI, 45.269 casi cross-product. Gli autori misurano il fenomeno, non ne dimostrano l'efficienza. |

Contributi tecnici usati come riferimento di architettura:

- **OpenAI Codex `code-review`** — una skill orchestratrice lancia separatamente
  le skill `code-review-*`, con lenti distinte per breaking changes, dimensione
  del cambiamento, contesto e testing; dal 26 giugno l'orchestratore è aperto a
  skill definite dall'utente. Conferma il modello *orchestratore + lenti*
  invece di un unico prompt monolitico.
- **Microsoft HVE Core – Code Review** (18 giugno) — context bootstrap,
  selezione della profondità, prospettive separate, evidence-first, profondità
  proporzionale al rischio.
- **Cisco AI Harness Toolkit – Code Review** (30 giugno) — lane parallele e
  classificazione di ogni finding come `auto-fixable` o `needs-human`; i fix
  deterministici entrano in un loop automatico, gli altri no. È il riscontro
  più diretto all'intuizione iniziale dell'utente.
- **GitHub Copilot Code Review + Agent Skills + MCP** (GA 29 luglio) — la review
  può usare skill custom e recuperare via MCP issue tracker, documentazione e
  service catalog. GitHub afferma esplicitamente che molta dell'informazione
  necessaria a un reviewer non è nel diff.
- **GitHub, *Better tools made Copilot code review worse*** (10 luglio) —
  strumenti migliori hanno inizialmente prodotto costi maggiori e meno issue
  trovate; la qualità è tornata riscrivendo il workflow attorno all'evidenza
  specifica della PR. L'harness e il protocollo contano quanto il modello.

Riferimenti empirici citati come fondamento: ARCTIC, *From Code Review to Code
Critique* (31 luglio), con intent prediction, drift detection e code spotlight
su una tassonomia derivata da 18.000 review; *3100 Opinions on Code Review in an
AI World* (8 luglio), che descrive la review come control point; *From
Human-Centric to Agentic Code Review* (14 luglio), su 1,02 milioni di PR, che
mostra decisioni più rapide ma non automaticamente review migliori; *Code Review
is a Conversation* (24 luglio), che critica il paradigma “diff seguito da una
serie di commenti” e difende il reviewer conversazionale.

## 10. Correzioni al modello iniziale prodotte dalla ricerca

Quattro correzioni che la conversazione registra esplicitamente come modifiche
all'ipotesi di partenza.

1. **Anti-anchoring.** Alcune skill recenti ricostruiscono prima in modo
   indipendente cosa fa il diff, poi leggono PR e ticket, e infine confrontano
   le due cose. L'intento dichiarato va verificato, non assunto come verità.
   Questo permette anche di rilevare *intent drift*.
2. **Fase di acquisizione del contesto.** Poiché l'informazione necessaria non
   è nel diff, la review moderna ha bisogno di una propria fase di context
   acquisition prima dell'analisi.
3. **Orchestratore più lenti separate**, non un unico grande prompt di review.
4. **La hygiene lane come quarto elemento che non è una review.** Non produce
   opinioni: prende refusi, formattazione, lint, documentazione ovvia e altre
   modifiche deterministiche e, quando possibile, le materializza come fix
   verificato, lasciando all'umano solo ciò che richiede giudizio.

Come contrappeso, la conversazione registra anche che **non tutti i commenti
sono rumore**: una discussione architetturale può essere essa stessa il
prodotto della review.

## 11. Formula riassuntiva

```text
Change
  → context acquisition
  → risk routing
  → lenti: intento | architettura | rischio
  → deterministic fix lane
  → giudizio umano solo dove resta incertezza
```

Tesi finale della sessione: il futuro della review non è un reviewer AI che
imita un collega umano più velocemente, ma un sistema che decide **cosa non
vale più la pena revisionare**, **cosa può essere verificato automaticamente** e
**dove concentrare il giudizio umano**, che è la risorsa scarsa e costosa.

## 12. Destinazione dichiarata del materiale

L'utente dichiara più volte che la conversazione serve come input per un
secondo processamento, in vista di un articolo da pubblicare sul blog. La
costruzione di una skill è una decisione presa successivamente, in questa
sessione, e non è un requisito espresso nella conversazione originale.
