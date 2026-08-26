# Questioni aperte

> Stato: aggiornato al termine della sessione di decisione del 26 agosto 2026.
> Le questioni bloccanti sono state tutte chiuse e spostate in
> [decisions.md](decisions.md#b-decisioni-prese-nella-sessione-di-design-del-26-agosto-2026).
> Nessuna delle domande rimaste autorizza assunzioni implicite.

## Bloccanti prima dell'implementazione

Nessuna. Le tre emerse durante la sessione — come si scopre il comando dei test,
che pavimento calcolare su uno stack non riconosciuto, quali soglie fanno
scattare la promozione dal registro — sono state decise e registrate.

Resta però un vincolo di sequenza: **le soglie numeriche non esistono ancora**.
Copertura del riconoscimento, volume cumulato non revisionato e numero di
giudizi aperti sono parametri dichiarati, non valori. La prima passata reale su
`belt-configurator` serve anche a tararli. Finché restano non tarati, il
contrappeso all'accumulo e il blocco per stack ignoto sono meccanismi presenti
ma inerti.

## Scelte di design da esplorare

| ID | Questione | Alternative iniziali |
| --- | --- | --- |
| Q-04 | Come si rileva meccanicamente la violazione dell'ordine change brief → intento, dato che dentro un unico contesto il modello può aver già letto la descrizione della PR? | Rifiuto di partire senza change brief; confronto dei tempi di scrittura dei file; dichiarazione esplicita nel brief delle fonti lette. |
| Q-05 | Quali categorie di igiene sono ammesse quando la suite autorevole esiste ma è lenta, o quando copre poco? | Soglia di durata oltre la quale si scende alle sole categorie che non eseguono; misura di copertura; scelta dell'utente al lancio. |
| Q-06 | Come si chiude un giudizio nel file di debito: modifica manuale, comando dedicato, o scomparsa automatica quando il codice cambia? | Editing manuale; skill di chiusura; rilevamento del cambiamento con richiesta di conferma. |
| Q-07 | Che rapporto ha `review-cycle` con `plan-cycle`? Una questione aperta ricorrente dovrebbe poter diventare un piano? | Nessun collegamento nella v1; rimando testuale; handoff esplicito. |
| Q-08 | Quanto costa e quanto dura una passata completa in corsia stretta, e questo cambia la scelta delle corsie? | Da misurare sul primo caso reale. |
| Q-09 | Il cambiamento sintetico con difetti piantati: quanti difetti, di quali tipi, e come si evita che le lenti vengano tarate su di esso invece che sul mondo reale? | Catalogo derivato dai findings reali delle prime passate; difetti generati; fixture fissa. |
| Q-11 | Che cosa entra esattamente nel primo strato del catalogo, e come lo si estende senza trasformarlo in configurazione per progetto? | Lista fissa versionata col plugin; contributi per pull request; estensione tramite il secondo strato. |
| Q-13 | Come si rileva a runtime il supporto ai subagent, invece di assumerlo? | Presenza dello strumento nel runtime; sonda al primo utilizzo con ripiego seriale; dichiarazione nel manifest per prodotto. |
| Q-14 | Quante esecuzioni costa la bisezione per categoria nel caso peggiore, e a che punto conviene rinunciare e riclassificare tutto il lotto come giudizio umano? | Bisezione completa; un solo giro con scarto dell'intero lotto; soglia sul numero di categorie. |

Chiuse in sessione anche: la scelta del linguaggio del layer di script (bash più
`jq`, con l'estrazione del comando dei test delegata al modello); la definizione
di area ai fini del volume cumulato (`Q-10`, chiusa da S-36); e il meccanismo di
verifica del perimetro sui file di test (S-35, che rende la verifica
un'intersezione di insiemi e toglie il parser dal percorso).

Resta scoperto il caso Windows, dove il repository non ha comunque precedenti.

## Contraddizioni e tensioni da gestire

| ID | Tensione | Conseguenza da chiarire |
| --- | --- | --- |
| T-01 | Skill componibili nello stesso contesto contro anti-anchoring strutturale. | La difesa è procedurale. Serve un modo per accorgersi che è stata violata: vedi Q-04. |
| T-02 | Fix applicati automaticamente contro perimetro e assenza di impatto. | Il gate copre le regressioni osservabili dalle suite verdi. Resta aperto cosa succede quando un fix formalmente innocuo rompe un consumatore non coperto da alcun test — ed è il caso che le suite fuori CI dichiarate fuori gate rendono più probabile. |
| T-03 | Corsie leggere contro accumulo di debito. | Mitigato dal registro e dal file di debito, ma i due meccanismi restano inerti finché le soglie non sono tarate. |
| T-04 | Core portabile senza adapter contro utilità reale del contratto d'intento. | La deduzione da commit e descrizione della PR funziona meglio quando un adapter recupera la descrizione. Dove non c'è, l'intento poggia sui soli messaggi di commit. |
| T-05 | Uniformità fra runtime contro garanzie disponibili solo su Claude Code. | Debito consapevole, registrato. Rivedibile se Codex e OpenCode acquisiranno primitive equivalenti. |
| T-06 | La conversazione originale nasce per un articolo e non chiede una skill. | Ciò che nel discorso era una tesi retorica può non reggere come regola eseguibile. Ogni volta che la specifica trasforma una frase della conversazione in un vincolo, il salto va dichiarato. |

## Da rivedere dopo il primo uso reale

- Le tre soglie numeriche, che al momento non hanno un valore.
- Il gate d'intento proporzionato alla corsia: accettato con riserva esplicita
  dell'utente di verificarlo sul campo.
- Se il filtro “dichiara cosa succede se lo ignori” tagli anche cose che
  l'utente voleva vedere. In tal caso si aggiunge un passaggio di auto-critica
  con scarti visibili.
- Se le quattro corsie siano il numero giusto, o se `skip` e `fast` collassino
  nella pratica.
