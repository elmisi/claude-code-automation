# Product specification — review-cycle

> Stato: discovery draft. Non autorizza implementazione, packaging o release.
> Riflette il design concordato nella sessione del 26 agosto 2026 e le
> questioni ancora aperte in [open-questions.md](../context/open-questions.md).

## Problema

Quando il codice viene prodotto da agenti, la review tradizionale si rompe in
due modi opposti. Se il reviewer commenta ogni minuzia, i commenti vengono dati
in pasto a un altro agente che produce fix, che vanno rivisti di nuovo: un ciclo
costoso in cui nessuno dei due lati esercita giudizio. Se invece il reviewer
smette di segnalare le minuzie, il debito si accumula.

Nessuno dei due esiti dipende dalla qualità del modello. Dipendono dal fatto che
il processo tratta allo stesso modo cose di natura diversa: ciò che una macchina
può sistemare deterministicamente e ciò che richiede un giudizio umano.

## Utenti previsti

- chi revisiona il cambiamento di qualcun altro, umano o agente;
- chi ha commissionato la modifica e conosce l'intento meglio di chi l'ha
  scritta;
- chi rilegge il proprio lavoro prima di aprire una PR.

Non sono definiti ruoli, permessi, collaborazione multi-utente o integrazione
con la CI.

## Obiettivo e non-obiettivi

### Obiettivo

Trasformare un cambiamento in giudizi indipendenti — allineamento all'intento,
architettura, rischio — proporzionati al rischio del cambiamento stesso, e
separare in modo netto ciò che va corretto automaticamente da ciò che merita
attenzione umana.

### Non-obiettivi

- imitare un reviewer umano che commenta riga per riga;
- pubblicare commenti o spingere codice verso l'esterno senza gesto umano;
- sostituire il giudizio umano dove resta incertezza;
- massimizzare il numero di osservazioni prodotte;
- rilevare la deriva architetturale cumulativa, che resta compito di
  `refactor-discovery`;
- dipendere da una piattaforma di hosting, da un modello o da una API.

## Workflow

```text
change
  → copertura riconoscimento (controllo a costo zero; sotto soglia si ferma)
  → change brief            (comportamento ricostruito dal solo diff)
  → contratto d'intento     (dedotto da commit e PR, validato dall'utente)
  → routing                 (pavimento da regola, promozione dal modello)
  → lenti: drift | architettura | rischio
  → triage                  (auto-fixable | needs-human)
       ├─ auto-fixable → hygiene lane → commit locali
       └─ needs-human  → findings e questioni aperte
  → registro e debito
```

| Fase | Scopo | Output | Gate |
| --- | --- | --- | --- |
| Copertura riconoscimento | Verificare che il catalogo sappia collocare i file toccati. | — | Sotto soglia il plugin si ferma e chiede, senza aver speso nulla. |
| Change brief | Ricostruire cosa fa il diff, prima di leggere qualunque intento dichiarato. | `change-brief.md` | Nessuna altra skill parte se non esiste. |
| Contratto d'intento | Dedurre l'intento da commit e descrizione della PR, presentarlo, farlo correggere. | `intent.md` | Proporzionato alla corsia. |
| Routing | Scegliere corsia e profondità. | corsia nel change brief | Il modello può solo promuovere. |
| Lenti | Produrre pochi giudizi ad alto segnale. | `review.md` | Nessuna scrittura di codice. |
| Triage | Classificare ogni esito. | `review.md` | Nel dubbio, `needs-human`. |
| Hygiene lane | Applicare i fix deterministici. | commit locali, `hygiene.md` | Suite verde prima e dopo; mai `git push`. |
| Chiusura | Registrare la passata e aggiornare il debito. | `registry.md`, `debt.md` | Nessuno. |

## Principi

| | Principio |
| --- | --- |
| P1 | Si ricostruisce il comportamento del diff prima di leggere l'intento dichiarato. |
| P2 | Poche osservazioni ad alto segnale, non quantità. |
| P3 | Le lenti sono ortogonali: intento corretto, architettura sbagliata e rischio basso sono uno stato legittimo. |
| P4 | Solo il perimetro del cambiamento, più il minimo contesto. |
| P5 | Ciò che una macchina sistema deterministicamente non diventa una conversazione. |
| P6 | Zero modifiche comportamentali nella fix lane; se serve argomentarlo, è un giudizio umano. |
| P7 | L'intento è attestato dall'utente, mai inferito e dato per buono. |
| P8 | Selettività, non leggerezza: la corsia stretta è più severa della review tradizionale. |

## Le lenti

| Lente | Domanda guida | Verifica |
| --- | --- | --- |
| Drift | Il comportamento coincide con l'intento validato? | Scarto fra comportamento ricostruito e contratto d'intento; criteri scoperti; assunzioni non dichiarate. |
| Architettura | La stiamo costruendo nel posto e nel modo giusto? | Confini, pattern, responsabilità, direzione tecnica. Se devia: impatto e poche alternative concrete. |
| Rischio | Se sbagliamo, quanto ci costa? | Probabilità, impatto, blast radius, rilevabilità, reversibilità; come lo si rileva e come si fa rollback. |

Ogni lente dichiara esplicitamente cosa ha lasciato fuori ambito.

## Corsie

| Corsia | Innesco | Lenti | Contratto d'intento |
| --- | --- | --- | --- |
| `skip` | File generati, sola formattazione, soli commenti. | Nessuna. | Non richiesto. |
| `fast` | Prototipo, dati finti, nulla di sensibile. | Rischio in forma leggera. | Non richiesto. |
| `normal` | Dati veri non sensibili, nuovo flusso. | Tutte. | Richiesto, sbloccabile con un “non lo so” che resta scritto. |
| `strict` | Permessi, migrazioni, contratti pubblici, infrastruttura. | Tutte in profondità, più piano di rollback, test negativi, threat modeling. | Validato, obbligatorio. |

La hygiene lane gira in ogni corsia, `skip` compresa: i refusi non si accumulano
mai. La corsia determina quali lenti girano e quanto a fondo, mai il livello di
autonomia di scrittura, che è fisso.

Il **pavimento** è la corsia minima sotto la quale un cambiamento non può
scendere: il modello può promuovere a una corsia più severa motivando per
iscritto, mai declassare. Lo calcola un catalogo fisso di segnali che il plugin
porta con sé e applica meccanicamente all'albero del progetto e al diff.

Il catalogo è a due strati. Il primo non dipende dallo stack — dimensione e
dispersione del diff, file di lock, workflow di CI, file di configurazione,
estensioni come `.sql`, path contenenti `migration`, `auth`, `secret`,
`permission`, file modificati privi di test associati — e risponde ovunque. Il
secondo aggiunge il riconoscimento specifico dello stack quando c'è. Il change
brief dichiara quale strato ha risposto, così è visibile quando l'analisi è
stata approssimativa.

Prima di tutto il resto, a costo praticamente nullo, si misura quanta parte dei
file toccati il catalogo sa collocare. Sotto soglia il plugin si ferma, elenca
ciò che non ha riconosciuto e chiede all'utente di collocarlo: troppo materiale
non riconosciuto è di per sé anomalo, e proseguire significherebbe spendere
effort che potrebbe essere inutile.

La promozione d'ufficio dal registro scatta su due criteri combinati: volume
cumulato non revisionato su un'area e presenza di giudizi aperti che la toccano.
Tutte le soglie numeriche sono parametri da tarare sul primo uso reale.

## Esiti

Due forme, non intercambiabili.

**Finding** — un difetto. Ha severità, evidenza `file:riga`, e una
classificazione `auto-fixable` o `needs-human`.

**Questione aperta** — una decisione da prendere, non un errore. Non ha
severità e non si risolve: si decide. È ammessa solo se nomina almeno
un'alternativa concreta e il suo costo; senza quello è un'opinione.

Entrambe le forme devono dichiarare **cosa succede se le si ignora**. Un esito
senza conseguenza dichiarata non entra nell'elenco. Non esistono tetti numerici:
la selezione avviene per costruzione.

I `needs-human` non vengono mai risolti automaticamente. Restano file, con una
versione già formattata da incollare nella PR; nessuna pubblicazione automatica.

## Hygiene lane

Categorie ammesse: refusi, commenti obsoleti evidenti, docstring, lint,
formattazione, import, naming locale non pubblico.

Categorie sempre vietate: logica di business, API, schema, dipendenze,
configurazioni, ottimizzazioni speculative, e la configurazione di lint e CI.

**File di test interamente fuori perimetro**, senza eccezioni. La verifica è
un'intersezione di insiemi — i file modificati dalla lane non devono intersecare
i file che corrispondono ai pattern di test — ed è quindi meccanica, senza
parser, senza dipendenza dal linguaggio o dal runner. Un refuso in un commento
dentro un file di test non viene corretto: diventa un giudizio umano.

Il comando autorevole viene dal workflow di CI. La CI non è però un censimento:
il plugin enumera comunque le suite presenti nel repository e segna quali la CI
non esegue. Tutte vengono eseguite prima di iniziare. Quelle verdi entrano nel
gate e devono restare verdi dopo ogni commit; quelle già rosse o non eseguibili
nell'ambiente locale restano fuori dal gate e vengono dichiarate come copertura
mancante, con il motivo. La lane parte se la suite autorevole è verde.

La suite viene eseguita **una volta sola sull'insieme dei fix**, non dopo ogni
commit. Se è verde, si committa per categoria. Se è rossa, si bisezione per
categoria fino a isolare il gruppo colpevole, che viene scartato e riclassificato
come giudizio umano.

Dove il comando di collect del runner è noto e funziona, il confronto
dell'insieme dei test raccolti prima e dopo resta come verifica aggiuntiva:
intercetta i casi in cui la raccolta cambia indirettamente, per esempio un import
rimosso da un sorgente che era ciò che registrava un test. Dove il comando non è
noto, `hygiene.md` lo dichiara come copertura mancante, come già fa per le suite
fuori dal gate.

La garanzia vale sullo stato finale del branch: un singolo commit di igiene
preso da solo potrebbe non essere verde. È un indebolimento dichiarato, accettato
perché i fix di igiene sono di norma indipendenti fra loro e l'alternativa costa
un'esecuzione completa della suite per ogni commit.

Commit tematici, messaggi chiari, reversibili, mai mescolati con la logica.
Nessun `git push`.

## Divisione fra codice e giudizio

La contabilità deterministica non vive nei prompt. Non per risparmiare, ma
perché diverse decisioni di questa specifica sono vere solo se le fa eseguire
del codice: il pavimento è deterministico solo se lo calcola uno script, e la
regola che ogni esito dichiari la propria conseguenza filtra qualcosa solo se
qualcuno la verifica.

| Lavoro | Chi |
| --- | --- |
| Matching dei segnali e calcolo del pavimento | Script |
| Copertura del riconoscimento | Script |
| Inventario del diff: file, righe, dispersione, test associati | Script |
| Enumerazione ed esecuzione delle suite, confronto dell'insieme dei test raccolti | Script |
| Estrazione del comando dei test dal workflow di CI, una volta per repository | Modello |
| Registro, debito, volume cumulato per area | Script |
| Validazione di forma degli esiti | Script |
| Ricostruzione del comportamento dal diff | Modello |
| Deduzione dell'intento da commit e descrizione della PR | Modello |
| Le tre lenti | Modello |
| Classificazione `auto-fixable` / `needs-human` | Modello |
| Promozione della corsia | Modello |

Ne discendono due vincoli di forma. La metodologia è divisa per lente e
caricata su richiesta, così il materiale della sola corsia stretta non entra in
una passata leggera. E **nessun prompt contiene rami condizionali**: la
selezione la fa lo script, l'orchestratore invoca solo ciò che serve e passa la
profondità come parametro, e ogni skill resta un'istruzione lineare — che è la
forma che i modelli piccoli seguono con più scrupolo.

Non esistono tetti di righe né budget di token: un tetto misura la cosa
sbagliata e induce a comprimere la qualità dell'output invece del problema.

Il layer è scritto in bash più `jq`, come il resto del repository. L'unica
eccezione alla divisione è l'estrazione del comando dei test dal workflow di CI:
leggere uno YAML arbitrario è lavoro semantico, lo fa il modello una volta sola
per repository e il risultato resta nel registro. Così non serve né un parser né
una dipendenza da installare in sandbox altrui.

## Architettura

Plugin `review-cycle` con doppio manifest, sei skill componibili e una
metodologia interna condivisa.

| Skill | Ruolo | Scrive codice |
| --- | --- | --- |
| `/review-cycle` | Orchestratore: brief, routing, invocazione delle skill della corsia, triage, registro. | No |
| `/review-cycle-intent` | Deduce l'intento, lo presenta, raccoglie le correzioni, scrive il contratto. Invocabile da sola. | No |
| `/review-cycle-drift` | Lente: scarto fra comportamento e intento validato. | No |
| `/review-cycle-architecture` | Lente architettura. | No |
| `/review-cycle-risk` | Lente rischio. | No |
| `/review-cycle-hygiene` | Fix lane deterministica. | Sì: working tree e commit locali, mai push. |

Il core opera su un range git locale. Gli adapter — `gh`, Bitbucket, Jira — sono
opzionali e arricchiscono la sola deduzione dell'intento.

Le lenti sono skill, non subagent, e non usano `context: fork`: il risultato è
identico su Claude Code, Codex e OpenCode. L'anti-anchoring non è quindi
garantito dall'isolamento del contesto ma dall'ordine di esecuzione e dal fatto
che ogni skill legge `change-brief.md` come input, scritto e chiuso prima che
l'intento entri in scena.

Nelle corsie normale e stretta, dove le lenti da eseguire sono tre, il plugin le
esegue **in parallelo se il runtime supporta i subagent**, rilevandolo invece di
assumerlo, e serialmente altrove. L'input di ogni lente è esattamente
`change-brief.md` più `intent.md`: se il suo esito cambiasse fra le due
modalità, significherebbe che stava leggendo il contesto invece dei file, cioè
che stava già violando il protocollo. Dove il parallelismo è disponibile,
l'isolamento del contesto rientra come effetto collaterale.

I debiti che restano sono registrati in
[decisions.md](../context/decisions.md#d-debiti-consapevoli).

## Artefatti

In `docs/review-cycle/<pass-id>/` del progetto revisionato:

| File | Contenuto |
| --- | --- |
| `change-brief.md` | Comportamento ricostruito, file e righe toccate, dispersione, mappa delle aree sensibili, presenza di test, reversibilità stimata, corsia con la motivazione di ogni eventuale promozione. |
| `intent.md` | Intento dedotto, origine di ciascun elemento, cosa non è stato determinato, correzioni dell'utente, stato di validazione. |
| `review.md` | Findings e questioni aperte, con conseguenza dell'ignorarli e classificazione. |
| `hygiene.md` | File toccati, categorie, quali suite sono entrate nel gate e quali no con il motivo, esito prima e dopo, commit prodotti, cosa è stato lasciato aperto. |

E a livello di progetto, non di passata:

| File | Contenuto |
| --- | --- |
| `docs/review-cycle/registry.md` | Log leggibile: una riga per passata — range, corsia, aree toccate, esiti non chiusi. Ogni passata è un append puro, che non può corrompere nulla. |
| `docs/review-cycle/state.json` | Il lato macchina, interrogabile con `jq`: comando dei test, profondità di area, collocazione di ciò che il catalogo non riconosce, volume cumulato per area, giudizi aperti. È stato operativo, non policy: non decide mai se un cambiamento vada revisionato. |
| `docs/review-cycle/debt.md` | Vista leggibile dei giudizi umani mai chiusi, rigenerata da `state.json` e ripresentata a ogni passata. |

## Approvazioni umane

| Decisione | Stato richiesto |
| --- | --- |
| Contratto d'intento | Validato dall'utente; obbligatorio in corsia stretta. |
| `git push`, apertura PR, pubblicazione di commenti | Sempre gesto esplicito dell'utente. |
| Findings `needs-human` | Non risolti automaticamente in nessuna corsia. |
| Corsia `strict` | Approvazione umana obbligatoria prima del merge. |

## Criteri di successo

Una prima versione sarà utile se, su una PR reale di `belt-configurator` o
`configurator-backend`:

1. il change brief descrive il comportamento senza aver letto l'intento;
2. la corsia scelta è quella che l'utente avrebbe scelto a mano;
3. il contratto d'intento dedotto va corretto, non riscritto;
4. i giudizi umani sono pochi e nessuno di essi è un nit;
5. i commit di igiene sono leggibili e non richiedono di essere riletti riga per
   riga;
6. l'utente non riapre una conversazione per cose che la lane avrebbe potuto
   sistemare;
7. rilanciare la stessa passata produce la stessa corsia e gli stessi giudizi
   principali.

## Roadmap successiva all'implementazione

L'ordine conta più del contenuto: ogni tappa produce ciò che serve alla
successiva, e il salto rischioso è fra la terza e la quarta — l'unico momento in
cui il plugin passa dal produrre file al modificare codice che qualcun altro
vedrà.

| # | Tappa | Scopo | Produce |
| --- | --- | --- | --- |
| 1 | Rodaggio su `claude-code-automation` | Scoprire gli errori grossolani — script che non gira, skill che non trova i file, ordine change brief/intento violato — dove non si fanno danni. Non tara nulla: autore e reviewer coincidono, quindi il contratto d'intento dice cose già note. | La fixture sintetica con i difetti piantati, derivata da casi veri invece che scritta a tavolino. |
| 2 | Prima passata reale su `belt-configurator`, sola lettura | Verificare i due criteri che contano: la corsia scelta è quella che l'utente avrebbe scelto a mano, e i giudizi sono pochi con nessun nit. Hygiene lane disattivata. | I primi numeri veri: durata, numero di esiti, quanti ne ha scartati il filtro della conseguenza. |
| 3 | Taratura delle soglie | Copertura del riconoscimento, volume cumulato, giudizi aperti. Richiede una manciata di passate su entrambi i repository. | Le tre soglie, senza le quali il blocco per stack ignoto e la promozione d'ufficio restano meccanismi inerti. |
| 4 | Prima scrittura: hygiene lane su una PR vera | Verificare la promessa centrale — i commit sono leggibili e non vanno riletti riga per riga — e misurare il costo reale dell'esecuzione unica della suite su `configurator-backend`. | La prova che il ping-pong dei commenti sparisce davvero. |
| 5 | Revisione di ciò che è marcato rivedibile | Gate d'intento proporzionato, filtro della conseguenza, se `skip` e `fast` collassino, se quattro corsie siano il numero giusto. Con dati invece che a memoria; è il punto in cui usare `takeaway`. | Correzioni al design fondate su uso reale. |
| 6 | L'articolo | Era la destinazione dichiarata della conversazione originale. | Numeri di un sistema costruito e usato davvero, comprese le parti che non hanno funzionato — cosa che nessun contributo in bibliografia ha. |

## Fonti

- [Conversazione originale normalizzata](../context/conversation.md)
- [Decisioni estratte](../context/decisions.md)
- [Questioni aperte](../context/open-questions.md)
