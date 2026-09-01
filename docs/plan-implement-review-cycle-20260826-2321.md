# Plan: implementazione del plugin `review-cycle`

## How to work with this plan

Sections labeled *(Reviewer surface)* require user input before approval — read them in full.
Sections labeled *(Executor surface)* are the implementer's baseline — reviewers may skip.

For operations (annotate / review / finalize): see the **Operations Guide** appendix at the bottom of this file.

## Context *(Reviewer surface)*

### Cosa si costruisce

Un nuovo plugin `review-cycle` in questo repository, dual-packaged per Claude Code e Codex,
che implementa la pipeline specificata in `docs/review-cycle/docs/product-spec.md`:

```text
change → copertura riconoscimento → change brief → contratto d'intento
       → routing → lenti (drift | architettura | rischio) → triage
       → hygiene lane → registro e debito
```

Le decisioni vincolanti sono in `docs/review-cycle/context/decisions.md` (20 dalla
conversazione originale con prefisso `D-`, 36 di sessione con prefisso `S-`, 4 debiti
consapevoli con prefisso `DB-`). Le questioni ancora aperte sono in
`docs/review-cycle/context/open-questions.md`. Questo piano non le rinegozia: le traduce
in file.

### Cosa esiste oggi nel repository, verificato

| Fatto | Dove l'ho verificato |
| --- | --- |
| I plugin self-contained hanno due manifest e nessun bump di `VERSION` alla radice: `VERSION` è legato al solo `automate`. | `tests/scripts/run-tests.sh:249-257` confronta `VERSION` con `plugins/automate/.claude-plugin/plugin.json` e `.claude-plugin/marketplace.json` `.plugins[0].version`. |
| Le voci del marketplace Claude portano `version`; quelle del marketplace Codex **non devono portarlo**. | `.claude-plugin/marketplace.json` ha `version` per ogni voce; `tests/scripts/run-tests.sh:855-857` è un test negativo che asserisce l'assenza di `version` nella voce Codex di `plan-cycle`. |
| Le voci Codex puntano a `./plugins/<nome>` via `source.path`. | `.agents/plugins/marketplace.json`; asserito da `STRUCT-116`, `STRUCT-123`, `STRUCT-129`, `STRUCT-QA-09`. |
| Il pattern "skill-only script" esiste già ed è di 11 righe. | `plugins/automate/skills/automate-list/SKILL.md` invoca `"${CLAUDE_SKILL_DIR}/../../scripts/automate-list.sh"` e nient'altro. |
| Il pattern "subagent quando il runtime lo supporta, altrimenti seriale" esiste già. | `plugins/refactor-discovery/skills/refactor-discovery/SKILL.md:118` e `:128`. |
| Il pattern "pass-id datato con suffisso incrementale" e il registro append-only esistono già. | `plugins/refactor-discovery/skills/refactor-discovery/SKILL.md:44` e `:363`. |
| Gli script del repository sono bash con `#!/bin/bash`, `set -e`, `SCRIPT_DIR` risolto da `BASH_SOURCE`, uscite `0/1/2`. | `plugins/automate/scripts/validate-config.sh:1-22`. |
| La CI installa `jq` ed esegue `structure`, `e2e` e una validazione esplicita delle fixture. | `.github/workflows/ci.yml`. |
| Toolchain locale disponibile. | `bash 5.2.21(1)`, `jq-1.7`, `git 2.43.0`, misurati con `--version` il 2026-08-26. |
| Le assertion disponibili nei test sono `assert_file_exists`, `assert_file_not_exists`, `assert_file_contains`, `assert_valid_json`, `assert_valid_frontmatter`, `assert_json_has_key`, `assert_validation_passes`, `assert_validation_fails`. | `tests/scripts/helpers.sh:112-278`. |

### Il vincolo di packaging che condiziona tutto il resto

`CHANGELOG.md`, voce `[qa-architect 0.1.0-beta.2] - 2026-08-13`, registra una misura fatta
contro **opencode 1.18.18**: i riferimenti relativi di una skill vengono risolti *rispetto al
percorso del link, senza seguirlo*. Con `.agents/skills/qa-architect` che puntava al solo
`SKILL.md`, ogni riferimento a `references/` e `assets/` risolveva su un percorso inesistente;
la correzione è stata linkare l'intera directory della skill.

Conseguenza per `review-cycle`: **se una skill viene esposta tramite un symlink in
`.agents/skills/`, tutto ciò che quella skill legge deve stare dentro la sua directory.**
Un riferimento `../../scripts/` o `../../docs/` non risolve — e la misura riportata più sotto
mostra che non fallisce nemmeno in modo benigno.

Stato attuale: `.agents/skills/` contiene **solo** `qa-architect` (verificato con `ls -la` il
2026-08-26). `plan-cycle`, `refactor-discovery` e `takeaway` sono impacchettati per Codex
esclusivamente tramite `.agents/plugins/marketplace.json` → `./plugins/<nome>`.

`unverified:` che in quella seconda modalità — plugin installato dal marketplace Codex invece
che esposto in `.agents/skills/` — il percorso `../../` risolva normalmente. È plausibile
perché il prodotto legge l'intera directory del plugin, e i tre plugin esistenti funzionano,
ma non l'ho misurato. Non è load-bearing per `review-cycle`, che dopo la decisione qui sotto
non usa `../../` da nessuna parte; lo sarebbe se un giorno si tornasse indietro.

**Decisione presa il 2026-08-26:** `review-cycle` viene esposto anche in `.agents/skills/`,
perché la compatibilità con OpenCode è una ragione dichiarata di S-04 e i link costano poco.
La duplicazione si evita con **link annidati**: dentro ogni directory di skill, un `scripts`
che punta a `../../scripts` e un `methodology-core.md` che punta a
`../../docs/methodology-core.md`. Così ogni skill legge solo percorsi che restano al proprio
interno — la condizione che la correzione di `qa-architect` ha dimostrato funzionante — e la
sorgente resta una sola.

**Misurato il 2026-08-26 contro opencode 1.18.23**, con uno scenario minimo in scratchpad:
una skill esposta come directory symlink in `.agents/skills/`, contenente un symlink a
directory (`scripts` → `../../scripts`) e uno a file
(`methodology-core.md` → `../../docs/methodology-core.md`), più una seconda skill di
controllo che tentava un percorso `../../`.

| Caso | Percorso letto dalla skill | Esito misurato |
| --- | --- | --- |
| Symlink annidati, percorso interno | `scripts/rc-lib.sh`, `methodology-core.md` | **Riuscito.** opencode ha letto `.agents/skills/linktest/scripts/rc-lib.sh` e `.agents/skills/linktest/methodology-core.md`, attraversando sia il link di directory sia i link annidati, restituendo i marker corretti al primo tentativo e senza fallback a glob. |
| Percorso genitore-relativo | `../../scripts/rc-lib.sh` | **Fallito, e peggio del previsto.** Il percorso non ha risolto sulla directory reale del plugin: è uscito dalla radice del progetto, ha fatto scattare la richiesta di permesso `external_directory` ed è stato rifiutato. |

Le due misure insieme stabiliscono che il layout a link annidati funziona e che il divieto di
`../../` non è stilistico ma sostanziale: da una skill esposta via symlink un percorso
genitore-relativo non trova il file *e* tenta di uscire dal progetto. `STRUCT-RC-26` diventa
quindi un test portante.

Nota, senza azione richiesta: `refactor-discovery` e `automate` usano
`${CLAUDE_SKILL_DIR}/../../` ma non sono esposti in `.agents/skills/`, quindi non sono
toccati da questo comportamento.

## Interpretation Log *(Reviewer surface)*

- ~~Letto "layer di script bash+jq" come un layer a script separati, uno per compito, più una libreria condivisa.~~ **Confermato il 2026-08-27.** Il numero è salito a sette script più `rc-lib.sh` con l'aggiunta di `rc-guard.sh` (S-35), coerente col principio confermato di un file per compito.

- ~~Letto "registro" come due file affiancati: `registry.md` leggibile e `state.json` macchina.~~ **Confermato il 2026-08-27**, con la ragione decisiva che l'append resta un append. La sezione Artefatti della spec va allineata in **T15**.

- ~~Letto S-31 come vincolo che si estende all'orchestratore, non solo alle lenti.~~ **Confermato il 2026-08-27:** `rc-floor.sh` emette la lista `invoke`, perché "quali lenti girano" è una proprietà di sicurezza che fallisce in modo invisibile e dev'essere verificabile da un test.

- ~~Letto "area" come directory di primo livello del repository.~~ **Corretto il 2026-08-27 in S-36:** directory di primo livello *sotto la radice sorgente rilevata*, con la profondità calcolata una volta per repository e memorizzata in `state.json`. Chiude `Q-10`.

- ~~Letto la versione iniziale come `0.1.0-beta.1`.~~ **Confermato dall'utente il 2026-08-26.**

## Approach *(Reviewer surface)*

Tre principi guidano il layout, e discendono tutti da decisioni già prese.

**Il codice fa la contabilità, il prompt fa la semantica** (S-28). Ogni cosa che deve essere
riproducibile — pavimento della corsia, copertura del riconoscimento, inventario del diff,
esecuzione delle suite, registro, validazione di forma degli esiti — è uno script bash. Non
per risparmiare: il pavimento è deterministico solo se lo calcola del codice, e la regola per
cui ogni esito dichiara la propria conseguenza filtra qualcosa solo se qualcuno la verifica.

**I prompt sono lineari** (S-31). Nessuna skill contiene rami sulla corsia. Lo script emette
la lista di ciò che va invocato; le skill eseguono un'istruzione sola. Il costo di questa
scelta è che il contratto fra script e skill diventa un formato JSON che va tenuto stabile,
ed è per questo che ha fixture e test propri.

**Le soglie non esistono ancora** (S-27). `data/thresholds.json` nasce con tutti i valori a
`null`. Uno script che legge una soglia `null` non blocca e non promuove: stampa una riga
`INERT:` nel proprio output, che l'orchestratore riporta all'utente. Questo rende visibile in
esecuzione ciò che altrimenti sembrerebbe funzionante — è il rischio nominato in cima a
`docs/review-cycle/context/open-questions.md`.

Cosa **non** cambia: nessun file esistente del repository viene modificato nella sostanza.
Gli unici tocchi fuori da `plugins/review-cycle/` sono voci nei due marketplace, nuovi
blocchi di test, nuove fixture, e le righe di elenco in `CLAUDE.md`, `AGENTS.md`, `README.md`
e `CHANGELOG.md`.

## Decisions I Need From You *(Reviewer surface)*

None. Le tre decisioni aperte alla stesura sono state risolte dall'utente il 2026-08-26 e
sono incorporate nelle sezioni operative:

| Decisione | Esito | Dove è incorporata |
| --- | --- | --- |
| Esposizione in `.agents/skills/` | Sì, con link annidati invece di copie | *Context*, §1, §7, §8, T10 |
| `effort` nel frontmatter | `effort: high` su orchestratore e tre lenti | §5 |
| Versione iniziale | `0.1.0-beta.1`, con "beta" nella descrizione del marketplace | §7 |

Le cinque letture in `Interpretation Log` sono state confermate o corrette dall'utente il
2026-08-27; quattro sono confermate e una — la definizione di area — è stata corretta e ha
prodotto S-36.

## Detailed Changes *(Executor surface)*

### 1. Struttura del plugin

Nuova directory `plugins/review-cycle/`:

```text
plugins/review-cycle/
  .claude-plugin/plugin.json
  .codex-plugin/plugin.json
  agents/
    lens-runner.md
  data/
    signals.json
    thresholds.json
  docs/
    methodology-core.md
  scripts/
    rc-lib.sh
    rc-recognize.sh
    rc-inventory.sh
    rc-floor.sh
    rc-suites.sh
    rc-registry.sh
    rc-guard.sh
    rc-validate.sh
  skills/
    review-cycle/               SKILL.md + scripts@ + methodology-core.md@
    review-cycle-intent/        SKILL.md + scripts@ + methodology-core.md@
    review-cycle-drift/         SKILL.md + methodology-core.md@ + methodology-drift.md
    review-cycle-architecture/  SKILL.md + methodology-core.md@ + methodology-architecture.md
    review-cycle-risk/          SKILL.md + methodology-core.md@ + methodology-risk.md
    review-cycle-hygiene/       SKILL.md + scripts@ + methodology-core.md@ + methodology-hygiene.md
```

`@` indica un symlink relativo interno al plugin: `scripts` → `../../scripts`,
`methodology-core.md` → `../../docs/methodology-core.md`. Quindici link in totale contando i
sei di `.agents/skills/`, zero copie, nessun rischio di drift fra copie. La regola che li
giustifica: una skill deve leggere **solo percorsi che restano dentro la propria directory**,
perché da una skill raggiunta via symlink un `../../` viene normalizzato rispetto a
`.agents/skills/` e non alla directory reale.

I file di metodologia specifici di una lente vivono direttamente nella directory di quella
lente, non in `docs/`, per la stessa ragione — e questo realizza anche S-29, dato che il
materiale di una lente non è raggiungibile dalle altre.

**Criterio di successo visibile all'utente:** l'utente lancia `/review-cycle main...HEAD` su
questo repository e ottiene `docs/review-cycle/<data>/change-brief.md` popolato, senza errori
di percorso su nessuno dei sei comandi.

### 2. `data/signals.json` — catalogo a due strati (S-11, S-24)

Sorgente di verità del pavimento. Nessuna configurazione per progetto: il file vive nel
plugin e viene applicato meccanicamente.

```json
{
  "version": 1,
  "layer_base": {
    "path_patterns": [
      {"match": "**/migration*/**", "floor": "strict", "why": "schema change"},
      {"match": "**/auth*/**",      "floor": "strict", "why": "authentication surface"},
      {"match": "**/*secret*",      "floor": "strict", "why": "credential surface"},
      {"match": "**/*permission*",  "floor": "strict", "why": "authorization surface"}
    ],
    "extensions": [
      {"match": "*.sql", "floor": "strict", "why": "schema or data change"}
    ],
    "filenames": [
      {"match": "*.lock",             "floor": "normal", "why": "dependency graph"},
      {"match": ".github/workflows/*","floor": "normal", "why": "pipeline definition"},
      {"match": "bitbucket-pipelines.yml", "floor": "normal", "why": "pipeline definition"}
    ],
    "generated": ["**/dist/**", "**/build/**", "**/*.min.*", "**/node_modules/**"],
    "roles": {
      "test":   ["**/test/**", "**/tests/**", "**/*_test.*", "**/*.test.*", "**/*.spec.*"],
      "config": ["**/*.config.*", "**/*.ini", "**/*.toml", "**/*.cfg"],
      "docs":   ["**/*.md", "**/*.rst", "**/*.txt"]
    }
  },
  "layer_stack": {
    "node":   {"manifest": "package.json",   "test_config": ["jest.config.*", "vitest.config.*", "playwright.config.*"]},
    "python": {"manifest": "pyproject.toml", "test_config": ["pytest.ini", "tox.ini", "setup.cfg"]},
    "rust":   {"manifest": "Cargo.toml",     "test_config": []},
    "go":     {"manifest": "go.mod",         "test_config": []}
  },
  "collect_commands": {
    "pytest": "pytest --collect-only -q",
    "jest":   "npx jest --listTests",
    "vitest": "npx vitest list",
    "go":     "go test ./... -list .",
    "cargo":  "cargo test -- --list"
  }
}
```

`roles.test` è **portante**: dopo S-35 quei glob sono ciò che definisce il perimetro
intoccabile della hygiene lane. Un file di test che nessun pattern riconosce viene trattato
come un sorgente qualunque. Vanno testati con la stessa cura dei segnali del pavimento.

`assumed:` i comandi in `collect_commands` sono presi dalla documentazione dei rispettivi
runner e **non sono stati eseguiti** in questa sessione; `vitest list` in particolare è
cambiato fra major version. Dopo S-35 questo non blocca più nulla: il confronto dell'insieme
raccolto è una verifica *aggiuntiva*, e la garanzia meccanica di base è l'intersezione vuota
di `rc-guard.sh`. Dove un comando di collect manca o fallisce, `hygiene.md` lo dichiara come
copertura mancante e la lane prosegue.

**Criterio di successo visibile all'utente:** su questo repository l'utente esegue
`rc-inventory.sh` su un range che tocca `.github/workflows/ci.yml`, passa l'inventario a
`rc-floor.sh`, e ottiene `"floor": "normal"` con il motivo `pipeline definition` fra i
segnali. Ripetendo i due comandi sullo stesso range ottiene byte per byte lo stesso output.

### 3. `data/thresholds.json` — soglie non tarate (S-27)

```json
{
  "recognition_coverage_min": null,
  "uncumulated_volume_lines": null,
  "open_judgements_max": null,
  "_note": "null = meccanismo presente ma inerte. Tarare alla tappa 3 della roadmap."
}
```

Ogni script che legge una soglia `null` stampa su stderr
`INERT: <nome-soglia> non tarata — il meccanismo non scatterà` ed esce `0`.

**Criterio di successo visibile all'utente:** lanciando `/review-cycle` con le soglie a
`null`, il report finale contiene una riga esplicita che elenca quali meccanismi non sono
attivi. L'utente non può concludere per sbaglio che il blocco per stack ignoto sia operativo.

### 4. Layer di script

Convenzioni comuni, da `plugins/automate/scripts/validate-config.sh:1-22`: `#!/bin/bash`,
`set -e`, `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`, uscite `0` valido /
`1` bloccato o invalido / `2` errore d'uso, messaggi diagnostici su stderr, payload JSON su
stdout. `rc-lib.sh` centralizza le funzioni di emissione JSON, la risoluzione della radice
del plugin, la lettura delle soglie e la stampa delle righe `INERT:`.

| Script | Argomenti | Emette su stdout |
| --- | --- | --- |
| `rc-recognize.sh` | `<base> <head>` | `{"coverage": 0.0-1.0, "classified": [...], "unknown": [...], "manifests": [...], "threshold": null\|number, "blocked": bool}` |
| `rc-inventory.sh` | `<base> <head>` | `{"files":[{"path","role","added","removed"}], "added":N, "removed":N, "dispersion":N, "areas":[...], "tests_touched":[...], "files_without_tests":[...]}` |
| `rc-floor.sh` | `<inventory.json>` | `{"floor":"skip\|fast\|normal\|strict", "signals":[{"match","why","floor"}], "layer":"base\|stack", "invoke":[...], "intent_gate":"none\|required-unblockable\|required-strict"}` |
| `rc-suites.sh` | `discover\|enumerate\|collect\|run [args]` | dipende dal sottocomando; vedi sotto |
| `rc-registry.sh` | `init\|append-pass\|set-test-command\|set-area-mapping\|promote-check\|debt-list\|debt-add\|debt-close` | JSON o nulla |
| `rc-guard.sh` | `<base> <head>` | nulla se il perimetro è rispettato; elenco dei file di test toccati su stderr ed esce `1` |
| `rc-validate.sh` | `<review.md>` | nulla se valido; elenco delle violazioni su stderr ed esce `1` |

`rc-floor.sh` è il punto in cui S-31 diventa concreto: il campo `invoke` contiene i nomi
delle skill da eseguire, in ordine, e il prompt dell'orchestratore non contiene alcun ramo.

- `skip` → `["review-cycle-hygiene"]`, `intent_gate: "none"`
- `fast` → `["review-cycle-risk", "review-cycle-hygiene"]`, `intent_gate: "none"`
- `normal` → `["review-cycle-intent", "review-cycle-drift", "review-cycle-architecture", "review-cycle-risk", "review-cycle-hygiene"]`, `intent_gate: "required-unblockable"`
- `strict` → come `normal`, `intent_gate: "required-strict"`

`rc-suites.sh discover` legge il comando dei test da `state.json`. Se assente, emette
`{"needs_model_extraction": true, "ci_files": ["..."]}` — l'estrazione dal YAML è compito del
modello, una volta per repository (S-34), e il risultato viene scritto con
`rc-registry.sh set-test-command`.

`rc-suites.sh enumerate` elenca le suite presenti nel repository e marca quali il comando
autorevole copre (S-22). `run` esegue e restituisce `{"suite","status","duration_s"}`.
`collect` restituisce l'insieme dei test raccolti per il confronto prima/dopo, che dopo S-35 è una verifica aggiuntiva e non la garanzia primaria.

`rc-guard.sh` è la verifica meccanica del perimetro introdotta da S-35. Calcola
`git diff --name-only <base> <head>`, lo interseca con i file che corrispondono ai glob
`roles.test` di `signals.json`, ed esce `1` se l'intersezione non è vuota. Nessun parser,
nessuna dipendenza dal linguaggio o dal runner: funziona anche sugli stack che il catalogo
non riconosce. La hygiene lane lo invoca dopo aver applicato i fix e prima di committare.

`rc-suites.sh collect` resta come verifica *aggiuntiva* dove il comando di collect è noto e
funziona, e intercetta i casi in cui la raccolta cambia indirettamente — per esempio un
import rimosso da un sorgente che era ciò che registrava un test. Dove il comando manca o
fallisce, la lane non si ferma: lo dichiara in `hygiene.md` come copertura mancante, lo
stesso schema di S-23.

`rc-validate.sh` verifica, su `review.md`: ogni finding ha severità, evidenza `file:riga`,
classificazione `auto-fixable|needs-human` e una riga `Conseguenza:` non vuota (S-16); ogni
questione aperta ha una riga `Alternativa:` e una `Costo:` non vuote (S-15); nessuna
questione aperta porta severità.

**Criterio di successo visibile all'utente:** l'utente scrive a mano un finding senza riga
`Conseguenza:` in un `review.md`, lancia `rc-validate.sh` su quel file, e ottiene exit code
`1` con il numero di riga dell'esito incompleto. Su un file corretto ottiene `0` e nessun
output.

### 5. Le sei skill

Frontmatter comune: `name`, `description`, `disable-model-invocation: true`,
`argument-hint`, `allowed-tools`. **`effort: high`** su `review-cycle` e sulle tre lenti;
assente su `review-cycle-intent` e `review-cycle-hygiene`, che eseguono protocollo e non
giudizio. Il campo è una capacità di Claude Code e viene ignorato da Codex e OpenCode: la
divergenza è di profondità di ragionamento, non di protocollo, quindi non viola S-04.

| Skill | `argument-hint` | `allowed-tools` | Legge | Scrive |
| --- | --- | --- | --- | --- |
| `review-cycle` | `<base>...<head>` | `[Agent, Bash, Read, Write, Skill, Glob, Grep, TodoWrite]` | output degli script | `change-brief.md`, `review.md`, `registry.md`, `state.json`, `debt.md` |
| `review-cycle-intent` | `<pass-dir>` | `[Bash, Read, Write, AskUserQuestion]` | commit, descrizione PR, `change-brief.md` | `intent.md` |
| `review-cycle-drift` | `<pass-dir>` | `[Read, Write, Glob, Grep]` | `change-brief.md`, `intent.md` | `review-drift.md` |
| `review-cycle-architecture` | `<pass-dir>` | `[Read, Write, Glob, Grep]` | idem | `review-architecture.md` |
| `review-cycle-risk` | `<pass-dir>` | `[Read, Write, Glob, Grep]` | idem | `review-risk.md` |
| `review-cycle-hygiene` | `<pass-dir>` | `[Bash, Read, Edit, Write, Glob, Grep]` | `review.md`, output di `rc-suites.sh` e `rc-guard.sh` | working tree, commit locali, `hygiene.md` |

L'orchestratore esegue, senza rami:

1. `rc-recognize.sh` → se `blocked` è vero, elenca gli sconosciuti, chiede all'utente come collocarli, salva con `rc-registry.sh set-area-mapping` e **termina invitando a rilanciare**: la passata non prosegue con una mappa appena scritta, così l'utente vede l'effetto della propria risposta prima che venga speso qualcosa.
2. `rc-inventory.sh` → `inventory.json` nella directory di passata.
3. Scrive `change-brief.md` ricostruendo il comportamento **dal solo diff**. Non legge descrizione della PR né ticket in questo passo (D-16, P1).
4. `rc-floor.sh` e `rc-registry.sh promote-check` → corsia e lista `invoke`. Può promuovere motivando per iscritto nel brief; non può declassare (S-10).
5. Invoca in ordine ogni skill elencata in `invoke`.
6. `rc-validate.sh` su `review.md` assemblato. Se esce `1`, rimanda gli esiti incompleti alla lente che li ha prodotti **una sola volta**; se al secondo passaggio sono ancora incompleti, li scarta e scrive in `review.md` quali esiti sono stati scartati e perché.
7. `rc-registry.sh append-pass` e aggiornamento di `debt.md`.

Le tre lenti nelle corsie `normal` e `strict` girano in parallelo tramite l'agent
`lens-runner` quando il runtime supporta i subagent, serialmente altrimenti (S-33), sullo
stesso pattern di `plugins/refactor-discovery/skills/refactor-discovery/SKILL.md:118`. Il
supporto va sondato, non assunto: se lo strumento `Agent` non è disponibile la skill procede
serialmente senza segnalare un errore.

`agents/lens-runner.md` non duplica la logica delle lenti: riceve il nome della skill e la
directory di passata, e usa lo strumento `Skill` per invocarla. Questo tiene una sola
sorgente per ogni lente.

**Criterio di successo visibile all'utente:** l'utente lancia `/review-cycle-risk
docs/review-cycle/2026-08-27/` da solo, senza aver lanciato l'orchestratore, e ottiene
`review-risk.md` popolato — oppure un rifiuto esplicito se `change-brief.md` non esiste in
quella directory.

### 6. Metodologia divisa per lente (S-29)

`docs/methodology-core.md` contiene solo ciò che serve a tutti: definizione dei due tipi di
esito, regola della conseguenza dichiarata, triage `auto-fixable` / `needs-human` con la
regola del dubbio, formato di `review.md`. È linkato dentro tutte e sei le directory di
skill.

I file per lente vivono dentro la directory della lente cui appartengono
(`skills/review-cycle-risk/methodology-risk.md` e omologhi) e non sono raggiungibili dalle
altre skill: è S-29 realizzato dal layout invece che dalla disciplina. Il materiale della
corsia stretta — piano di rollback, test negativi, threat modeling — sta in
`methodology-risk.md` in una sezione separata che l'orchestratore indica di leggere solo
quando `intent_gate` vale `required-strict`.

### 7. Packaging

`plugins/review-cycle/.claude-plugin/plugin.json` sul modello di
`plugins/refactor-discovery/.claude-plugin/plugin.json`: `name`, `version`, `description`,
`author.name: elmisi`, `repository`, `license: MIT`, `keywords`.

`plugins/review-cycle/.codex-plugin/plugin.json` sul modello di
`plugins/qa-architect/.codex-plugin/plugin.json`: gli stessi campi più `homepage`,
`skills: "./skills/"` e il blocco `interface` con `displayName`, `shortDescription`,
`longDescription`, `developerName`, `category: "Productivity"`, `capabilities:
["Interactive","Write"]`, `websiteURL`, `defaultPrompt` (tre esempi), `brandColor`,
`screenshots: []`.

`.claude-plugin/marketplace.json`: nuova voce **con** `version`.
`.agents/plugins/marketplace.json`: nuova voce **senza** `version`, con
`source: {"source":"local","path":"./plugins/review-cycle"}`, `policy` come le altre,
`category: "Productivity"`.

Versione iniziale: **`0.1.0-beta.1`** nei due manifest e nella voce del marketplace Claude,
la cui `description` inizia con "Beta" sul modello della voce `qa-architect`. Motivo: due
meccanismi di sicurezza nascono inerti finché le soglie non sono tarate, e la marcatura di
beta è l'unico posto in cui un installatore lo vede.

`.agents/skills/` riceve **sei directory symlink**, uno per skill, ciascuno verso
`../../plugins/review-cycle/skills/<nome-skill>`, sullo stesso modello di
`.agents/skills/qa-architect`. Sono directory link, mai file link: è la correzione registrata
in `CHANGELOG.md` per `qa-architect 0.1.0-beta.2`.

`VERSION` alla radice **non** si tocca: è legato al solo `automate` (`run-tests.sh:249-257`).
`CHANGELOG.md` riceve una voce in cima.

### 8. Test

Nuovo blocco `STRUCT-RC-*` in `run_structure_tests()` di `tests/scripts/run-tests.sh`,
inserito dopo il blocco `STRUCT-QA-*`:

| ID | Asserzione |
| --- | --- |
| `STRUCT-RC-01..06` | I sei `SKILL.md` esistono. |
| `STRUCT-RC-07..12` | I sei `SKILL.md` hanno frontmatter valido (`assert_valid_frontmatter`). |
| `STRUCT-RC-13` | `.claude-plugin/plugin.json` esiste ed è JSON valido. |
| `STRUCT-RC-14` | `.codex-plugin/plugin.json` esiste ed è JSON valido. |
| `STRUCT-RC-15` | `data/signals.json` è JSON valido. |
| `STRUCT-RC-16` | `data/thresholds.json` è JSON valido e contiene le tre chiavi previste. |
| `STRUCT-RC-17` | Version sync fra i due manifest e la voce del marketplace Claude. |
| `STRUCT-RC-18` | La voce Codex punta a `./plugins/review-cycle`. |
| `STRUCT-RC-19` | La voce Codex **non** ha campo `version` (test negativo, sul modello di `run-tests.sh:855-857`). |
| `STRUCT-RC-20` | Gli otto script esistono, sono eseguibili e iniziano con `#!/bin/bash`. |
| `STRUCT-RC-21` | Nessuno dei sei `SKILL.md` contiene le stringhe di ramo `if the lane`, `se la corsia`, `when the lane is` — verifica meccanica di S-31. |
| `STRUCT-RC-22` | `agents/lens-runner.md` esiste e ha frontmatter valido. |
| `STRUCT-RC-23` | I sei percorsi `.agents/skills/review-cycle*` esistono e sono symlink a directory (`test -L` e `test -d`). |
| `STRUCT-RC-24` | `scripts/rc-lib.sh` è leggibile **attraverso** `.agents/skills/review-cycle/`, `.agents/skills/review-cycle-intent/` e `.agents/skills/review-cycle-hygiene/` — sul modello di `STRUCT-QA-15`. |
| `STRUCT-RC-25` | `methodology-core.md` è leggibile attraverso tutti e sei i percorsi `.agents/skills/review-cycle*`. |
| `STRUCT-RC-26` | Nessun `SKILL.md` di `review-cycle` contiene la stringa `../../` — verifica meccanica della regola "solo percorsi interni alla propria directory". |

Nuove fixture in `tests/fixtures/review-cycle/`:

- `review-valid.md` — un finding completo e una questione aperta completa.
- `review-missing-consequence.md` — un finding senza riga `Conseguenza:`.
- `open-question-without-alternative.md` — questione aperta priva di `Alternativa:`.
- `inventory-sample.json` — inventario sintetico che tocca `db/migrations/001.sql`.
- `inventory-docs-only.json` — inventario di sole modifiche a file `.md`.

`TEST-RC-07` e `TEST-RC-08` non usano file di fixture: `rc-guard.sh` lavora su un range git,
quindi i due test creano un repository sandbox con `setup_sandbox()` di
`tests/scripts/helpers.sh`, fanno due commit — uno che tocca `tests/foo.test.js`, uno che
tocca solo `src/foo.js` — e verificano i due codici di uscita.

Nuove funzioni fixture in `run_e2e_tests()`:

| ID | Asserzione |
| --- | --- |
| `TEST-RC-01` | `rc-validate.sh review-valid.md` esce `0`. |
| `TEST-RC-02` | `rc-validate.sh review-missing-consequence.md` esce `1` e nomina la riga. |
| `TEST-RC-03` | `rc-validate.sh open-question-without-alternative.md` esce `1`. |
| `TEST-RC-04` | `rc-floor.sh inventory-sample.json` produce `floor: "strict"` e cita il segnale `.sql`. |
| `TEST-RC-05` | `rc-floor.sh inventory-docs-only.json` produce `floor: "skip"` e `invoke` contenente la sola hygiene. |
| `TEST-RC-06` | Con `thresholds.json` a `null`, `rc-recognize.sh` esce `0` e stampa `INERT:` su stderr. |
| `TEST-RC-07` | `rc-guard.sh` su un range che modifica un file corrispondente a `roles.test` esce `1` e nomina il file. |
| `TEST-RC-08` | `rc-guard.sh` su un range che non tocca alcun file di test esce `0` senza output. |

`.github/workflows/ci.yml`: nuovo passo che esegue `rc-validate.sh` sulle tre fixture di
forma e `rc-floor.sh` sulle due di inventario, accanto alla validazione già esistente.
`rc-guard.sh` non entra in quel passo perché richiede un repository sandbox: resta coperto da
`run-tests.sh e2e`, che la CI già esegue.

**Criterio di successo visibile all'utente:** l'utente lancia
`./tests/scripts/run-tests.sh structure` e `./tests/scripts/run-tests.sh e2e` e vede i nuovi
`STRUCT-RC-*` e `TEST-RC-*` passare, con il conteggio totale aumentato di 34 (26 struttura,
8 fixture).

### 9. Documentazione del repository

- `CLAUDE.md`: riga nella tabella dei plugin; menzione di `plugins/review-cycle/scripts/` fra le directory chiave; nota che `review-cycle` ha versione propria e non tocca `VERSION`.
- `AGENTS.md`: aggiunta di `plugins/review-cycle/` all'elenco della sezione struttura.
- `README.md`: sezione del plugin con i sei comandi e un esempio di invocazione.
- `CHANGELOG.md`: voce in cima con versione `0.1.0-beta.1`, che riporta anche l'esito della misura su opencode 1.18.23 fatta in **T10**, come è stato fatto per la misura su 1.18.18.
- `docs/review-cycle/docs/product-spec.md`: aggiornamento della sezione Artefatti per riflettere `registry.md` più `state.json`, confermato il 2026-08-27.

## Edge Cases and Risks *(Executor surface)*

**La contabilità in bash diventa illeggibile.**
Likelihood: media. Impact: manutenzione. Mitigation: `rc-lib.sh` centralizza JSON e soglie;
ogni script resta monofunzione. **Exit clause:** se un singolo script supera 250 righe o
richiede strutture annidate oltre un livello, quello script si riscrive in Python 3 con sola
stdlib, che S-34 autorizza esplicitamente senza toccare altre decisioni.

**I comandi di `collect_commands` sono sbagliati.**
Likelihood: alta — non sono stati eseguiti. Impact: **limitato dopo S-35**: si perde la
verifica aggiuntiva sui cambi indiretti di raccolta, non la garanzia di perimetro, che resta
`rc-guard.sh`. Mitigation: `rc-suites.sh collect` distingue "comando fallito" da "insieme
vuoto"; nel primo caso non ferma la lane ma lo dichiara in `hygiene.md` come copertura
mancante per quel runner. **Exit clause:** se alla tappa 1 della roadmap più di due runner su
cinque risultano sbagliati, si rimuove `collect_commands` da `signals.json` e la verifica
aggiuntiva sparisce del tutto, invece di restare una promessa che funziona a metà.

**Le lenti in parallelo divergono da quelle seriali.**
Likelihood: bassa. Impact: due passate sullo stesso diff danno esiti diversi, che è la cosa
che S-33 dava per impossibile. Mitigation: l'input di ogni lente è esattamente
`change-brief.md` più `intent.md`, e il prompt dell'agent `lens-runner` non trasmette altro
contesto. **Exit clause:** se una passata di controllo sullo stesso diff dà due liste di
esiti con intersezione inferiore a due terzi, si torna all'esecuzione seriale ovunque e si
riapre S-33.

**Un fix di igiene rompe un consumatore non coperto da alcun test.**
Likelihood: media. Impact: regressione silenziosa, ed è la tensione T-02 già registrata come
aperta. Mitigation: `hygiene.md` dichiara sempre quali suite erano fuori dal gate e perché
(S-23), così l'informazione esiste al momento in cui serve. **Exit clause:** se accade una
volta su codice condiviso, la lane si restringe a commenti, documentazione e formattazione
finché tutte le suite presenti nel repository non sono verdi.

**Il contratto JSON fra script e skill si rompe silenziosamente.**
Likelihood: media. Impact: l'orchestratore invoca la lista sbagliata di skill senza
accorgersene. Mitigation: `TEST-RC-04` e `TEST-RC-05` fissano la forma dell'output di
`rc-floor.sh` su due inventari noti. **Exit clause:** se il contratto cambia più di due volte
durante l'implementazione, si aggiunge uno schema JSON in `data/` e una funzione
`validate_contract()` in `rc-lib.sh`.

**Una versione futura di opencode cambia la risoluzione dei percorsi delle skill.**
Likelihood: bassa nel breve, ma il comportamento è già cambiato una volta fra `1.18.18` e la
correzione di `qa-architect`. Impact: le tre skill che usano gli script non li trovano.
Mitigation: `STRUCT-RC-24` e `STRUCT-RC-25` verificano la raggiungibilità *attraverso*
`.agents/skills/`, quindi una regressione di layout viene colta dai test; una regressione del
resolver di opencode no, perché i test girano sul filesystem. **Exit clause:** se una versione
futura rompe i link annidati, si passa a copie fisiche di `scripts/` e `methodology-core.md`
dentro le directory che le usano, con un test di uguaglianza byte a byte e uno script
`sync-shared.sh` invocato in CI; la compatibilità con OpenCode resta e nessun'altra decisione
cambia.

**Un `../../` si insinua in un `SKILL.md` durante la manutenzione.**
Likelihood: media — è il modo naturale di scrivere un percorso, ed è ciò che fanno
`refactor-discovery` e `automate`. Impact: la skill funziona su Claude Code e fallisce
silenziosamente su OpenCode. Mitigation: `STRUCT-RC-26` lo vieta meccanicamente, e
`STRUCT-RC-24`/`STRUCT-RC-25` verificano la raggiungibilità *attraverso* `.agents/skills/`
invece che sul percorso reale — che è la lezione di `STRUCT-QA-04`, il test che non aveva
colto il problema perché controllava il percorso sbagliato.

## Failure Modes and Degradation *(Executor surface)*

| Componente | Modo di guasto | Cosa vede l'utente | Soglia o fallback |
| --- | --- | --- | --- |
| `rc-recognize.sh` | Copertura sotto soglia | Elenco dei file non classificati e una domanda su come collocarli | Soglia da `thresholds.json`; se `null`, nessun blocco e una riga `INERT:` |
| `rc-floor.sh` | Nessun segnale trovato | Corsia calcolata dal solo strato di base, con `layer: "base"` nel brief | Nessun fallback: lo strato di base risponde sempre |
| `rc-suites.sh discover` | Nessun workflow di CI trovato | Richiesta esplicita del comando dei test, memorizzata in `state.json` | Una domanda per repository, mai ripetuta |
| `rc-suites.sh run` | Suite autorevole rossa prima di iniziare | La lane non parte e dice quale suite è rossa | Nessun fallback: S-08 lo esclude |
| `rc-suites.sh run` | Suite rossa dopo i fix | Bisezione per categoria; il gruppo colpevole viene scartato e riclassificato | Se le categorie sono più di 5, si scarta l'intero lotto invece di bisezionare (Q-14 aperta) |
| `rc-suites.sh collect` | Comando di collect assente o fallito | `hygiene.md` dichiara la verifica aggiuntiva come non disponibile per quel runner | La lane prosegue: la garanzia meccanica è `rc-guard.sh`, non il collect |
| `rc-guard.sh` | Un file di test è stato toccato | Elenco dei file e blocco prima del commit | Nessun fallback: è la chiusura ricorsiva di S-09 nella forma irrigidita da S-35 |
| `roles.test` | Un file di test non corrisponde ad alcun pattern | Nessun avviso specifico | Coperto solo parzialmente dal controllo di copertura del riconoscimento; è il buco dichiarato di S-35 |
| Strumento `Agent` assente | Nessun parallelismo | Nessun messaggio; le lenti girano in serie | Rilevamento, non assunzione (S-33) |
| `rc-validate.sh` | Esiti incompleti | Elenco delle righe non conformi | L'orchestratore rimanda alla lente che li ha prodotti, una volta sola; al secondo fallimento l'esito viene scartato e la cosa scritta in `review.md` |
| `rc-registry.sh` | `state.json` corrotto | Errore esplicito con il percorso del file | Nessuna riparazione automatica: lo stato operativo non si indovina |

## Task Breakdown *(Executor surface)*

- [x] **T1** — Creare l'albero di `plugins/review-cycle/` con i due manifest. Criterio: `jq .` su entrambi i file esce `0`.
- [x] **T2** — Scrivere `data/signals.json` e `data/thresholds.json`. Criterio: `STRUCT-RC-15` e `STRUCT-RC-16` passano.
- [x] **T3** — Scrivere `scripts/rc-lib.sh` con emissione JSON, risoluzione radice, lettura soglie e righe `INERT:`. Criterio: `bash -n` pulito e una chiamata di prova che stampa `INERT:` con soglia `null`.
- [x] **T4** — Scrivere `rc-recognize.sh` e `rc-inventory.sh`, incluso il calcolo della profondità di area di S-36 e la sua memorizzazione in `state.json`. Criterio: eseguiti su `HEAD~1...HEAD` di questo repository producono JSON valido con `coverage` maggiore di zero e una profondità di area stabile fra due esecuzioni.
- [x] **T5** — Scrivere `rc-floor.sh` con la lista `invoke`. Criterio: `TEST-RC-04` e `TEST-RC-05` passano.
- [x] **T6** — Scrivere `rc-registry.sh` (`init`, `append-pass`, `set-test-command`, `set-area-mapping`, `promote-check`, `debt-*`). Criterio: due `append-pass` consecutivi producono due righe in `registry.md` e non una sovrascrittura.
- [x] **T7** — Scrivere `rc-suites.sh` (`discover`, `enumerate`, `collect`, `run`). Criterio: `enumerate` su questo repository trova `tests/scripts/run-tests.sh` e lo marca come coperto dalla CI.
- [x] **T8** — Scrivere `rc-validate.sh` e `rc-guard.sh`. Criterio: `TEST-RC-01`, `TEST-RC-02`, `TEST-RC-03`, `TEST-RC-07`, `TEST-RC-08` passano.
- [x] **T9** — Scrivere i cinque file di metodologia: `docs/methodology-core.md` alla radice del plugin, e i quattro per lente dentro la directory della lente cui appartengono. Criterio: `methodology-core.md` non contiene nulla di specifico di una singola lente, e nessun file per lente vive in `docs/`.
- [x] **T10** — ~~Misurare il comportamento di opencode sui link annidati.~~ **Eseguito il 2026-08-26 su opencode 1.18.23: lettura riuscita al primo tentativo attraverso link annidati di directory e di file, e percorso `../../` fallito con uscita dal progetto e rifiuto per `external_directory`.** Nessun ripiego su copie necessario. L'esito va riportato nella voce di `CHANGELOG.md` in **T15**, come è stato fatto per opencode 1.18.18.
- [x] **T11** — Scrivere le sei `SKILL.md` e `agents/lens-runner.md`, con `effort: high` su orchestratore e lenti. Criterio: `STRUCT-RC-21` e `STRUCT-RC-26` passano, cioè nessun ramo sulla corsia e nessun `../../` nei prompt.
- [x] **T12** — Aggiungere le voci ai due marketplace, versione `0.1.0-beta.1`, e creare i sei symlink in `.agents/skills/` più i nove link annidati. Criterio: `STRUCT-RC-17`, `STRUCT-RC-18`, `STRUCT-RC-19`, `STRUCT-RC-23` passano.
- [x] **T13** — Aggiungere fixture e blocchi di test. Criterio: `./tests/scripts/run-tests.sh structure` e `e2e` passano con 34 test in più.
- [x] **T14** — Aggiungere il passo di validazione a `.github/workflows/ci.yml`. Criterio: il comando del passo eseguito in locale esce `0`.
- [x] **T15** — Aggiornare `CLAUDE.md`, `AGENTS.md`, `README.md`, `CHANGELOG.md` e la sezione Artefatti di `docs/review-cycle/docs/product-spec.md`, che deve riflettere `registry.md` più `state.json`. Criterio: la tabella dei plugin in `CLAUDE.md` elenca sei comandi `review-cycle`, e la voce di `CHANGELOG.md` riporta l'esito della misura su opencode 1.18.23.
- [ ] **T16** — Passata di rodaggio su una PR di questo repository (tappa 1 della roadmap in spec). Criterio: `/review-cycle` produce `change-brief.md`, `review.md` e `hygiene.md` senza errori di percorso; `hygiene.md` contiene o i commit prodotti o la dichiarazione esplicita che non c'era nulla di correggibile automaticamente. Un rodaggio senza fix da applicare è un esito valido, non un fallimento.

---

## Operations Guide *(Appendix — instructions for any agent operating on this plan)*

Operations available on this plan. Any coding agent can follow these instructions.

## Operation Dispatch Rule

Identify the requested operation by the user's **exact** wording:

- `plan-cycle-annotate` → run section `## plan-cycle-annotate`.
- `plan-cycle-review` → run section `## plan-cycle-review`.
- `plan-cycle-finalize` → run section `## plan-cycle-finalize`.

**No aliases.** If wording doesn't exactly match one of the three, do NOT execute: reply

> Operazione non riconosciuta. Le operazioni valide su questo piano sono: `plan-cycle-annotate`, `plan-cycle-review`, `plan-cycle-finalize`.

Existing `> **NOTE**:` lines don't change the requested operation. For `plan-cycle-annotate`, never edit/remove/resolve/rewrite existing plan content.

## Grilling discipline

When an operation needs decisions from you, it grills — it resolves the decision tree in waves, never as a flat dump:

- **Per wave, ask only mutually independent (orthogonal) questions.** Two questions are dependent — and MUST NOT share a wave — if the answer to one would change the answer to the other, or change whether the other still needs asking. Independent questions don't influence each other, so they may be grouped (a handful at most).
- **Walk the tree in waves.** Answer the current orthogonal set, follow the branches the answers open, and let the newly-unblocked questions form the next wave. Repeat until no branch is left open.
- **Every question carries a recommended answer** (the planner's default) with a one-line why.
- **Explore before asking.** If the codebase or the plan can answer it, investigate and state the finding instead of asking.

## plan-cycle-annotate

Add inline annotations below the section/task they refer to. Do NOT modify plan content — only add notes.

**Format:** `> **NOTE**: [tag?] comment`. Tags: `[impact]` (plan-impact skill), `[quality: <criterion>]` (plan-quality skill), none (user). `plan-cycle-review` processes all uniformly.

**Safety check:** before editing, state "plan-cycle-annotate mode: I will only add `> **NOTE**:` lines." After editing, verify the diff only adds notes + blank spacing; if it removes/modifies non-note text, revert and redo.

## plan-cycle-review

1. Read the entire plan.
2. Find all `> **NOTE**:` lines.
3. For each: understand, update plan, remove annotation.
4. If unclear, keep the annotation and resolve it via the **Grilling discipline** (above).

## plan-cycle-finalize

Make the plan operative, self-contained, coherent, robust — a fresh agent must execute it without prior context.

1. Read the entire plan.
2. For each section, check ALL 11 rules: Self-contained, Operative, Outcome-layer success, Numbers-not-adjectives, Exit clauses, Explicit degradation, Verify-before-claim, Enumerate-universals, Mark-unverifiable, Coherent, Robust.
3. Rewrite every failing section — do not annotate.
4. Report: sections updated count + one-line summary per section.
5. **Unresolved Items Inventory** — list every remaining TODO, `assumed:`, `unverified:`. For each, prompt the user per item via the **Grilling discipline** (above): *resolve before execution* or *proceed knowingly with consequence stated*. Approval is invalid without this step.

## General Principles

- `plan-cycle-annotate` may only add `> **NOTE**:` annotations — never rewrites.
- `plan-cycle-review` and `plan-cycle-finalize` rewrite plan content directly.
- Multiple annotate passes can run before a single review pass.
- The plan is approved only when the owner explicitly says so.
