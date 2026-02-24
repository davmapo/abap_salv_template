# ABAP SALV Template

Template riutilizzabile per la creazione di report ALV con la classe `CL_SALV_TABLE` in ABAP.

---

## Indice

- [Struttura del progetto](#struttura-del-progetto)
- [Global data (`Z_SALV_TOP`)](#global-data-z_salv_top)
  - [Tipi](#tipi)
  - [Variabili globali](#variabili-globali)
- [Class (`Z_SALV_CLASS`)](#class-z_salv_class)
  - [`lcl_event_handler`](#lcl_event_handler)
    - [Metodo `m_link_click`](#metodo-m_link_click)
    - [Metodo `m_added_function`](#metodo-m_added_function)
- [Form (`Z_SALV_FORM`)](#form-z_salv_form)
  - [`f_display_salv`](#f_display_salv)
  - [`f_modify_display_settings`](#f_modify_display_settings)
  - [`f_modify_layout`](#f_modify_layout)
  - [`f_set_columns`](#f_set_columns)
  - [`f_set_functions`](#f_set_functions)
- [Flusso di esecuzione](#flusso-di-esecuzione)
- [Note d'uso](#note-duso)

---

## Struttura del progetto

| File | Include ABAP | Descrizione |
|---|---|---|
| `Main.abap` | `Z_SALV` | Report principale, entry point |
| `Global data.abap` | `Z_SALV_TOP` | Dati globali, tipi e variabili |
| `Class.abap` | `Z_SALV_CLASS` | Classe per la gestione degli eventi |
| `Form.abap` | `Z_SALV_FORM` | Form routines per la visualizzazione e configurazione dell'ALV |

---

## Global data (`Z_SALV_TOP`)

Definisce tutti i tipi e le variabili globali condivisi tra gli include.

### Tipi

| Tipo | Descrizione |
|---|---|
| `ty_alv` | Struttura delle righe della tabella ALV. Aggiungere qui i campi necessari. |

### Variabili globali

| Variabile | Tipo | Descrizione |
|---|---|---|
| `gt_alv` | `TABLE OF ty_alv` | Tabella interna con i dati da visualizzare nell'ALV |
| `go_alv_t_descr` | `REF TO cl_abap_tabledescr` | Oggetto per la descrizione della tabella (RTTI) |
| `go_alv_s_descr` | `REF TO cl_abap_structdescr` | Oggetto per la descrizione della struttura della tabella (RTTI) |
| `gt_alv_f_descr` | `abap_compdescr_tab` | Tabella con i descrittori dei singoli campi della struttura |
| `go_alv` | `REF TO cl_salv_table` | Oggetto principale SALV |
| `go_container` | `REF TO cl_gui_custom_container` | Container grafico per l'ALV (necessario solo con screen custom) |
| `go_settings` | `REF TO cl_salv_display_settings` | Oggetto per le impostazioni di visualizzazione |
| `go_layout` | `REF TO cl_salv_layout` | Oggetto per la gestione del layout |
| `go_selection` | `REF TO cl_salv_selections` | Oggetto per la gestione della selezione righe |
| `go_columns` | `REF TO cl_salv_columns_table` | Oggetto per la gestione delle colonne |
| `go_column` | `REF TO cl_salv_column_table` | Oggetto per la gestione di una singola colonna |
| `go_functions` | `REF TO cl_salv_functions_list` | Oggetto per la gestione dei bottoni/funzioni della toolbar |
| `go_sort` | `REF TO cl_salv_sort` | Oggetto per la gestione dell'ordinamento |
| `go_filter` | `REF TO cl_salv_filter` | Oggetto per la gestione dei filtri |

---

## Class (`Z_SALV_CLASS`)

### `lcl_event_handler`

Classe locale per la gestione degli eventi generati dall'ALV.

#### Metodo `m_link_click`

```abap
m_link_click FOR EVENT link_click OF cl_salv_events_table
  IMPORTING row, column
```

Gestisce il click su una cella di tipo `checkbox_hotspot`.

- Legge la riga cliccata dalla tabella `gt_alv` tramite l'indice `row`.
- Se il campo `checkbox` è vuoto, lo imposta a `'X'` e aggiunge la riga alla lista delle righe selezionate (`lt_selected_rows`).
- Se `checkbox` è già selezionato, lo deseleziona e rimuove la riga dalla lista.
- Chiama `go_alv->refresh()` con stabilizzazione di righe e colonne per aggiornare la visualizzazione senza perdere la posizione.

#### Metodo `m_added_function`

```abap
m_added_function FOR EVENT added_function OF cl_salv_events_table
  IMPORTING e_salv_function
```

Gestisce la pressione dei bottoni custom aggiunti alla toolbar dell'ALV.

- Usa un `CASE` su `e_salv_function` per identificare il bottone premuto e richiamare la form corrispondente.
- Esempio: alla pressione di `'1_MY_FUNCTION'` viene chiamata `f_1_my_function`.

---

## Form (`Z_SALV_FORM`)

### `f_display_salv`

```abap
FORM f_display_salv USING pr_table TYPE REF TO data.
```

Form principale che crea e visualizza l'ALV. Riceve la tabella dati come `TYPE REF TO data` (riferimento generico), il che permette di richiamarla con tabelle di struttura diversa senza modificare la firma della form.

- Se `go_alv` è già istanziato, esegue un semplice `refresh()`.
- Altrimenti:
  1. Assegna il riferimento `pr_table` a un field-symbol generico (`FIELD-SYMBOLS: <lt_table> TYPE ANY TABLE`), dereferenziando il puntatore per passare la tabella a `cl_salv_table=>factory`.
  2. Crea il `go_container` con il nome `'CONTAINER'` (necessario solo con screen custom).
  3. Istanzia l'oggetto ALV tramite `cl_salv_table=>factory`.
  4. Legge la struttura della tabella via RTTI (inline): popola `go_alv_t_descr`, `go_alv_s_descr`, `gt_alv_f_descr`.
  5. Chiama le form di configurazione: `f_modify_display_settings`, `f_modify_layout`, `f_set_columns`, `f_set_functions`.
  6. Registra i gestori degli eventi (`m_link_click`, `m_added_function`) tramite `SET HANDLER`.
  7. Chiama `go_alv->display()` per mostrare l'ALV.
- Gestisce le eccezioni `cx_salv_msg` e `cx_root`.

---

### `f_modify_display_settings`

```abap
FORM f_modify_display_settings.
```

Configura le impostazioni di visualizzazione generali dell'ALV.

| Metodo chiamato | Valore | Descrizione |
|---|---|---|
| `set_list_header` | `'MY TITLE'` | Titolo dell'ALV |
| `set_striped_pattern` | `abap_true` | Righe con sfondo alternato per migliorare la leggibilità |
| `set_fit_column_to_table_size` | `abap_true` | Adatta la larghezza delle colonne alla dimensione della tabella |

---

### `f_modify_layout`

```abap
FORM f_modify_layout.
```

Configura il layout dell'ALV e la modalità di selezione righe.

| Metodo chiamato | Valore | Descrizione |
|---|---|---|
| `go_layout->set_key` | `report = sy-repid` | Chiave univoca per il salvataggio del layout |
| `go_layout->set_default` | `abap_true` | Usa questo layout come predefinito |
| `go_layout->set_save_restriction` | `restrict_none` | Permette all'utente di salvare layout personalizzati |
| `go_selection->set_selection_mode` | `single` | Modalità selezione riga singola. Valori possibili: `none`, `single`, `multiple`, `cell`, `row_column` |

---

### `f_set_columns`

```abap
FORM f_set_columns.
```

Configura le singole colonne dell'ALV. Scorre `gt_alv_f_descr` tramite un `LOOP` e per ogni campo esegue un `CASE` sul nome.

**Aggiunta colonna checkbox:**
- `go_columns->add_column('CHECKBOX')`: aggiunge una colonna con nome `CHECKBOX`.
- `set_cell_type( if_salv_c_cell_type=>checkbox_hotspot )`: imposta la cella come checkbox cliccabile.

**Configurazione per `'FIELD NAME'`** (campo di esempio):

| Metodo | Descrizione |
|---|---|
| `set_visible( abap_false )` | Nasconde la colonna |
| `set_technical( abap_true )` | Imposta la colonna come tecnica (non visibile/selezionabile dall'utente) |
| `set_color( ls_color )` | Colore della colonna. `col`: 0=default, 1=blu, 2=grigio, 3=giallo, 4=blu-grigio, 5=verde, 6=rosso, 7=arancione. `int`: 0=normale, 1=intenso. `inv`: 0=off, 1=inverso |
| `set_short_text` / `set_medium_text` / `set_long_text` | Testi della colonna per le diverse larghezze |
| `set_output_length( 25 )` | Larghezza fissa della colonna in caratteri |

**Configurazione per `'ICON'`:**
- `set_icon( abap_true )`: interpreta il valore della cella come icona ABAP.
- `set_optimized( abap_true )`: ottimizza la larghezza della colonna.

**`WHEN OTHERS`:**
- `set_optimized( abap_true )`: ottimizza automaticamente la larghezza di tutte le altre colonne.

---

### `f_set_functions`

```abap
FORM f_set_functions.
```

Configura la toolbar dell'ALV con funzioni standard e bottoni custom.

- `go_alv->set_screen_status`: imposta un PF-STATUS custom (`ZMY_STATUS`, da copiare in SE41 da `program = SAPLSALV_METADATA_STATUS; status = SALV_TABLE_STANDARD`) e abilita tutte le funzioni standard (`c_functions_all`). Valori possibili: `c_functions_all`, `c_functions_default`, `c_functions_none`. **Attenzione: non utilizzabile con un container — solo in full-screen mode.**
- `go_functions->set_all( abap_true )`: abilita tutte le funzioni standard.
- `go_functions->add_function(...)`: aggiunge un bottone custom alla toolbar.

**Parametri di `add_function`:**

| Parametro | Descrizione |
|---|---|
| `name` | Nome univoco del bottone (es. `'1_MY_FUNCTION'`) |
| `icon` | Icona ABAP da visualizzare |
| `text` | Testo del bottone |
| `tooltip` | Testo del tooltip |
| `position` | Posizione nella toolbar. Valori: `left_of_salv_functions`, `right_of_salv_functions`, `is_salv_functions` |

Gestisce le eccezioni `cx_salv_existing`, `cx_salv_wrong_call`, `cx_root`.

---

## Flusso di esecuzione

```
START-OF-SELECTION
    └─ gt_alv popolato?
        ├─ NO  → MESSAGE W01
        └─ SI  → f_display_salv( REF #( gt_alv ) )
                    ├─ go_alv già istanziato? → go_alv->refresh()
                    └─ NO
                        ├─ ASSIGN pr_table → <lt_table>
                        ├─ CREATE OBJECT go_container
                        ├─ cl_salv_table=>factory (crea oggetto ALV)
                        ├─ RTTI inline (go_alv_t_descr, go_alv_s_descr, gt_alv_f_descr)
                        ├─ f_modify_display_settings
                        ├─ f_modify_layout
                        ├─ f_set_columns
                        ├─ f_set_functions
                        ├─ SET HANDLER (link_click, added_function)
                        └─ go_alv->display()
```

---

## Note d'uso

- La struttura `ty_alv` in `Z_SALV_TOP` va completata con i campi del proprio report.
- Il container (`go_container`) è necessario solo se si usa uno screen custom con `SELECTION-SCREEN` o dynpro. Per un report semplice può essere rimosso insieme al parametro `r_container` nella `factory`.
- In `f_set_columns`, le righe `go_columns->get_columns()` e `set_optimize()` sono commentate: decommentarle se si vuole ottimizzare tutte le colonne globalmente (in alternativa a `set_fit_column_to_table_size` nelle display settings). Adattare i `WHEN` ai nomi dei propri campi.
- Per aggiungere nuovi bottoni custom, aggiungere una chiamata a `add_function` in `f_set_functions` e il relativo `WHEN` in `m_added_function`.
