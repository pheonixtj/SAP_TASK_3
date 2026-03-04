@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Bill Item Projection'
@Metadata.allowExtensions: true
define view entity ZCIT_RS_ITM_CV_AM058 as projection on ZCIT_RS_ITM_RT_AM058
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
/* Temporarily comment out the next line */
_Header : redirected to parent ZCIT_RS_HDR_CV_AM058
//_Header // Just expose the association for now
}
