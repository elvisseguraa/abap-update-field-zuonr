*&---------------------------------------------------------------------*
*& Include          ZES_PROGRAM_MAI
*&---------------------------------------------------------------------*

START-OF-SELECTION.

  REFRESH: gtd_data.
  CLEAR: gs_file.

  gs_file = p_fxls.

  CHECK gs_file IS NOT INITIAL.

  PERFORM validate_file.

  IF gs_file IS NOT INITIAL.
    PERFORM read_file_xls.
  ELSE.
    MESSAGE 'archivo no encontrado' TYPE 'S' DISPLAY LIKE 'W'.
  ENDIF.

  IF gtd_data[] IS NOT INITIAL.
    PERFORM process.
    PERFORM display_alv.
  ENDIF.

END-OF-SELECTION.