*&---------------------------------------------------------------------*
*& Include          ZES_PROGRAM_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form validate_file
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM validate_file .


  DATA: ls_file   TYPE string,
        ls_existe TYPE c.

  ls_file = gs_file.

  CALL METHOD cl_gui_frontend_services=>file_exist
    EXPORTING
      file                 = ls_file                " File to Check
    RECEIVING
      result               = ls_existe                " Result
    EXCEPTIONS
      cntl_error           = 1                " Control error
      error_no_gui         = 2                " Error: No GUI
      wrong_parameter      = 3                " Incorrect parameter
      not_supported_by_gui = 4                " GUI does not support this
      OTHERS               = 5.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  IF ls_existe IS INITIAL.
    CLEAR: gs_file.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  READ_FILE_XLS
*&---------------------------------------------------------------------*
FORM read_file_xls .

  DATA: li_bcol TYPE i VALUE 1,
        li_brow TYPE i VALUE 2,
        li_ecol TYPE i VALUE 5,
        li_erow TYPE i VALUE 1000.

  CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
    EXPORTING
      filename                = gs_file
      i_begin_col             = li_bcol
      i_begin_row             = li_brow
      i_end_col               = li_ecol
      i_end_row               = li_erow
    TABLES
      intern                  = gtd_excel
    EXCEPTIONS
      inconsistent_parameters = 1
      upload_ole              = 2
      OTHERS                  = 3.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ELSE.
    PERFORM format_data_excel TABLES gtd_excel.
  ENDIF.

ENDFORM.


FORM format_data_excel  TABLES p_gtd_excel STRUCTURE alsmex_tabline.

  DATA: li_id TYPE i.

  FIELD-SYMBOLS: <fs_excel> LIKE LINE OF gtd_excel,
                 <fs_data>  LIKE LINE OF gtd_data.
*Cargamos los datos
  DO.
    ADD 1 TO li_id.
    APPEND INITIAL LINE TO gtd_data ASSIGNING <fs_data>.
    LOOP AT gtd_excel ASSIGNING <fs_excel> WHERE row = li_id.
      CONDENSE <fs_excel>-value.
      CASE <fs_excel>-col.
        WHEN '0001'.
          <fs_data>-bukrs = <fs_excel>-value.
        WHEN '0002'.
          <fs_data>-belnr = <fs_excel>-value.
          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
            EXPORTING
              input  = <fs_data>-belnr
            IMPORTING
              output = <fs_data>-belnr.
        WHEN '0003'.
          <fs_data>-gjahr = <fs_excel>-value.
        WHEN '0004'.
          <fs_data>-buzei = <fs_excel>-value.
        WHEN '0005'.
          <fs_data>-zuonr = <fs_excel>-value.
      ENDCASE.
    ENDLOOP.
    IF sy-subrc <> 0.
      EXIT.
    ENDIF.
  ENDDO.

  DELETE gtd_data WHERE bukrs IS INITIAL
                     OR belnr IS INITIAL
                     OR gjahr IS INITIAL
                     OR buzei IS INITIAL
                     OR zuonr IS INITIAL.

  DATA: ltd_data TYPE STANDARD TABLE OF gty_report,
        lwa_data TYPE gty_report,
        li_count TYPE i,
        li_next  TYPE i.

  DELETE ADJACENT DUPLICATES FROM gtd_data COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM gtd_data COMPARING bukrs belnr gjahr zuonr.

  SORT gtd_data BY bukrs belnr gjahr buzei.

  ltd_data[] = gtd_data[].

  li_count = 0.
  li_next  = 0.

  LOOP AT gtd_data ASSIGNING <fs_data> .

    li_count = li_count + 1.
    li_next  = li_count + 1.

    READ TABLE ltd_data INTO lwa_data INDEX li_next.
    IF sy-subrc EQ 0.
      IF lwa_data-bukrs EQ <fs_data>-bukrs AND lwa_data-belnr EQ <fs_data>-belnr
                                           AND lwa_data-gjahr EQ <fs_data>-gjahr.
        <fs_data>-wait = 'X'.
      ENDIF.
    ENDIF.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form process
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM process .

  DATA: ltd_buztab TYPE  tpit_t_buztab,
        ltd_fldtab TYPE  tpit_t_fname,
        ltd_errtab TYPE  tpit_t_errdoc,
        lwa_errtab LIKE LINE OF ltd_errtab.

  DATA: ls_mtype   TYPE pmst_message-msg_type,
        ls_mid     TYPE pmst_message-msg_id,
        ls_mno     TYPE pmst_message-msg_no,
*        ls_msg1    TYPE pmst_message-msg_arg1,
*        ls_msg2    TYPE pmst_message-msg_arg2,
*        ls_msg3    TYPE pmst_message-msg_arg3,
*        ls_msg4    TYPE pmst_message-msg_arg4,
        ls_errtext TYPE pmst_raw_message.

  FIELD-SYMBOLS: <fs_buztab> LIKE LINE OF ltd_buztab,
                 <fs_fldtab> LIKE LINE OF ltd_fldtab.

  SELECT * INTO TABLE gtd_bseg
    FROM bseg FOR ALL ENTRIES IN gtd_data
    WHERE bukrs = gtd_data-bukrs
      AND belnr = gtd_data-belnr
      AND gjahr = gtd_data-gjahr
      AND buzei = gtd_data-buzei.

  APPEND INITIAL LINE TO ltd_fldtab ASSIGNING <fs_fldtab>.
  <fs_fldtab>-fname = 'ZUONR'.

  LOOP AT gtd_data ASSIGNING <fs_data>.

    CLEAR: gwa_bseg, ls_mtype, ls_mid, ls_mno.
    REFRESH: ltd_errtab, ltd_buztab.

    gwa_bseg-zuonr = <fs_data>-zuonr.

    READ TABLE gtd_bseg ASSIGNING <fs_bseg> WITH KEY bukrs = <fs_data>-bukrs
                                                     belnr = <fs_data>-belnr
                                                     gjahr = <fs_data>-gjahr
                                                     buzei = <fs_data>-buzei.
    IF sy-subrc EQ 0.

      APPEND INITIAL LINE TO ltd_buztab ASSIGNING <fs_buztab>.
      <fs_buztab>-bukrs = <fs_bseg>-bukrs.
      <fs_buztab>-belnr = <fs_bseg>-belnr.
      <fs_buztab>-gjahr = <fs_bseg>-gjahr.
      <fs_buztab>-buzei = <fs_bseg>-buzei.
      <fs_buztab>-koart = <fs_bseg>-koart.
      <fs_buztab>-umskz = <fs_bseg>-umskz.
      <fs_buztab>-bschl = <fs_bseg>-bschl.
*      <fs_buztab>-bstat = .
*      <fs_buztab>-mwart = .
*      <fs_buztab>-mwskz = .
*      <fs_buztab>-flaen = .

      CALL FUNCTION 'FI_ITEMS_MASS_CHANGE'
        EXPORTING
          s_bseg     = gwa_bseg
        IMPORTING
          errtab     = ltd_errtab[]
        TABLES
          it_buztab  = ltd_buztab
          it_fldtab  = ltd_fldtab
        EXCEPTIONS
          bdc_errors = 1
          OTHERS     = 2.

      IF sy-subrc EQ 0.

        COMMIT WORK AND WAIT.

        IF <fs_data>-wait IS NOT INITIAL.
          WAIT UP TO 2 SECONDS.
        ENDIF.

        <fs_data>-message = 'Actualización exitosa.'.

      ELSE.

        COMMIT WORK AND WAIT.

        IF <fs_data>-wait IS NOT INITIAL.
          WAIT UP TO 2 SECONDS.
        ENDIF.

        IF ltd_errtab[] IS NOT INITIAL.

          CLEAR: lwa_errtab.

          READ TABLE ltd_errtab INTO lwa_errtab INDEX 1.
          IF sy-subrc EQ 0.

            ls_mtype = lwa_errtab-err-msgtyp.
            ls_mid   = lwa_errtab-err-msgid.
            ls_mno   = lwa_errtab-err-msgnr.

            CALL FUNCTION 'CUTC_GET_MESSAGE'
              EXPORTING
                msg_type       = ls_mtype
                msg_id         = ls_mid
                msg_no         = ls_mno
*               msg_arg1       = ls_msg1
*               msg_arg2       = ls_msg2
*               msg_arg3       = ls_msg3
*               msg_arg4       = ls_msg4
                language       = sy-langu
              IMPORTING
                raw_message    = ls_errtext
              EXCEPTIONS
                msg_not_found  = 1
                internal_error = 2
                OTHERS         = 3.
            IF sy-subrc EQ 0.
              <fs_data>-message = ls_errtext.
            ENDIF.

          ENDIF.

        ELSE.

          <fs_data>-message = 'Error al invocar función.'.

        ENDIF.

      ENDIF.

    ENDIF.

  ENDLOOP.

ENDFORM.


FORM build_layout_grid.

  MOVE 'X' TO gwa_layout-zebra.

ENDFORM.                    " BUILD_LAYOUT


*&---------------------------------------------------------------------*
*&      Form  add_fieldcat
*&---------------------------------------------------------------------*
FORM add_fieldcat_grid TABLES gtd_fieldcat STRUCTURE gwa_fieldcat
                       USING  p_tabname
                              p_fieldname
                              p_seltext_l
                              p_seltext_m
                              p_seltext_s
                              p_outputlen.

  FIELD-SYMBOLS <lwa_fieldcat> LIKE LINE OF gtd_fieldcat.

  APPEND INITIAL LINE TO gtd_fieldcat ASSIGNING <lwa_fieldcat>.
  <lwa_fieldcat>-tabname   = p_tabname.
  <lwa_fieldcat>-fieldname = p_fieldname.
  <lwa_fieldcat>-seltext_l = p_seltext_l.
  <lwa_fieldcat>-seltext_m = p_seltext_m.
  <lwa_fieldcat>-seltext_s = p_seltext_s.
  <lwa_fieldcat>-outputlen = p_outputlen.

ENDFORM.                    " ADD_FIELDCAT

*&---------------------------------------------------------------------*
*&      Form  PROCESS_ALV
*&---------------------------------------------------------------------*
FORM display_alv .

  FIELD-SYMBOLS: <fs_data> LIKE LINE OF gtd_data.

  CLEAR: gtd_fieldcat[].

  PERFORM build_layout_grid.
  PERFORM add_fieldcat_grid:
    TABLES gtd_fieldcat USING 'GTD_DATA' 'BUKRS'   'Sociedad'            'Sociedad'         'Sociedad'   '10',
    TABLES gtd_fieldcat USING 'GTD_DATA' 'BELNR'   'Documento Contable'  'Documento.Cont.'  'Doc.Cont.'  '15',
    TABLES gtd_fieldcat USING 'GTD_DATA' 'GJAHR'   'Ejercicio'           'Ejercicio'        'Ejercicio'  '10',
    TABLES gtd_fieldcat USING 'GTD_DATA' 'BUZEI'   'Posición'            'Posición'         'Posición'   '10',
    TABLES gtd_fieldcat USING 'GTD_DATA' 'ZUONR'   'Asignación'          'Asignación'       'Asignación' '20',
    TABLES gtd_fieldcat USING 'GTD_DATA' 'MESSAGE' 'Mensaje'             'Mensaje'          'Mensaje'    '40'.

* Funci�n para mostrar el ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      it_fieldcat        = gtd_fieldcat[]
      i_grid_title       = 'Resultados'
      i_callback_program = sy-repid
      is_layout          = gwa_layout
    TABLES
      t_outtab           = gtd_data[]
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.
*
ENDFORM.