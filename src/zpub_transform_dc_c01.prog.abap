*&---------------------------------------------------------------------*
*& Include          ZPUB_TRANSFORM_DC_C01
*&---------------------------------------------------------------------*
CLASS lcl_demo DEFINITION FINAL.
  PUBLIC SECTION.
    CONSTANTS: mc_filename TYPE string VALUE 'C:\Temp\Resultxml.doc'.

    TYPES: ty_t_data    TYPE STANDARD TABLE OF tbl1024,  " данные для выгрузки в файл
           ty_s_context TYPE zpub_s_context_doc.         " Структура для контекста


    CLASS-METHODS:
      main.

  PRIVATE SECTION.

    CLASS-METHODS:
      get_context EXPORTING es_context TYPE ty_s_context.

ENDCLASS.

CLASS lcl_demo IMPLEMENTATION.
  METHOD get_context.
    CLEAR es_context.

    APPEND INITIAL LINE TO es_context-t_invoice ASSIGNING FIELD-SYMBOL(<ls_invoice>).
    <ls_invoice>-name = 'Картошка'(n01).
    APPEND INITIAL LINE TO es_context-t_invoice ASSIGNING <ls_invoice>.
    <ls_invoice>-name = 'Морковь'(n02).

    es_context-seller = |{ 'ООО "Тестовая организация"'(s01) }{ cl_abap_char_utilities=>cr_lf }{ 'ОАО "Организация2"'(s02) }|.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN es_context-seller WITH '<w:br/>'.

  ENDMETHOD.
  METHOD main.

    DATA: lt_data   TYPE ty_t_data,
          lv_length TYPE i,
          lv_xml    TYPE xstring.          "Результат трансформации

* Заполняем контекст
    get_context( IMPORTING es_context = DATA(ls_context) ).

* Запуск трансформации
    CALL TRANSFORMATION zpub_transform_doc
      SOURCE is_context = ls_context
      RESULT XML lv_xml.
    IF sy-subrc <> 0.
      MESSAGE 'Fail transform'(e01) TYPE 'E'.
    ENDIF.

* Пример работы с переносом строк
    DATA: _repl   TYPE string VALUE '<w:br/>',
          _repl2  TYPE string VALUE '~',
          _xrepl  TYPE xstring,
          _xrepl2 TYPE xstring.

    CALL FUNCTION 'SSFH_STRING_TO_XSTRINGUTF8'
      EXPORTING
        cstr_input_data  = _repl
        codepage         = '4110'
      IMPORTING
        ostr_input_data  = _xrepl
      EXCEPTIONS
        conversion_error = 1
        internal_error   = 2
        OTHERS           = 3.
    IF sy-subrc <> 0.
      MESSAGE 'Fail convert'(e02) TYPE 'E'.
    ENDIF.

    CALL FUNCTION 'SSFH_STRING_TO_XSTRINGUTF8'
      EXPORTING
        cstr_input_data  = _repl2
        codepage         = '4110'
      IMPORTING
        ostr_input_data  = _xrepl2
      EXCEPTIONS
        conversion_error = 1
        internal_error   = 2
        OTHERS           = 3.
    IF sy-subrc <> 0.
      MESSAGE 'Fail convert'(e02) TYPE 'E'.
    ENDIF.

    REPLACE ALL OCCURRENCES OF _xrepl IN lv_xml WITH _xrepl2 IN BYTE MODE.

* Для выгрузки в DOC конвертируем в бинарный код
    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer        = lv_xml
      IMPORTING
        output_length = lv_length
      TABLES
        binary_tab    = lt_data.

    IF lt_data[] IS INITIAL.
      MESSAGE 'Fail saving'(e03) TYPE 'E'.
    ENDIF.

* Сохраняем файл
    cl_gui_frontend_services=>gui_download(
      EXPORTING
        bin_filesize  = lv_length
        filetype = 'BIN'
        filename = mc_filename "Путь указан текстом для предельной наглядности
      CHANGING
        data_tab = lt_data
      EXCEPTIONS OTHERS = 1 ).
    IF sy-subrc <> 0.
      MESSAGE 'Fail saving'(e03) TYPE 'E'.
    ENDIF.

    MESSAGE 'File was exported successfully'(i01) TYPE 'I'.

  ENDMETHOD.
ENDCLASS.
