@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Bill Header Projection'
@Metadata.allowExtensions: true
define root view entity ZCIT_RS_HDR_CV_AM058
provider contract transactional_query
as projection on ZCIT_RS_HDR_rt_AM058
{
key bill_uuid,
bill_number,
customer_name,
billing_date,
@Semantics.amount.currencyCode: 'currency'
total_amount,
currency,
payment_status,
/* Temporarily comment out the next line */
_Items : redirected to composition child ZCIT_RS_ITM_CV_AM058
//_Items // Just expose the association for now
}
