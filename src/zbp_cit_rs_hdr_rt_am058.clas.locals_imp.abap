*CLASS lcl_buffer DEFINITION.
*  PUBLIC SECTION.
*    CLASS-DATA: mt_header_create TYPE STANDARD TABLE OF zcitrs_hdr_am058,
*                mt_header_update TYPE STANDARD TABLE OF zcitrs_hdr_am058,
*                mt_header_delete TYPE STANDARD TABLE OF zcitrs_hdr_am058,
*                mt_item_create   TYPE STANDARD TABLE OF zcitrs_ITM_am058,
*                mt_item_update   TYPE STANDARD TABLE OF zcitrs_ITM_am058,
*                mt_item_delete   TYPE STANDARD TABLE OF zcitrs_ITM_am058.
*ENDCLASS.
*
*CLASS lhc_Header DEFINITION INHERITING FROM cl_abap_behavior_handler.
*  PRIVATE SECTION.
*    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
*      IMPORTING keys REQUEST requested_authorizations FOR Header RESULT result.
*
*    METHODS markAsPaid FOR MODIFY
*      IMPORTING keys FOR ACTION Header~markAsPaid
*      RESULT result.
*
*
*    METHODS create FOR MODIFY IMPORTING entities FOR CREATE Header.
*    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE Header.
*    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE Header.
*    METHODS read   FOR READ   IMPORTING keys FOR READ Header RESULT result.
*    METHODS lock   FOR LOCK   IMPORTING keys FOR LOCK Header.
*
*    METHODS rba_Items FOR READ
*      IMPORTING keys_rba FOR READ Header\_Items
*      FULL result_requested RESULT result LINK association_links.
*
*    METHODS cba_Items FOR MODIFY
*      IMPORTING entities_cba FOR CREATE Header\_Items.
*ENDCLASS.
*
*CLASS lhc_Header IMPLEMENTATION.
*
*  METHOD get_instance_authorizations.
*  ENDMETHOD.
*
*  METHOD markAsPaid.
*
*    LOOP AT keys INTO DATA(ls_key).
*
*      SELECT SINGLE *
*        FROM zcitrs_hdr_am058
*        WHERE bill_uuid = @ls_key-bill_uuid
*        INTO @DATA(ls_header).
*
*      IF sy-subrc = 0 AND ls_header-payment_status = 'Draft'.
*
*        ls_header-payment_status = 'Paid'.
*
*        APPEND ls_header TO lcl_buffer=>mt_header_update.
*
*        APPEND VALUE #( bill_uuid = ls_header-bill_uuid )
*          TO result.
*
*      ENDIF.
*
*    ENDLOOP.
*
*  ENDMETHOD.
*
*
*  METHOD create.
*
*    LOOP AT entities INTO DATA(ls_entity).
*
*      DATA(ls_header) =
*        CORRESPONDING zcitrs_hdr_am058( ls_entity MAPPING FROM ENTITY ).
*
*      TRY.
*          IF ls_header-bill_uuid IS INITIAL.
*            ls_header-bill_uuid = cl_system_uuid=>create_uuid_x16_static( ).
*          ENDIF.
*        CATCH cx_uuid_error.
*          CONTINUE.
*      ENDTRY.
*
*      ls_header-payment_status = 'Draft'.
*
*      APPEND ls_header TO lcl_buffer=>mt_header_create.
*
*      INSERT VALUE #(
*        %cid      = ls_entity-%cid
*        bill_uuid = ls_header-bill_uuid
*      ) INTO TABLE mapped-header.
*
*    ENDLOOP.
*
*  ENDMETHOD.
*
*  METHOD update.
*
*    LOOP AT entities INTO DATA(ls_entity).
*
*      SELECT SINGLE *
*        FROM zcitrs_hdr_am058
*        WHERE bill_uuid = @ls_entity-bill_uuid
*        INTO @DATA(ls_header).
*
*      IF sy-subrc = 0.
*
*        IF ls_entity-%control-customer_name = if_abap_behv=>mk-on.
*          ls_header-customer_name = ls_entity-customer_name.
*        ENDIF.
*
*        IF ls_entity-%control-billing_date = if_abap_behv=>mk-on.
*          ls_header-billing_date = ls_entity-billing_date.
*        ENDIF.
*
*        IF ls_entity-%control-payment_status = if_abap_behv=>mk-on.
*          ls_header-payment_status = ls_entity-payment_status.
*        ENDIF.
*
*        APPEND ls_header TO lcl_buffer=>mt_header_update.
*
*      ENDIF.
*
*    ENDLOOP.
*
*  ENDMETHOD.
*
*  METHOD delete.
*
*    LOOP AT keys INTO DATA(ls_key).
*      APPEND VALUE #( bill_uuid = ls_key-bill_uuid )
*        TO lcl_buffer=>mt_header_delete.
*    ENDLOOP.
*
*  ENDMETHOD.
*
*  METHOD read.
*
*    IF keys IS NOT INITIAL.
*
*      SELECT *
*        FROM zcitrs_hdr_am058
*        FOR ALL ENTRIES IN @keys
*        WHERE bill_uuid = @keys-bill_uuid
*        INTO TABLE @DATA(lt_headers).
*
*      result = CORRESPONDING #( lt_headers MAPPING TO ENTITY ).
*
*    ENDIF.
*
*  ENDMETHOD.
*
*  METHOD lock.
*  ENDMETHOD.
*
*  METHOD cba_Items.
*
*    LOOP AT entities_cba INTO DATA(ls_cba).
*
*      LOOP AT ls_cba-%target INTO DATA(ls_target).
*
*        DATA(ls_item) =
*          CORRESPONDING zcitrs_ITM_am058(
*            ls_target MAPPING FROM ENTITY ).
*
*        ls_item-bill_uuid = ls_cba-bill_uuid.
*
*        TRY.
*            ls_item-item_uuid =
*              cl_system_uuid=>create_uuid_x16_static( ).
*          CATCH cx_uuid_error.
*        ENDTRY.
*
*        ls_item-subtotal =
*          ls_item-quantity * ls_item-unit_price.
*
*        APPEND ls_item TO lcl_buffer=>mt_item_create.
*
*        INSERT VALUE #(
*          %cid      = ls_target-%cid
*          item_uuid = ls_item-item_uuid
*        ) INTO TABLE mapped-item.
*
*      ENDLOOP.
*
*    ENDLOOP.
*
*  ENDMETHOD.
*
*  METHOD rba_Items.
*
*    IF keys_rba IS NOT INITIAL.
*
*      SELECT *
*        FROM zcitrs_ITM_am058
*        FOR ALL ENTRIES IN @keys_rba
*        WHERE bill_uuid = @keys_rba-bill_uuid
*        INTO TABLE @DATA(lt_items).
*
*      LOOP AT lt_items INTO DATA(ls_itm).
*
*        INSERT VALUE #(
*          source-bill_uuid = ls_itm-bill_uuid
*          target-item_uuid = ls_itm-item_uuid
*        ) INTO TABLE association_links.
*
*        IF result_requested = if_abap_behv=>mk-on.
*          APPEND CORRESPONDING #( ls_itm MAPPING TO ENTITY )
*            TO result.
*        ENDIF.
*
*      ENDLOOP.
*
*    ENDIF.
*
*  ENDMETHOD.
*
*ENDCLASS.





*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type declarations

CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    " Using the correct table types from your provided dictionary definitions
    CLASS-DATA: mt_header_create TYPE STANDARD TABLE OF ZCITRS_HDR_AM058,
                mt_header_update TYPE STANDARD TABLE OF ZCITRS_HDR_AM058,
                mt_header_delete TYPE STANDARD TABLE OF ZCITRS_HDR_AM058,
                mt_item_create   TYPE STANDARD TABLE OF ZCITRS_ITM_AM058,
                mt_item_update   TYPE STANDARD TABLE OF ZCITRS_ITM_AM058,
                mt_item_delete   TYPE STANDARD TABLE OF ZCITRS_ITM_AM058.
ENDCLASS.

CLASS lhc_Header DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Header RESULT result.
      METHODS markAsPaid FOR MODIFY
  IMPORTING keys FOR ACTION Header~markAsPaid
  RESULT result.
*  METHODS generatePDF
*  FOR MODIFY
*  IMPORTING keys FOR ACTION Header~generatePDF
*  RESULT result.
*    METHODS calculateTotal
*      FOR DETERMINE ON MODIFY
*      IMPORTING keys FOR Header.
*  METHODS generatePDF
*  FOR MODIFY
*  IMPORTING keys FOR ACTION Header~generatePDF
*  RESULT result.
    METHODS create FOR MODIFY IMPORTING entities FOR CREATE Header.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE Header.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE Header.
    METHODS read   FOR READ   IMPORTING keys FOR READ Header RESULT result.
    METHODS lock   FOR LOCK   IMPORTING keys FOR LOCK Header.
    METHODS rba_Items FOR READ IMPORTING keys_rba FOR READ Header\_Items FULL result_requested RESULT result LINK association_links.
    METHODS cba_Items FOR MODIFY IMPORTING entities_cba FOR CREATE Header\_Items.
ENDCLASS.

CLASS lhc_Header IMPLEMENTATION.
  METHOD get_instance_authorizations.
  ENDMETHOD.

*  METHOD create.
*    LOOP AT entities INTO DATA(ls_entity).
*      DATA(ls_header) = CORRESPONDING zcit_hdr_010( ls_entity MAPPING FROM ENTITY ).
*
*      TRY.
*          IF ls_header-bill_uuid IS INITIAL.
*            ls_header-bill_uuid = cl_system_uuid=>create_uuid_x16_static( ).
*          ENDIF.
*        CATCH cx_uuid_error.
*          CONTINUE.
*      ENDTRY.
*
*      ls_header-payment_status = 'Draft'.
*      APPEND ls_header TO lcl_buffer=>mt_header_create.
*
*      " Map back using the exact names from your BDEF mapping section
*      INSERT VALUE #( %cid = ls_entity-%cid
*                      bill_uuid = ls_header-bill_uuid ) INTO TABLE mapped-header.
*    ENDLOOP.
*  ENDMETHOD.

METHOD markAsPaid.

  LOOP AT keys INTO DATA(ls_key).

    SELECT SINGLE *
      FROM ZCITRS_HDR_AM058
      WHERE bill_uuid = @ls_key-bill_uuid
      INTO @DATA(ls_header).

    IF sy-subrc = 0 AND ls_header-payment_status = 'Draft'.

      ls_header-payment_status = 'Paid'.

      APPEND ls_header TO lcl_buffer=>mt_header_update.

      APPEND VALUE #( bill_uuid = ls_header-bill_uuid )
        TO result.

    ENDIF.

  ENDLOOP.

ENDMETHOD.

*METHOD generatePDF.
*
*  DATA lv_text    TYPE string.
*  DATA lv_xstring TYPE xstring.
*
*  READ ENTITIES OF ZCIT_I_HDR_010 IN LOCAL MODE
*    ENTITY Header
*    ALL FIELDS
*    WITH CORRESPONDING #( keys )
*    RESULT DATA(lt_header).
*
*  LOOP AT lt_header INTO DATA(ls_header).
*
*    lv_text =
*        |Bill Number: { ls_header-bill_number }| && cl_abap_char_utilities=>newline &&
*        |Customer: { ls_header-customer_name }| && cl_abap_char_utilities=>newline &&
*        |Total: { ls_header-total_amount } { ls_header-currency }|.
*
*    " ✅ Cloud-safe conversion
*    lv_xstring = cl_web_http_utility=>encode_utf8( lv_text ).
*
*    APPEND VALUE #(
*      %tky = ls_header-%tky
*      %param = VALUE ZCIT_PDF_RESULT(
*                  fileName = |Bill_{ ls_header-bill_number }.pdf|
*                  mimeType = 'application/pdf'
*                  value    = lv_xstring
*               )
*    ) TO result.
*
*  ENDLOOP.
*
*ENDMETHOD.


*METHOD generatePDF.
*
*  DATA lv_text TYPE string.
*
*  READ ENTITIES OF ZCIT_I_HDR_010 IN LOCAL MODE
*    ENTITY Header
*    ALL FIELDS
*    WITH CORRESPONDING #( keys )
*    RESULT DATA(lt_header).
*
*  LOOP AT lt_header INTO DATA(ls_header).
*
*    lv_text =
*        |Bill Number: { ls_header-bill_number }\n|
*     && |Customer: { ls_header-customer_name }\n|
*     && |Total: { ls_header-total_amount } { ls_header-currency }\n|.
*
*    APPEND VALUE #(
*      %tky = ls_header-%tky
*      %param = VALUE ZCIT_PDF_RESULT(
*                  fileName = |Bill_{ ls_header-bill_number }.pdf|
*                  mimeType = 'application/pdf'
*                  value    = lv_text
*               )
*    ) TO result.
*
*  ENDLOOP.
*
*ENDMETHOD.
*METHOD generatePDF.
*
*  LOOP AT keys INTO DATA(ls_key).
*
*    " Here you would generate PDF
*
*    APPEND VALUE #( bill_uuid = ls_key-bill_uuid )
*      TO result.
*
*  ENDLOOP.
*
*ENDMETHOD.

*METHOD calculateTotal.
*
*  LOOP AT keys INTO DATA(ls_key).
*
*    SELECT SUM( subtotal )
*      FROM zcit_itm_010
*      WHERE bill_uuid = @ls_key-bill_uuid
*      INTO @DATA(lv_total).
*
*    SELECT SINGLE *
*      FROM zcit_hdr_010
*      WHERE bill_uuid = @ls_key-bill_uuid
*      INTO @DATA(ls_header).
*
*    IF sy-subrc = 0.
*      ls_header-total_amount = lv_total.
*      APPEND ls_header TO lcl_buffer=>mt_header_update.
*    ENDIF.
*
*  ENDLOOP.
*
*ENDMETHOD.

  METHOD create.
    LOOP AT entities INTO DATA(ls_entity).
      DATA(ls_header) = CORRESPONDING ZCITRS_HDR_AM058( ls_entity MAPPING FROM ENTITY ).

      TRY.
          IF ls_header-bill_uuid IS INITIAL.
            ls_header-bill_uuid = cl_system_uuid=>create_uuid_x16_static( ).
          ENDIF.
        CATCH cx_uuid_error.
          CONTINUE.
      ENDTRY.

      ls_header-payment_status = 'Draft'.
      APPEND ls_header TO lcl_buffer=>mt_header_create.

      " Map back using the exact names from your BDEF mapping section
      INSERT VALUE #( %cid = ls_entity-%cid
                      bill_uuid = ls_header-bill_uuid ) INTO TABLE mapped-header.
    ENDLOOP.
  ENDMETHOD.

*METHOD create.
*    LOOP AT entities INTO DATA(ls_entity).
*      " 1. Map the incoming UI entity to your database structure
*      DATA(ls_header) = CORRESPONDING zcit_hdr_010( ls_entity MAPPING FROM ENTITY ).
*
*      " 2. UUID Generation
*      IF ls_header-bill_uuid IS INITIAL.
*        TRY.
*            ls_header-bill_uuid = cl_system_uuid=>create_uuid_x16_static( ).
*          CATCH cx_uuid_error.
*            CONTINUE.
*        ENDTRY.
*      ENDIF.
*
*      " 3. THE FIX: Only set 'Draft' if the user provided NOTHING
*      " This allows whatever you type in the UI to be preserved.
*      IF ls_header-payment_status IS INITIAL.
*        ls_header-payment_status = 'Draft'.
*      ENDIF.
*
*      " 4. Add to the local buffer
*      APPEND ls_header TO lcl_buffer=>mt_header_create.
*
*      " 5. Map back to the framework
*      INSERT VALUE #( %cid = ls_entity-%cid
*                      bill_uuid = ls_header-bill_uuid ) INTO TABLE mapped-header.
*    ENDLOOP.
*ENDMETHOD.

*  METHOD update.
*    LOOP AT entities INTO DATA(ls_entity).
*      " In Strict 2 Unmanaged, we fetch existing data to merge
*      SELECT SINGLE * FROM zcit_hdr_010 WHERE bill_uuid = @ls_entity-bill_uuid INTO @DATA(ls_header).
*
*      IF sy-subrc = 0.
*        IF ls_entity-%control-customer_name = if_abap_behv=>mk-on. ls_header-customer_name = ls_entity-customer_name. ENDIF.
*        IF ls_entity-%control-billing_date  = if_abap_behv=>mk-on. ls_header-billing_date  = ls_entity-billing_date.  ENDIF.
*        IF ls_entity-%control-total_amount  = if_abap_behv=>mk-on. ls_header-total_amount  = ls_entity-total_amount.  ENDIF.
*        IF ls_entity-%control-currency      = if_abap_behv=>mk-on. ls_header-currency      = ls_entity-currency.      ENDIF.
*
*        APPEND ls_header TO lcl_buffer=>mt_header_update.
*      ENDIF.
*    ENDLOOP.
*  ENDMETHOD.

*METHOD update.
*    LOOP AT entities INTO DATA(ls_entity).
*      " Fetch existing record from DB to merge changes
*      SELECT SINGLE * FROM zcit_hdr_010 WHERE bill_uuid = @ls_entity-bill_uuid INTO @DATA(ls_header).
*
*      IF sy-subrc = 0.
*        " Existing fields...
*        IF ls_entity-%control-customer_name  = if_abap_behv=>mk-on. ls_header-customer_name  = ls_entity-customer_name.  ENDIF.
*        IF ls_entity-%control-billing_date   = if_abap_behv=>mk-on. ls_header-billing_date   = ls_entity-billing_date.   ENDIF.
*        IF ls_entity-%control-total_amount   = if_abap_behv=>mk-on. ls_header-total_amount   = ls_entity-total_amount.   ENDIF.
*
*        " ADD THIS LINE: Explicitly check and move Payment Status
*        IF ls_entity-%control-payment_status = if_abap_behv=>mk-on. ls_header-payment_status = ls_entity-payment_status. ENDIF.
*
*        APPEND ls_header TO lcl_buffer=>mt_header_update.
*      ENDIF.
*    ENDloop.
*  ENDMETHOD.

METHOD update.
    LOOP AT entities INTO DATA(ls_entity).
      " 1. Get the current record from the DB
      SELECT SINGLE * FROM ZCITRS_HDR_AM058 WHERE bill_uuid = @ls_entity-bill_uuid INTO @DATA(ls_header).

      IF sy-subrc = 0.
        " 2. Update fields ONLY if the UI sent a change (%control)
        IF ls_entity-%control-customer_name  = if_abap_behv=>mk-on. ls_header-customer_name  = ls_entity-customer_name.  ENDIF.
        IF ls_entity-%control-billing_date   = if_abap_behv=>mk-on. ls_header-billing_date   = ls_entity-billing_date.   ENDIF.

        " CRITICAL: Ensure payment_status is handled here
        IF ls_entity-%control-payment_status = if_abap_behv=>mk-on.
          ls_header-payment_status = ls_entity-payment_status.
        ENDIF.

        APPEND ls_header TO lcl_buffer=>mt_header_update.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #( bill_uuid = ls_key-bill_uuid ) TO lcl_buffer=>mt_header_delete.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    " Fetching data for UI display
    IF keys IS NOT INITIAL.
      SELECT * FROM ZCITRS_HDR_AM058 FOR ALL ENTRIES IN @keys
        WHERE bill_uuid = @keys-bill_uuid INTO TABLE @DATA(lt_headers).
      result = CORRESPONDING #( lt_headers MAPPING TO ENTITY ).
    ENDIF.
  ENDMETHOD.

  METHOD lock.
    " For Strict 2, the framework handles draft locking via the 'lock master' BDEF syntax
  ENDMETHOD.

  METHOD cba_Items.
    LOOP AT entities_cba INTO DATA(ls_cba).
      LOOP AT ls_cba-%target INTO DATA(ls_target).
        DATA(ls_item) = CORRESPONDING ZCITRS_ITM_AM058( ls_target MAPPING FROM ENTITY ).

        ls_item-bill_uuid = ls_cba-bill_uuid.
        TRY.
            ls_item-item_uuid = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.

        " Automatic Calculation
        ls_item-subtotal = ls_item-quantity * ls_item-unit_price.

        APPEND ls_item TO lcl_buffer=>mt_item_create.
        INSERT VALUE #( %cid = ls_target-%cid
                        item_uuid = ls_item-item_uuid ) INTO TABLE mapped-item.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD rba_Items.
    " Read-by-Association logic
    IF keys_rba IS NOT INITIAL.
      SELECT * FROM ZCITRS_ITM_AM058 FOR ALL ENTRIES IN @keys_rba
        WHERE bill_uuid = @keys_rba-bill_uuid INTO TABLE @DATA(lt_items).

      LOOP AT lt_items INTO DATA(ls_itm).
        INSERT VALUE #( source-bill_uuid = ls_itm-bill_uuid
                        target-item_uuid = ls_itm-item_uuid ) INTO TABLE association_links.
        IF result_requested = if_abap_behv=>mk-on.
          APPEND CORRESPONDING #( ls_itm MAPPING TO ENTITY ) TO result.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_Item DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.


    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE Item.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE Item.
    METHODS read   FOR READ   IMPORTING keys FOR READ Item RESULT result.
    METHODS rba_Header FOR READ IMPORTING keys_rba FOR READ Item\_Header FULL result_requested RESULT result LINK association_links.

*METHODS calculateSubtotal
*  FOR DETERMINE ON MODIFY
*  IMPORTING keys FOR Item.
*  METHODS checkQuantity FOR VALIDATION Item~checkQuantity
*  IMPORTING keys.

ENDCLASS.

CLASS lhc_Item IMPLEMENTATION.

  METHOD update.
    LOOP AT entities INTO DATA(ls_entity).
      SELECT SINGLE * FROM ZCITRS_ITM_AM058 WHERE item_uuid = @ls_entity-item_uuid INTO @DATA(ls_item).
      IF sy-subrc = 0.
        IF ls_entity-%control-quantity   = if_abap_behv=>mk-on. ls_item-quantity   = ls_entity-quantity.   ENDIF.
        IF ls_entity-%control-unit_price = if_abap_behv=>mk-on. ls_item-unit_price = ls_entity-unit_price. ENDIF.

        ls_item-subtotal = ls_item-quantity * ls_item-unit_price.
        APPEND ls_item TO lcl_buffer=>mt_item_update.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #( item_uuid = ls_key-item_uuid ) TO lcl_buffer=>mt_item_delete.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    IF keys IS NOT INITIAL.
      SELECT * FROM ZCITRS_ITM_AM058 FOR ALL ENTRIES IN @keys
        WHERE item_uuid = @keys-item_uuid INTO TABLE @DATA(lt_items).
      result = CORRESPONDING #( lt_items MAPPING TO ENTITY ).
    ENDIF.
  ENDMETHOD.

  METHOD rba_Header.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_saver DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize REDEFINITION.
    METHODS check_before_save REDEFINITION.
    METHODS adjust_numbers REDEFINITION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
ENDCLASS.

CLASS lsc_saver IMPLEMENTATION.
  METHOD finalize. ENDMETHOD.
  METHOD check_before_save. ENDMETHOD.

*  METHOD adjust_numbers.
*    " Requirement: Late Numbering logic
*    LOOP AT lcl_buffer=>mt_header_create REFERENCE INTO DATA(lr_hdr) WHERE bill_number IS INITIAL.
*       lr_hdr->bill_number = |INV-{ cl_abap_random_int=>create( min = 1000 max = 9999 )->get_next( ) }|.
*    ENDLOOP.
*  ENDMETHOD.

*METHOD adjust_numbers.
*
*  DATA(lo_random) = cl_abap_random_int=>create(
*                      min = 1000
*                      max = 9999 ).
*
*  LOOP AT lcl_buffer=>mt_header_create REFERENCE INTO DATA(lr_hdr)
*       WHERE bill_number IS INITIAL.
*
*    lr_hdr->bill_number = |INV-{ lo_random->get_next( ) }|.
*
*  ENDLOOP.
*
*ENDMETHOD.

METHOD adjust_numbers.

  DATA lv_max_num TYPE i VALUE 0.

  " Read existing numbers
  SELECT bill_number
    FROM ZCITRS_HDR_AM058
    WHERE bill_number IS NOT INITIAL
    INTO TABLE @DATA(lt_numbers).

  LOOP AT lt_numbers INTO DATA(lv_bill).

    " Extract numeric part after INV-
    DATA(lv_numeric_part) = lv_bill+4.

    IF lv_numeric_part IS NOT INITIAL.
      TRY.
          DATA(lv_current) = CONV i( lv_numeric_part ).
          IF lv_current > lv_max_num.
            lv_max_num = lv_current.
          ENDIF.
        CATCH cx_sy_conversion_no_number.
          CONTINUE.
      ENDTRY.
    ENDIF.

  ENDLOOP.

  " Assign new numbers
  LOOP AT lcl_buffer=>mt_header_create REFERENCE INTO DATA(lr_hdr)
       WHERE bill_number IS INITIAL.

    lv_max_num += 1.
    lr_hdr->bill_number = |INV-{ lv_max_num }|.

  ENDLOOP.

ENDMETHOD.


  METHOD save.
    " Handle Header Changes
    IF lcl_buffer=>mt_header_create IS NOT INITIAL.
      INSERT ZCITRS_HDR_AM058 FROM TABLE @lcl_buffer=>mt_header_create.
    ENDIF.
    IF lcl_buffer=>mt_header_update IS NOT INITIAL.
      MODIFY ZCITRS_HDR_AM058 FROM TABLE @lcl_buffer=>mt_header_update.
    ENDIF.
    IF lcl_buffer=>mt_header_delete IS NOT INITIAL.
      DELETE ZCITRS_HDR_AM058 FROM TABLE @lcl_buffer=>mt_header_delete.
    ENDIF.

    " Handle Item Changes
    IF lcl_buffer=>mt_item_create IS NOT INITIAL.
      INSERT ZCITRS_ITM_AM058 FROM TABLE @lcl_buffer=>mt_item_create.
    ENDIF.
    IF lcl_buffer=>mt_item_update IS NOT INITIAL.
      MODIFY ZCITRS_ITM_AM058 FROM TABLE @lcl_buffer=>mt_item_update.
    ENDIF.
    IF lcl_buffer=>mt_item_delete IS NOT INITIAL.
      DELETE ZCITRS_ITM_AM058 FROM TABLE @lcl_buffer=>mt_item_delete.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup.
    CLEAR: lcl_buffer=>mt_header_create, lcl_buffer=>mt_header_update, lcl_buffer=>mt_header_delete,
           lcl_buffer=>mt_item_create,   lcl_buffer=>mt_item_update,   lcl_buffer=>mt_item_delete.
  ENDMETHOD.
ENDCLASS.
