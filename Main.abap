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
        DATA lr_alv TYPE REF TO data.
        GET REFERENCE OF gt_alv INTO lr_alv.
        PERFORM f_display_salv USING lr_alv.
    ELSE.
        MESSAGE TEXT-W01 TYPE 'W'.
    ENDIF.