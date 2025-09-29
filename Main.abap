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

    "Call to get ALV table description
    PERFORM f_descr_t_alv.

    IF gt_alv IS NOT INITIAL.
        " Call form to display ALV
        PERFORM f_display_salv.
    ELSE.
        MESSAGE TEXT-W01 TYPE 'W'.
    ENDIF.