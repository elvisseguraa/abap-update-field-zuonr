*&---------------------------------------------------------------------*
*& Include          ZES_PROGRAM_TOP
*&---------------------------------------------------------------------*

TYPES:
  BEGIN OF gty_report,
    bukrs   TYPE bseg-bukrs,
    belnr   TYPE bseg-belnr,
    gjahr   TYPE bseg-gjahr,
    buzei   TYPE bseg-buzei,
    zuonr   TYPE bseg-zuonr,
    wait    TYPE c,
    message TYPE c LENGTH 100,
  END OF gty_report.

DATA: gtd_data  TYPE STANDARD TABLE OF gty_report,
      gtd_excel TYPE STANDARD TABLE OF alsmex_tabline,
      gtd_bseg  TYPE STANDARD TABLE OF bseg,
      gwa_excel LIKE LINE OF gtd_excel,
      gwa_data  TYPE gty_report,
      gwa_bseg  TYPE bseg,
      gs_file   TYPE localfile.

DATA: gtd_fieldcat TYPE slis_t_fieldcat_alv,
      gwa_fieldcat TYPE slis_fieldcat_alv,
      gwa_layout   TYPE slis_layout_alv.

FIELD-SYMBOLS: <fs_data> TYPE gty_report,
               <fs_bseg> TYPE bseg.