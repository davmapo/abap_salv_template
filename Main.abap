*&---------------------------------------------------------------------*
*& Report Z_SALV
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z_SALV.

INCLUDE Z_SALV_top.
INCLUDE Z_SALV_class.
INCLUDE Z_SALV_sel.
INCLUDE Z_SALV_frm.

START-OF-SELECTION.

    IF gt_alv IS NOT INITIAL.
        " Call form to display ALV
        PERFORM f_display_salv USING REF #( gt_alv ).
    ELSE.
        MESSAGE TEXT-W01 TYPE 'W'.
    ENDIF.