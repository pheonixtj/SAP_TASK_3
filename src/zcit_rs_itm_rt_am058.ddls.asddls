@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Bill Item Interface'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCIT_RS_ITM_RT_AM058 as select from ZCITRS_ITM_AM058
association to parent ZCIT_RS_HDR_RT_AM058 as _Header on $projection.bill_uuid = _Header.bill_uuid
{
key item_uuid,
bill_uuid,
item_position,
product_id,
product_name,
@Semantics.quantity.unitOfMeasure: 'quantityunits'
quantity,
quantityunits,
@Semantics.amount.currencyCode: 'currency'
unit_price,
@Semantics.amount.currencyCode: 'currency'
subtotal,
currency,
_Header
}
