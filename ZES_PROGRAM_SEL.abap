*&---------------------------------------------------------------------*
*& Include          ZES_PROGRAM_SEL
*&---------------------------------------------------------------------*

DATA: ltd_file TYPE filetable,
      li_rc    TYPE i,
      lw_file  TYPE file_table.

SELECTION-SCREEN BEGIN OF BLOCK b_1 WITH FRAME TITLE text-001.
PARAMETERS:
  p_fxls TYPE localfile DEFAULT '' MODIF ID g1.",
SELECTION-SCREEN END OF BLOCK b_1.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_fxls.
  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title = 'Seleccionar archivo'
      file_filter  = '(*.xls,*.xlsx)|*.xls*'
    CHANGING
      file_table   = ltd_file
      rc           = li_rc.
  IF sy-subrc EQ 0.
    READ TABLE ltd_file INTO lw_file INDEX 1.
    p_fxls = lw_file-filename.
  ENDIF.