# ABAP SALV Template

Reusable template for creating ALV reports using the `CL_SALV_TABLE` class in ABAP.

---

## Table of Contents

- [Project structure](#project-structure)
- [Global data (`Z_SALV_TOP`)](#global-data-z_salv_top)
  - [Types](#types)
  - [Global variables](#global-variables)
- [Class (`Z_SALV_CLASS`)](#class-z_salv_class)
  - [`lcl_event_handler`](#lcl_event_handler)
    - [Method `m_link_click`](#method-m_link_click)
    - [Method `m_added_function`](#method-m_added_function)
- [Form (`Z_SALV_FORM`)](#form-z_salv_form)
  - [`f_display_salv`](#f_display_salv)
  - [`f_modify_display_settings`](#f_modify_display_settings)
  - [`f_modify_layout`](#f_modify_layout)
  - [`f_set_columns`](#f_set_columns)
  - [`f_set_functions`](#f_set_functions)
- [Execution flow](#execution-flow)
- [Usage notes](#usage-notes)

---

## Project structure

| File | ABAP Include | Description |
|---|---|---|
| `Main.abap` | `Z_SALV` | Main report, entry point |
| `Global data.abap` | `Z_SALV_TOP` | Global data, types and variables |
| `Class.abap` | `Z_SALV_CLASS` | Class for event handling |
| `Form.abap` | `Z_SALV_FORM` | Form routines for ALV display and configuration |

---

## Global data (`Z_SALV_TOP`)

Defines all types and global variables shared across includes.

### Types

| Type | Description |
|---|---|
| `ty_alv` | Structure of ALV table rows. Add the required fields here. |

### Global variables

| Variable | Type | Description |
|---|---|---|
| `gt_alv` | `TABLE OF ty_alv` | Internal table holding the data to display in the ALV |
| `go_alv_t_descr` | `REF TO cl_abap_tabledescr` | Object for table description (RTTI) |
| `go_alv_s_descr` | `REF TO cl_abap_structdescr` | Object for table structure description (RTTI) |
| `gt_alv_f_descr` | `abap_compdescr_tab` | Table with descriptors of the individual structure fields |
| `go_alv` | `REF TO cl_salv_table` | Main SALV object |
| `go_container` | `REF TO cl_gui_custom_container` | Graphical container for the ALV (only needed with a custom screen) |
| `go_settings` | `REF TO cl_salv_display_settings` | Object for display settings |
| `go_layout` | `REF TO cl_salv_layout` | Object for layout management |
| `go_selection` | `REF TO cl_salv_selections` | Object for row selection management |
| `go_columns` | `REF TO cl_salv_columns_table` | Object for column management |
| `go_column` | `REF TO cl_salv_column_table` | Object for single column management |
| `go_functions` | `REF TO cl_salv_functions_list` | Object for toolbar buttons/functions management |
| `go_sort` | `REF TO cl_salv_sort` | Object for sort management |
| `go_filter` | `REF TO cl_salv_filter` | Object for filter management |

---

## Class (`Z_SALV_CLASS`)

### `lcl_event_handler`

Local class for handling events raised by the ALV.

#### Method `m_link_click`

```abap
m_link_click FOR EVENT link_click OF cl_salv_events_table
  IMPORTING row, column
```

Handles clicks on cells of type `checkbox_hotspot`.

- Reads the clicked row from `gt_alv` using the `row` index.
- If the `checkbox` field is empty, sets it to `'X'` and adds the row to the selected rows list (`lt_selected_rows`).
- If `checkbox` is already checked, clears it and removes the row from the list.
- Calls `go_alv->refresh()` with row and column stabilization to update the display without losing the current position.

#### Method `m_added_function`

```abap
m_added_function FOR EVENT added_function OF cl_salv_events_table
  IMPORTING e_salv_function
```

Handles presses of custom buttons added to the ALV toolbar.

- Uses a `CASE` on `e_salv_function` to identify the pressed button and call the corresponding form.
- Example: pressing `'1_MY_FUNCTION'` calls `f_1_my_function`.

---

## Form (`Z_SALV_FORM`)

### `f_display_salv`

```abap
FORM f_display_salv USING pr_table TYPE REF TO data.
```

Main form that creates and displays the ALV. Receives the data table as `TYPE REF TO data` (generic reference), which allows it to be called with tables of different structures without changing the form signature.

- If `go_alv` is already instantiated, performs a simple `refresh()`.
- Otherwise:
  1. Assigns the `pr_table` reference to a generic field-symbol (`FIELD-SYMBOLS: <lt_table> TYPE ANY TABLE`), dereferencing the pointer to pass the table to `cl_salv_table=>factory`.
  2. Creates `go_container` with name `'CONTAINER'` (only needed with a custom screen).
  3. Instantiates the ALV object via `cl_salv_table=>factory`.
  4. Reads the table structure via RTTI (inline): populates `go_alv_t_descr`, `go_alv_s_descr`, `gt_alv_f_descr`.
  5. Calls the configuration forms: `f_modify_display_settings`, `f_modify_layout`, `f_set_columns`, `f_set_functions`.
  6. Registers event handlers (`m_link_click`, `m_added_function`) via `SET HANDLER`.
  7. Calls `go_alv->display()` to show the ALV.
- Handles exceptions `cx_salv_msg` and `cx_root`.

---

### `f_modify_display_settings`

```abap
FORM f_modify_display_settings.
```

Configures the general display settings of the ALV.

| Method | Value | Description |
|---|---|---|
| `set_list_header` | `'MY TITLE'` | ALV title |
| `set_striped_pattern` | `abap_true` | Alternating row background for improved readability |
| `set_fit_column_to_table_size` | `abap_true` | Stretches columns to fill the full table width |

---

### `f_modify_layout`

```abap
FORM f_modify_layout.
```

Configures the ALV layout and row selection mode.

| Method | Value | Description |
|---|---|---|
| `go_layout->set_key` | `report = sy-repid` | Unique key for layout saving |
| `go_layout->set_default` | `abap_true` | Use this layout as default |
| `go_layout->set_save_restriction` | `restrict_none` | Allows the user to save custom layouts |
| `go_selection->set_selection_mode` | `single` | Single row selection mode. Possible values: `none`, `single`, `multiple`, `cell`, `row_column` |

---

### `f_set_columns`

```abap
FORM f_set_columns.
```

Configures the individual ALV columns. Loops over `gt_alv_f_descr` and for each field executes a `CASE` on the field name.

**Adding a checkbox column:**
- `go_columns->add_column('CHECKBOX')`: adds a column named `CHECKBOX`.
- `set_cell_type( if_salv_c_cell_type=>checkbox_hotspot )`: sets the cell type to clickable checkbox.

**Configuration for `'FIELD NAME'`** (example field):

| Method | Description |
|---|---|
| `set_visible( abap_false )` | Hides the column |
| `set_technical( abap_true )` | Marks the column as technical (not visible or selectable by the user) |
| `set_color( ls_color )` | Column color. `col`: 0=default, 1=blue, 2=grey, 3=yellow, 4=blue-grey, 5=green, 6=red, 7=orange. `int`: 0=normal, 1=intense. `inv`: 0=off, 1=inverse |
| `set_short_text` / `set_medium_text` / `set_long_text` | Column header texts for different display widths |
| `set_output_length( 25 )` | Fixed column width in characters |

**Configuration for `'ICON'`:**
- `set_icon( abap_true )`: interprets the cell value as an ABAP icon.
- `set_optimized( abap_true )`: optimizes the column width.

**`WHEN OTHERS`:**
- `set_optimized( abap_true )`: automatically optimizes the width of all other columns.

---

### `f_set_functions`

```abap
FORM f_set_functions.
```

Configures the ALV toolbar with standard functions and custom buttons.

- `go_alv->set_screen_status`: sets a custom PF-STATUS (`ZMY_STATUS`, to be copied in SE41 from `program = SAPLSALV_METADATA_STATUS; status = SALV_TABLE_STANDARD`) and enables all standard functions (`c_functions_all`). Possible values: `c_functions_all`, `c_functions_default`, `c_functions_none`. **Note: cannot be used with a container — full-screen mode only.**
- `go_functions->set_all( abap_true )`: enables all standard functions.
- `go_functions->add_function(...)`: adds a custom button to the toolbar.

**Parameters of `add_function`:**

| Parameter | Description |
|---|---|
| `name` | Unique button name (e.g. `'1_MY_FUNCTION'`) |
| `icon` | ABAP icon to display |
| `text` | Button label |
| `tooltip` | Tooltip text |
| `position` | Position in the toolbar. Values: `left_of_salv_functions`, `right_of_salv_functions`, `is_salv_functions` |

Handles exceptions `cx_salv_existing`, `cx_salv_wrong_call`, `cx_root`.

---

## Execution flow

```
START-OF-SELECTION
    └─ gt_alv populated?
        ├─ NO  → MESSAGE W01
        └─ YES → f_display_salv( REF #( gt_alv ) )
                    ├─ go_alv already instantiated? → go_alv->refresh()
                    └─ NO
                        ├─ ASSIGN pr_table → <lt_table>
                        ├─ CREATE OBJECT go_container
                        ├─ cl_salv_table=>factory (create ALV object)
                        ├─ RTTI inline (go_alv_t_descr, go_alv_s_descr, gt_alv_f_descr)
                        ├─ f_modify_display_settings
                        ├─ f_modify_layout
                        ├─ f_set_columns
                        ├─ f_set_functions
                        ├─ SET HANDLER (link_click, added_function)
                        └─ go_alv->display()
```

---

## Usage notes

- The `ty_alv` structure in `Z_SALV_TOP` must be filled with the fields of your report.
- The container (`go_container`) is only needed when using a custom screen with `SELECTION-SCREEN` or a dynpro. For a simple report it can be removed along with the `r_container` parameter in the `factory` call.
- In `f_set_columns`, the `go_columns->get_columns()` and `set_optimize()` lines are commented out: uncomment them to optimize all columns globally (as an alternative to `set_fit_column_to_table_size` in the display settings). Adapt the `WHEN` branches to your own field names.
- To add new custom buttons, add an `add_function` call in `f_set_functions` and the corresponding `WHEN` branch in `m_added_function`.
