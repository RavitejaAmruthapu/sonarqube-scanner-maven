#define ST_PROC 1
#include "AC_Accounting.h"

DROP PUBLIC SYNONYM SP_AC_AccAmort_u ;

CREATE OR REPLACE PROCEDURE
	SP_AC_AccAmort_u (
							p_dat_ProcessDate IN		amortization.last_amort_date%TYPE,
							p_cod_CountryCode IN  	amortization.country_code%TYPE,
							p_cod_LegVeh	   IN  	amortization.leg_veh%TYPE,
							p_cod_BoffCode	   IN  	amortization.boff_code%TYPE,
							p_cod_MisCode	   IN  	amortization.mis_code%TYPE,
							p_ref_RefNum	   IN  	amortization.ref_num%TYPE,
							p_seq_SeqNum	   IN  	amortization.seq_num%TYPE,
							p_cod_ChargeType  IN  	amortization.charge_type%TYPE,
							p_cod_SerialNum	IN  	amortization.serial_num%TYPE
							)

AS
str_ErrorMsg1					VARCHAR2 (SYS_LEN_TXT_ERRKEY);
str_ErrorMsg2					VARCHAR2 (SYS_LEN_TXT_ERRKEY);
amt_BalCalcAmt					amortization.bal_calc_basis_amt%TYPE;
amt_OrigCalcAmt				amortization.orig_calc_basis_amt%TYPE;
amt_OutstBookCcy				amortization.outst_amt_book_ccy%TYPE;
amt_AmrtNotPost				amortization.amort_amt_not_post%TYPE;
amt_AmrtToDate					amortization.amort_amt_to_date%TYPE;
amt_PrinAmount					amortization.bal_calc_basis_amt%TYPE;
amt_AccAmount					amortization.bal_calc_basis_amt%TYPE;
nbr_RowId						ROWID;
msc_NormalExit					EXCEPTION;
msc_AbnormalExit				EXCEPTION;


BEGIN
	BEGIN

		SELECT 	   NVL(bal_calc_basis_amt,0)	,
						NVL(orig_calc_basis_amt,0) ,
						NVL(outst_amt_book_ccy,0) ,
						NVL(amort_amt_not_post,0) ,
						NVL(amort_amt_to_date,0),
						rowid
		INTO	    	amt_BalCalcAmt,
						amt_OrigCalcAmt,
						amt_OutstBookCcy,
						amt_AmrtNotPost,
						amt_AmrtToDate,
						nbr_RowId
		FROM        amortization 
		WHERE      	country_code					= p_cod_CountryCode				AND
						country_state					= SYS_COD_AUTH						AND
						leg_veh							= p_cod_LegVeh						AND
						leg_veh_state 					= SYS_COD_AUTH						AND
						boff_code						= p_cod_BoffCode					AND
						booking_office_state  		= SYS_COD_AUTH						AND
						mis_code							= p_cod_MisCode					AND
						mis_code_state					= SYS_COD_AUTH						AND
						ref_num							= p_ref_RefNum						AND
						seq_num							= p_seq_SeqNum						AND
						charge_type						= p_cod_ChargeType				AND
						charge_type_state 			= SYS_COD_AUTH						AND
						serial_num						= p_cod_SerialNum					AND
						NVL(bal_calc_basis_amt,0) 	< NVL(orig_calc_basis_amt,0)	AND
						SYS_GET_DATE(last_amort_date)< SYS_GET_DATE(p_dat_ProcessDate) 
																									AND
						status_flag 					= SYS_COD_STAT_AMORT_ACTIVE 
		FOR UPDATE OF amort_amt_not_post, amort_amt_to_date, orig_calc_basis_amt;

		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				raise msc_NormalExit;
			WHEN TOO_MANY_ROWS THEN
				raise msc_AbnormalExit;
	END;


/******************************************************************************
* The amortization table is updated for the record selected by the SELECT     *
* statement							              												*
*******************************************************************************/



 	amt_PrinAmount:= amt_OrigCalcAmt - amt_BalCalcAmt;

 	amt_AccAmount :=	amt_PrinAmount * (amt_OutstBookCcy -
 							amt_AmrtNotPost)/amt_OrigCalcAmt;

	UPDATE	amortization
	SET  		amort_amt_not_post 	= amt_AmrtNotPost + amt_AccAmount,
				amort_amt_to_date 	= amt_AmrtToDate + amt_AccAmount,
				orig_calc_basis_amt = amt_BalCalcAmt
	WHERE 	rowid = nbr_RowId;


	EXCEPTION 
		WHEN msc_NormalExit THEN
			NULL;
		WHEN msc_AbnormalExit THEN
			str_ErrorMsg1 := p_cod_CountryCode 	|| ' ' || p_cod_LegVeh 		|| ' ';
			str_ErrorMsg1 := str_ErrorMsg1 		|| p_cod_BoffCode 			|| ' ';
			str_ErrorMsg1 := str_ErrorMsg1 		|| p_cod_MisCode				|| ' ';
			str_ErrorMsg1 := str_ErrorMsg1 		||	p_cod_ChargeType ;

			str_ErrorMsg2 := p_ref_RefNum 		|| ' ';
			str_ErrorMsg2 := str_ErrorMsg2 		|| p_seq_SeqNum		|| ' ';
			str_ErrorMsg2 := str_ErrorMsg2 		|| p_cod_SerialNum;

			sp_RaiseError('AccAmtTooManyRows',str_ErrorMsg1, str_ErrorMsg2);

END;

/
CREATE PUBLIC SYNONYM SP_AC_AccAmort_u  FOR SP_AC_AccAmort_u ;
