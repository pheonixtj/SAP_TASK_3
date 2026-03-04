@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Bill Header Interface'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZCIT_RS_HDR_RT_AM058
as select from ZCITRS_HDR_AM058
composition [0..*] of ZCIT_RS_ITM_RT_AM058 as _Items
{
key bill_uuid,
bill_number,
customer_name,
billing_date,
@Semantics.amount.currencyCode: 'currency'
total_amount,
currency,
payment_status,
_Items
}
