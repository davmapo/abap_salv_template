*&---------------------------------------------------------------------*
*& Include          Z_SALV_CLASS
*&---------------------------------------------------------------------*

***** Event handler class for ALV events *****

CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS:
      " Handle click on checkbox hotspot.
      m_link_click
        FOR EVENT link_click OF cl_salv_events_table
        IMPORTING
          row, column,
      
      " Handle added functions.
      m_added_function
        FOR EVENT added_function OF cl_salv_events_table
        IMPORTING
          e_salv_function.
ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.

    METHOD m_link_click.

        " Handle click on checkbox hotspot.

        DATA: lt_selected_rows TYPE salv_t_row.

        lt_selected_rows = go_selection->get_selected_rows( ).

        READ TABLE gt_alv ASSIGNING FIELD-SYMBOL(<ls_alv>) INDEX row.
        IF sy-subrc IS INITIAL.
            IF <ls_alv>-checkbox IS INITIAL.
                <ls_alv>-checkbox = 'X'.
                IF line_exists( lt_selected_rows[ table_line = row ] ) = abap_false.
                    APPEND row TO lt_selected_rows.
                ENDIF.
            ELSE.
                CLEAR <ls_alv>-checkbox.
                DELETE lt_selected_rows = row.
            ENDIF.
        ENDIF.
        go_alv->refresh( s_stable = VALUE #( row = abap_true col = abap_true )  ).

    ENDMETHOD.

    METHOD m_added_function.

        " Handle added functions passing selected rows.

        DATA: lt_selected_rows TYPE salv_t_row.

        lt_selected_rows = go_selection->get_selected_rows( ).

        CASE e_salv_function.
            
            " Example
            WHEN '1_MY_FUNCTION'.
                
                PERFORM f_1_my_function USING lt_selected_row.

        " Add more cases as needed for other fields

        ENDCASE.

    ENDMETHOD.

ENDCLASS.