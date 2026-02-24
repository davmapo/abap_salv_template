*&---------------------------------------------------------------------*
*& Include          Z_SALV_TOP
*&---------------------------------------------------------------------*

**** DATA FOR SALV ****
TYPE-POOLS: icon.

TYPES: BEGIN OF ty_alv,                                         "Structure for ALV
         "put your fields here
       END OF ty_alv.

DATA: gt_alv TYPE TABLE OF ty_alv,                              "Internal table for ALV
      go_alv_t_descr TYPE REF TO cl_abap_tabledescr,            "Table description object
      go_alv_s_descr TYPE REF TO cl_abap_structdescr,           "Structure description object
      gt_alv_f_descr TYPE abap_compdescr_tab.                       "Field description ALV table

DATA: go_alv TYPE REF TO cl_salv_table,                         "SALV object
      go_container TYPE REF TO cl_gui_custom_container,         "Container for ALV
      go_settings TYPE REF TO cl_salv_display_settings,         "Display settings object
      go_layout TYPE REF TO cl_salv_layout,                     "Layout object
      go_selection TYPE REF TO cl_salv_selections,              "Selection object
      go_columns TYPE REF TO cl_salv_columns_table,             "Columns object
      go_column TYPE REF TO cl_salv_column_table,                "Single column object
      go_functions TYPE REF TO cl_salv_functions_list,          "Functions object
      go_sort TYPE REF TO cl_salv_sort,                         "Sort object
      go_filter TYPE REF TO cl_salv_filter.                     "Filter object
