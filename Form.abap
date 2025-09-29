*&---------------------------------------------------------------------*
*& Form f_descr_t_alv.
*&---------------------------------------------------------------------*
FORM f_descr_t_alv.
    " Get ALV table description
    go_alv_t_descr ?= cl_abap_typedescr=>describe_by_data( gt_alv ).
    gr_alv_s_descr ?= go_alv_t_descr->get_table_line_type( ).
    gt_alv_f_descr = gr_descr->components.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_display_salv
*&---------------------------------------------------------------------*
FORM f_display_salv.

    IF go_alv IS NOT INITIAL.
      go_alv->refresh( ).
    ELSE.
        TRY.
            "Create custom container for ALV --> No need for SALV without container
            CREATE OBJECT go_container
                EXPORTING
                container_name = 'CONTAINER'.
        
            "Create ALV table object
            CALL METHOD cl_salv_table=>factory
                EXPORTING
                r_container = go_container   " Link to custom container --> No need without container
                container_name = 'CONTAINER' " Name of the container    --> No need without container
                IMPORTING
                r_salv_table = go_alv
                CHANGING
                t_table      = gt_alv.
        
            "Get display settings object and adjust settings as needed
            go_settings = go_alv->get_display_settings( ).
            go_settings->set_list_header( 'MY TITLE' ).             " Set title of the ALV
            go_settings->set_striped_pattern( abap_true ).          " Enable striped pattern for better readability
            go_settings->set_fit_column_to_table_size( abap_true ). " Adjust column width

            " Get layout object and adjust layout settings as needed
            go_layout = go_alv->get_layout( ).
            DATA(ls_key) = VALUE salv_s_layout_key( report = sy-repid ).          " Unique key for layout
            go_layout->set_key( ls_key ).                                         " Set layout key
            go_layout->set_default( abap_true ).                                  " Use as default layout
            go_layout->set_save_restriction( if_salv_c_layout => restrict_none ). " Allow saving layout
            
            "set selection mode
            go_selection = go_alv->get_selections( ).
            go_selection->set_select_mode( if_salv_c_selection_mode => single ). " Set selection mode.
                                                                                 " Possible values: none, single, multiple, cell, row_column
            
            "Get columns object
            go_columns = go_alv->get_columns( ).
*            go_columns->set_optimize( abap_true ).  " Optimize column widths. It's better to use this method on a single column, 
                                                    " but if you want to optimize all columns, don't use fit_to_table_size in settings.
            
            "Add checkbox column for selection if needed
            CLEAR: go_column.
            go_column ?= go_columns-> add_column ('CHECKBOX').                  " Casting becouse add_column returns CL_SALV_COLUMN superclass, now we need CL_SALV_COLUMN_TABLE
            go_column->set_cell_type( if_salv_c_cell_type=>checkbox_hotspot ).  " Set cell type to checkbox - hotspot

            " Example: Set properties for a specific column
            go_column ?= go_columns->get_column( 'FIELD_NAME' ). " Casting becouse get_column returns CL_SALV_COLUMN superclass, now we need CL_SALV_COLUMN_TABLE
            go_column->set_short_text( 'Short Text' ).
            go_column->set_medium_text( 'Medium Text' ).
            go_column->set_long_text( 'Long Text' ).
            go_column->set_output_length( 20 ).

            PERFORM f_modify_columns. " Call form to modify columns if needed
        
            " Get functions object and enable/disable functions as needed
            go_functions = go_alv->get_functions( ).
            go_functions->set_all( abap_true ).         " Enable all functions
            
            PERFORM f_add_functions. " Call form to add custom functions if needed

            "Events handling
            go_events = go_alv->get_events( ).                     "Get events from SALV object
            CREATE OBJECT go_events.                               "Create events object
            SET HANDLER go_events->m_link_click FOR go_events.     "Set handler for click on checkbox hotspot
            SET HANDLER go_events->m_added_function FOR go_events. "Set handler for added functions

            CATCH cx_salv_msg INTO DATA(lx_salv).
                MESSAGE lx_salv TYPE 'E'.
            CATCH cx_root INTO DATA(lx_root).
                MESSAGE lx_root TYPE 'E'.
        ENDTRY.
    ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_modify_columns
*&---------------------------------------------------------------------*
FORM f_modify_columns.

    LOOP AT gt_alv_f_descr ASSIGNING FIELD-SYMBOL(<fs_field>).

        DATA: ls_color TYPE lvc_s_colo.

        CLEAR: go_column.
        go_column ?= go_columns->get_column( <fs_field>-name ). " Casting becouse get_column returns CL_SALV_COLUMN superclass, now we need CL_SALV_COLUMN_TABLE
       
        CASE <fs_field>-name.
            
            WHEN 'FIELD NAME'.

                "set visibility
                go_column->set_visible( abap_false ). "don't use if technical column

                "set technical
                go_column->set_technical( abap_true ).

                "set color
                ls_color-col = '6'. "Color code: 0 = default, 1 = blue, 2 = grey, 3 = yellow, 4 = blu/grey, 5 = green, 6 = red, 7 = orange.
                ls_color-int = '1'. "Intensity: 0 = normal, 1 = intense.
                ls_color-inv = '0'. "Inverse: 0 = off, 1 = on.
                go_column->set_color( ls_color ).

                "set text
                go_column->set_short_text( 'New Short Text' ).
                go_column->set_medium_text( 'New Medium Text' ).
                go_column->set_long_text( 'New Long Text' ).

                "set output length
                go_column->set_output_length( 25 ). "If set lenght, don't use optimize for this column.
            
                " Add more cases as needed for other fields

            WHEN 'ICON'.

                go_column->set_cell_type( if_salv_c_cell_type=>icon ). " Set cell type to icon
                go_column->set_optimized( abap_true ).
            
            WHEN OTHERS.

                go_column->set_optimized( abap_true ).

        ENDCASE.

    ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_add_functions.
*&---------------------------------------------------------------------*
FORM f_add_functions.

    TRY.
        " Example: Add a custom button to the toolbar
        go_functions->add_function(
            name = '1_MY_FUNCTION'                                          " Unique name for the button
            icon = "insert icon                                             " Icon for the button
            text = 'My Function'                                            " Text displayed on the button
            tooltip = 'This is my custom button'                            " Tooltip text
            position = if_salv_c_function_position=>right_of_salv_functions " Position of the button. Values: left_of_salv_functions, right_of_salv_functions, is_salv_functions
        ).

        CATCH cx_salv_existing INTO DATA(lx_salv_existing).
            MESSAGE lx_salv TYPE 'E'.
        CATCH cx_salv_wrong_call INTO DATA(lx_salv_wcall).
            MESSAGE lx_salv TYPE 'E'.
        CATCH cx_root INTO DATA(lx_root).
            MESSAGE lx_root TYPE 'E'.
    ENDTRY.

    "add more functions as needed

ENDFORM.

