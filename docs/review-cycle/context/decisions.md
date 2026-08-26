# Decisioni estratte

> Stato: distillazione. Le decisioni sono divise per **provenienza**, perché
> hanno peso epistemico diverso: quelle della conversazione originale sono
> posizioni espresse dall'utente parlando di un articolo; quelle di sessione
> sono scelte prese deliberatamente per costruire il plugin `review-cycle`.
> Non promuovere una proposta a requisito senza conferma esplicita.

## A. Decisioni confermate nella conversazione originale

| ID | Decisione | Evidenza |
| --- | --- | --- |
| D-01 | L'oggetto della verifica è il **cambiamento**, non il codice: si passa da *reviewing code* a *verifying changes*. | [conversazione §1](conversation.md#1-tesi-della-conversazione) |
| D-02 | Il ping-pong “agente commenta → agente corregge → umano rivede” è un costo da eliminare, non da ottimizzare. | [§2](conversation.md#2-il-problema-di-partenza) |
| D-03 | Ignorare i refusi non è la soluzione alternativa: accumulati diventano debito costoso. | [§2](conversation.md#2-il-problema-di-partenza) |
| D-04 | I nit non diventano thread: diventano fix applicati, raccolti in pochi commit tematici etichettati. | [§3](conversation.md#3-cambio-di-paradigma-i-nit-diventano-fix-non-thread) |
| D-05 | La fix lane non può cambiare il comportamento e non può uscire dal perimetro del cambiamento. | [§3](conversation.md#3-cambio-di-paradigma-i-nit-diventano-fix-non-thread), [§4](conversation.md#4-contratto-operativo-della-hygiene-lane) |
| D-06 | Esiste un catalogo esplicito di modifiche consentite e vietate alla fix lane. | [§4](conversation.md#4-contratto-operativo-della-hygiene-lane) |
| D-07 | La fix lane deve chiudere con un riepilogo che dichiari i file toccati, le categorie, l'assenza di cambio comportamentale e ciò che è stato lasciato volutamente aperto. | [§4](conversation.md#4-contratto-operativo-della-hygiene-lane) |
| D-08 | Criterio di confine: se serve argomentare perché una modifica “non cambia la logica”, non è un nit. | [§4](conversation.md#4-contratto-operativo-della-hygiene-lane) |
| D-09 | La profondità della review non è uniforme: esistono corsie diverse scelte in base a rischio e reversibilità. | [§5](conversation.md#5-le-tre-corsie-di-profondità) |
| D-10 | La selettività non significa leggerezza: la corsia stretta è più severa della review tradizionale. | [§5](conversation.md#5-le-tre-corsie-di-profondità) |
| D-11 | Le lenti sono tre — intento, architettura, rischio — e sono ortogonali fra loro. | [§6](conversation.md#6-le-tre-lenti) |
| D-12 | L'intento va reso ispezionabile, non presunto: serve un passaggio di consegne con obiettivo, criteri di accettazione, vincoli e focus della review. | [§7](conversation.md#7-il-passaggio-di-consegne-dintento) |
| D-13 | Se l'intento è debole, il primo output non riguarda il codice ma la chiarezza dell'obiettivo. | [§7](conversation.md#7-il-passaggio-di-consegne-dintento) |
| D-14 | Metrica di qualità della review: poche osservazioni ad alto segnale, non quantità. | [§8](conversation.md#8-i-tre-prompt-abbozzati) |
| D-15 | Ogni lente dichiara esplicitamente cosa ha lasciato fuori ambito. | [§8](conversation.md#8-i-tre-prompt-abbozzati) |
| D-16 | L'intento dichiarato va verificato, non assunto: si ricostruisce prima il comportamento del diff, poi lo si confronta con l'intento. | [§10](conversation.md#10-correzioni-al-modello-iniziale-prodotte-dalla-ricerca) |
| D-17 | Serve una fase di acquisizione del contesto prima dell'analisi, perché l'informazione necessaria non è nel diff. | [§10](conversation.md#10-correzioni-al-modello-iniziale-prodotte-dalla-ricerca) |
| D-18 | Architettura a orchestratore più lenti separate, non un unico prompt monolitico. | [§10](conversation.md#10-correzioni-al-modello-iniziale-prodotte-dalla-ricerca) |
| D-19 | Ogni finding è classificato `auto-fixable` oppure `needs-human`. | [§9](conversation.md#9-ricognizione-della-letteratura-recente), [§10](conversation.md#10-correzioni-al-modello-iniziale-prodotte-dalla-ricerca) |
| D-20 | Contrappeso accettato: non tutti i commenti sono rumore; una discussione architetturale può essere il prodotto della review. | [§10](conversation.md#10-correzioni-al-modello-iniziale-prodotte-dalla-ricerca) |

## B. Decisioni prese nella sessione di design del 26 agosto 2026

Non provengono dalla conversazione originale. Sono scelte esplicite dell'utente
durante il brainstorming del plugin.

### Perimetro e forma

| ID | Decisione | Motivazione |
| --- | --- | --- |
| S-01 | Il prodotto è un plugin `review-cycle` che implementa la **pipeline completa**: change brief, contratto d'intento, routing, lenti, triage, hygiene lane. | Scelta fra tre perimetri; l'utente ha scelto quello pieno. |
| S-02 | Il core opera su un **range git locale** (`base...head`). Gli adapter esterni sono opzionali e servono solo ad arricchire il contesto. | Funziona ovunque e degrada con grazia. |
| S-03 | Le lenti sono **skill componibili** invocabili singolarmente, sul modello di `plan-cycle`, non subagent. | Invocabilità singola e uniformità fra runtime. |
| S-04 | **Nessun `context: fork`.** Comportamento identico su Claude Code, Codex e OpenCode. | Il plugin Codex deve poter essere usato anche da OpenCode. |
| S-33 | Le lenti girano **in parallelo nelle corsie normale e stretta dove il runtime supporta i subagent**, serialmente altrove. Il supporto va rilevato, non assunto. L'input di ogni lente è esattamente `change-brief.md` più `intent.md`, così il risultato non dipende dalla modalità di esecuzione. | Parallelo contro seriale cambia il tempo, non il risultato. Effetto collaterale: su Claude Code l'anti-anchoring torna a essere anche strutturale, senza che l'esito su Codex e OpenCode debba differire. |
| S-05 | Nome del plugin: **`review-cycle`**. | Coerenza col marketplace esistente, come fratello di `plan-cycle`. |
| S-06 | **Sei skill**: orchestratore, contratto d'intento, drift, architettura, rischio, igiene. Il contratto d'intento è invocabile da solo, senza far partire alcun giudizio. | Rende il passaggio di consegne d'intento un atto indipendente dalla review. |
| S-28 | **Layer di script**: la contabilità deterministica esce dal prompt — matching dei segnali e calcolo del pavimento, copertura del riconoscimento, inventario del diff, scoperta ed esecuzione delle suite, registro, debito, volume cumulato, validazione di forma degli esiti. Al modello resta la semantica: ricostruzione del comportamento, deduzione dell'intento, le tre lenti, la classificazione, la promozione della corsia. | Non è un risparmio: il pavimento è deterministico solo se lo calcola del codice, e il filtro sulla conseguenza dichiarata filtra solo se qualcosa lo verifica. In prosa quelle decisioni restano auspici. |
| S-29 | La metodologia è **divisa per lente** e caricata su richiesta. Il materiale specifico della corsia stretta non entra in una passata leggera. | Il costo di una passata scala con la corsia invece di essere costante. |
| S-30 | **Nessun budget e nessun tetto di righe** per skill o per corsia. | Un tetto misura la cosa sbagliata e induce compressione silente della qualità dell'output invece che del problema. |
| S-34 | Il layer di script è **bash più `jq`**, come il resto del repository. L'estrazione del comando dei test dal workflow di CI non è compito dello script ma **del modello, una volta sola per repository**, con il risultato memorizzato nel registro: leggere uno YAML arbitrario è lavoro semantico, e trattarlo così evita di introdurre un parser o una dipendenza in sandbox altrui. Se la contabilità in bash diventasse illeggibile, aggiungere Python resta possibile senza toccare altre decisioni. | Una sola tecnologia nel repository, nessuna dipendenza da installare, e i test di struttura esistenti continuano a valere. |
| S-31 | **Nessun ramo condizionale nei prompt delle skill.** La selezione la fa lo script; l'orchestratore invoca solo ciò che serve e passa la profondità come parametro. Ogni skill è un'istruzione lineare. | I rami condizionali sono il principale nemico dello scrupolo di esecuzione, soprattutto sui modelli piccoli con cui il plugin può girare su OpenCode. |

### Hygiene lane

| ID | Decisione | Motivazione |
| --- | --- | --- |
| S-07 | La lane **applica i fix e crea commit locali, ma non fa mai push**. Nessuna apertura di PR, nessuna pubblicazione di commenti senza gesto umano. | Elimina il ping-pong senza agire verso l'esterno senza gate; tutto reversibile con git. |
| S-08 | L'assenza di cambio comportamentale è dimostrata da **suite verde prima e dopo**. Se la suite non è verde all'inizio la lane non parte; se un commit la rompe, quel commit viene revertito e il fix riclassificato come giudizio umano. | È la garanzia più ampia disponibile senza un parser per linguaggio. |
| S-09 | Chiusura ricorsiva della verifica: i **file di test sono fuori perimetro**. *(Irrigidita il 2026-08-27 da S-35: l'eccezione originaria per le categorie che non eseguono è stata rimossa.)* | Una verifica vale solo se l'artefatto che verifica non è modificabile da ciò che verifica. Stessa logica già applicata a configurazione di lint e CI. |
| S-22 | Il comando dei test viene dal **workflow di CI**, che è la fonte autorevole. Ma la CI non è un censimento: il plugin enumera comunque le suite presenti nel repository e segna quali la CI non esegue. Tutte vengono eseguite prima di iniziare; quelle verdi entrano nel gate. `hygiene.md` dichiara sempre cosa è entrato nel gate e cosa no. | Il comando su cui il team ha già concordato vale più di un'euristica, ma esistono test fuori CI che comunque non devono rompersi. |
| S-23 | Una suite fuori CI **già rossa o non eseguibile** nell'ambiente locale resta fuori dal gate e viene dichiarata come copertura mancante, con il motivo. La lane parte se la suite autorevole è verde. | Legare la potenza della lane a condizioni esterne al cambiamento la terrebbe depotenziata proprio sui progetti veri. Un punto cieco dichiarato è una difesa più onesta di una restrizione che nessuno toglierà. |
| S-35 | **I file di test sono interamente fuori perimetro, senza eccezioni.** La verifica è un'intersezione di insiemi — `file modificati dalla lane ∩ file che corrispondono ai pattern di test == ∅` — calcolabile con `git diff --name-only` e i glob del catalogo. Il confronto dell'insieme dei test raccolti resta come **verifica aggiuntiva** dove il comando di collect è noto e funziona, e intercetta i casi in cui la raccolta cambia indirettamente; dove il comando non è noto, `hygiene.md` lo dichiara come copertura mancante. Un refuso in un commento dentro un file di test non viene corretto dalla lane: diventa un giudizio umano. | L'eccezione "salvo le categorie che non eseguono" era l'unico punto del protocollo che richiedeva di interpretare il contenuto di un hunk, cioè un parser o un giudizio. Rimuovendola la verifica diventa meccanica, indipendente da linguaggio e runner, e vale anche sugli stack che il catalogo non riconosce. È la lettura più fedele alla chiusura ricorsiva: se la suite è lo strumento che verifica, lo strumento non si tocca. |
| S-32 | La suite viene eseguita **una volta sola sull'insieme dei fix**, non dopo ogni commit: se verde, si committa per categoria; se rossa, bisezione per categoria per isolare il gruppo colpevole, che viene scartato e riclassificato come giudizio umano. | Le esecuzioni della suite dominano il tempo di una passata. Da N a una nel caso normale. **Indebolimento dichiarato**: la garanzia vale sullo stato finale del branch, non più su ogni singolo commit intermedio preso da solo. |

### Routing

| ID | Decisione | Motivazione |
| --- | --- | --- |
| S-10 | La regola deterministica fissa il **pavimento**; il modello può solo **promuovere** a una corsia più severa, motivando per iscritto, mai declassare. | Rende deterministico il punto in cui l'errore è invisibile — lo skip — lasciando al modello il solo potere di essere più prudente. |
| S-11 | Le regole vivono **solo nel plugin**, come catalogo fisso di segnali. L'estrazione delle aree sensibili è applicazione meccanica di quei segnali all'albero del progetto e al diff, non valutazione. La mappa risultante entra nel change brief. | Nessuna configurazione per progetto; il pavimento resta riproducibile perché è riconoscimento, non giudizio. |
| S-24 | Il catalogo è a **due strati**: segnali indipendenti dallo stack (dimensione e dispersione del diff, file di lock, workflow di CI, file di configurazione, estensioni come `.sql`, path contenenti `migration`, `auth`, `secret`, `permission`, file modificati privi di test associati) e segnali specifici dello stack quando è riconosciuto. Il change brief dichiara quale strato ha risposto. | Su uno stack ignoto il pavimento non è cieco, è più grossolano — e si vede quando l'analisi è stata approssimativa. |
| S-25 | **Controllo di copertura del riconoscimento come primo passo**, prima del change brief: quanta parte dei file toccati il catalogo sa collocare e se esiste almeno un manifest riconosciuto. Sotto soglia il plugin si ferma, elenca ciò che non ha riconosciuto e chiede all'utente di collocarlo. La risposta è ricordata nel registro del progetto. | Il controllo costa niente, tutto ciò che viene dopo costa: non si spende effort che potrebbe essere inutile. Troppo materiale non riconosciuto è di per sé un segnale anomalo. |

### Intento

| ID | Decisione | Motivazione |
| --- | --- | --- |
| S-12 | L'intento è **dedotto da commit e descrizione della PR** dopo la chiusura del change brief, presentato all'utente e da lui **validato o corretto**. L'intento validato è input di tutto il resto. | Commit e descrizione sono dichiarazioni dell'autore, non il codice; la validazione umana rende l'intento attestato invece che inferito. |
| S-13 | La proposta d'intento deve segnalare esplicitamente **cosa non è riuscita a determinare** e quali parti poggiano su poco. | Senza questo la validazione diventa un timbro. |
| S-14 | Il gate è **proporzionato alla corsia**: veloce nessun contratto richiesto; normale richiesto ma sbloccabile con un “non lo so” esplicito che resta scritto; stretta contratto validato obbligatorio. La copertura è contata per singolo criterio, non come verdetto binario. Marcato **rivedibile dopo il primo uso reale**. | Il gate scala col rischio come il resto della pipeline. L'utente ha accettato riservandosi di rivederlo. |

### Esiti e accumulo

| ID | Decisione | Motivazione |
| --- | --- | --- |
| S-15 | **Due tipi di esito**: *finding* (difetto, con severità) e *questione aperta* (decisione da prendere, senza severità). Una questione aperta è ammessa solo se nomina almeno un'alternativa concreta e il suo costo. | Scioglie la tensione fra “poche osservazioni ad alto segnale” e “non tutti i commenti sono rumore”. |
| S-16 | Ogni esito **dichiara cosa succede se lo si ignora**; senza conseguenza dichiarata non entra nell'elenco. Nessun tetto numerico per corsia. | Agisce sulla causa del rumore invece che sul sintomo, senza perdere informazione. |
| S-17 | I giudizi umani **restano file**, accompagnati da una versione già formattata da incollare nella PR. Nessuna pubblicazione automatica. | Funziona su GitHub e Bitbucket allo stesso modo e mantiene S-07. |
| S-18 | **Registro delle passate** (range, corsia, aree toccate, esiti non chiusi) più **file di debito** dei giudizi mai chiusi, che ogni passata rilegge e ripresenta. L'accumulo su un'area promuove d'ufficio la passata successiva. | Rende l'accumulo un innesco automatico e impedisce che i giudizi evaporino. |
| S-26 | La promozione d'ufficio scatta su due criteri combinati: **volume cumulato non revisionato** per area (righe passate in corsia leggera) e **presenza di giudizi aperti** che toccano quell'area. | Il volume intercetta la deriva silenziosa, i giudizi aperti intercettano ciò che era già stato visto e lasciato lì; insieme non richiedono di misurare il tempo. |
| S-19 | La **deriva architetturale cumulativa è fuori perimetro**: rimando esplicito a `refactor-discovery`. | È già il suo mestiere; duplicarlo qui significherebbe farlo peggio. |

### Validazione

| ID | Decisione | Motivazione |
| --- | --- | --- |
| S-20 | Validazione su PR reali di **`digi-pep/belt-configurator`** e sulle PR aperte di **`digi-pep/configurator-backend`**. | È il contesto da cui la conversazione è nata e l'unico banco che misura se il ping-pong sparisce davvero. |
| S-21 | Un **cambiamento sintetico con difetti piantati** entra nella suite del repository come fixture di regressione delle lenti e del triage. | Impedisce che le lenti regrediscano senza accorgersene. |
| S-36 | Un'**area**, ai fini del volume cumulato, è una directory di primo livello sotto la radice sorgente rilevata: se il repository ha un'unica directory di primo livello contenente codice, si scende di un livello. La profondità è calcolata **una volta per repository e memorizzata nello stato operativo**, come il comando dei test, così la chiave dell'area resta stabile fra passate. Chiude `Q-10`. | La chiave deve essere stabile o non si accumula nulla; la sola directory di primo livello degenera sui repository con un'unica radice sorgente, dove la promozione diventerebbe globale invece che mirata. |
| S-27 | Tutte le **soglie numeriche** — copertura del riconoscimento, volume cumulato non revisionato, numero di giudizi aperti — sono parametri da tarare sul primo uso reale, non valori fissati a priori. | Un numero inventato adesso avrebbe l'aria di una regola senza esserlo. |

## C. Vincoli di processo derivati

- L'unica skill che modifica il working tree è quella di igiene.
- Nessuna skill esegue `git push`, apre PR o pubblica commenti.
- Il change brief è scritto e chiuso prima che qualunque dichiarazione d'intento
  entri nel contesto. Le altre skill rifiutano di partire se il change brief non
  esiste.
- Il routing decide quali lenti girano e con quale profondità; non decide mai il
  livello di autonomia di scrittura, che è fisso.
- Un esito `auto-fixable` non genera mai un commento; un esito `needs-human` non
  viene mai risolto automaticamente. Nel dubbio, `needs-human`.
- I pattern che identificano i file di test sono portanti quanto i segnali del
  pavimento: un file di test che nessun pattern riconosce viene trattato dalla
  lane come un sorgente qualunque. Il controllo di copertura del riconoscimento
  lo copre solo parzialmente, quindi quei pattern vanno testati come i segnali.
- Il registro rende tracciabile anche la corsia `skip`, che altrimenti sarebbe
  l'unico esito senza traccia, e gestisce le passate ripetute sullo stesso
  branch come righe successive invece che come sovrascritture.
- Il registro ospita anche lo **stato operativo** del progetto — comando dei
  test, collocazione di ciò che il catalogo non riconosce — che è cosa diversa
  dalla policy esclusa da S-11: non decide se un cambiamento va revisionato,
  evita solo di rifare la stessa domanda a ogni passata.

## D. Debiti consapevoli

| ID | Debito | Perché è stato accettato |
| --- | --- | --- |
| DB-01 | L'anti-anchoring poggia su ordine di esecuzione e su file, non sull'isolamento del contesto. Parzialmente ripagato da S-33: dove i subagent esistono, nelle corsie normale e stretta l'isolamento c'è anche strutturalmente. Resta scoperto ovunque il parallelismo non sia supportato e nelle corsie leggere. | Uniformità del risultato fra Claude Code, Codex e OpenCode. |
| DB-02 | Nessun artefatto di policy versionato per progetto: la regola che decide se un cambiamento viene revisionato non è discutibile in una PR e non registra ciò che il team impara. | Zero configurazione. Si può aggiungere in seguito senza rompere nulla. |
| DB-03 | Il gate proporzionato alla corsia poggia su plausibilità, non su evidenza. | Dichiarato rivedibile dopo il primo uso reale. |
| DB-04 | Con l'esecuzione unica della suite, un commit di igiene preso singolarmente potrebbe non essere verde: la garanzia è sullo stato finale del branch. | I fix di igiene sono di norma indipendenti fra loro; il caso è raro e il costo dell'alternativa è N esecuzioni complete della suite a ogni passata. |

## E. Gerarchia delle fonti

1. decisioni esplicitamente confermate dall'utente in sessione (sezione B);
2. decisioni della conversazione originale (sezione A);
3. questo file, per la loro forma distillata;
4. [product spec](../docs/product-spec.md), per l'interpretazione;
5. [conversazione](conversation.md), per il contesto completo;
6. assunzioni del modello, sempre dichiarate come tali.
