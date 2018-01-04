create or replace PROCEDURE SP_INSERT_TMP_SDI
(
	p_client_cd				MST_CLIENT.client_cd%TYPE,
	p_client_type_1			MST_CLIENT.client_type_1%TYPE,
	p_subrek				VARCHAR2,
	p_type					NUMBER
)
IS
BEGIN
	IF p_client_type_1 = 'I' THEN
						
		INSERT INTO TMP_SDI
		(
			COL1,
			COL2,
			COL3,
			COL4,
			COL5,
			COL6,
			COL7,
			COL10,
			COL11,
			COL12,
			COL13,
			COL14,
			COL15,
			COL16,
			COL17,
			COL18,
			COL19,
			COL20,
			COL21,
			COL22,
			COL23,
			COL24,
			COL25,
			COL26,
			COL27,
			COL28,
			COL29,
			COL30,
			COL31,
			COL32,
			COL33,
			COL34,
			COL35,
			COL36,
			COL37,
			COL39,
			COL41,
			COL42,
			COL43,
			COL44,
			COL45,
			COL46,
			COL47,
			COL48,
			COL49,
			COL50,
			COL51,
			COL52,
			COL53,
			COL54,
			COL71,
			COL72,
			COL73,
			COL74
		)
		SELECT
			DECODE (p_type,1,'CREATION','MODIFICATION') AS col1,
			'INDIVIDUAL' AS col2,
			'DIRECT' AS col3,
			v.broker_cd AS col4,
			p_subrek col5,
			f.tax_id AS col6, 
			f.cif_name AS col7, 
			i.nationality  AS col10,								
			DECODE(f.ic_type,'0', F_CLEAN(f.client_ic_num),null) AS col11,							
			DECODE(f.ic_type,'0', DECODE(TO_CHAR(f.IC_EXPIRY_DT,'yyyy'),'5000','99999999','9999','99999999',TO_CHAR(f.IC_EXPIRY_DT,'yyyymmdd')),null) AS col12,							
			f.npwp_no AS col13, 
			TO_CHAR(f.npwp_date,'yyyymmdd') AS col14,							
			DECODE(f.ic_type,'2',  f.client_ic_num,null) AS col15,							
			DECODE(f.ic_type,'2', TO_CHAR(f.IC_EXPIRY_DT,'yyyymmdd'),null) AS col16,							
			NVL(i.kitas_num,f.skd_no) AS col17,							
			TO_CHAR(NVL(i.kitas_EXPIRY_DT, f.skd_expiry),'yyyymmdd') AS col18, 
			i.BIRTH_PLACE AS col19,							
			TO_CHAR(f.client_birth_dt,'yyyymmdd') AS col20, 
			i.id_addr AS col21,							
			SUBSTR(i.id_rtrw|| DECODE(f.client_type_2,'L',' Kel.','')||i.id_klurahn,1,60) AS col22,							
			SUBSTR(DECODE(f.client_type_2,'L',' Kec.','')||i.id_kcamatn,1,60)  AS col23,							
			i.city_cd AS col24, i.province_cd AS col25, 
			SUBSTR(i.id_post_cd,1,5) AS col26, 
			NVL(i.id_negara,f.country)  AS col27,							
			SUBSTR(NVL(f.phone_num,f.hp_num),1,20) col28, 
			DECODE(f.phone_num,null,'',f.hp_num) col29,							
			f.e_mail1 AS col30, 
			f.fax_num AS col31,							
			DECODE(m.def_addr_1,i.id_addr,'',m.def_addr_1) AS col32,							
			DECODE(m.def_addr_1,i.id_addr,'',m.def_addr_2) AS col33,							
			DECODE(m.def_addr_1,i.id_addr,'',m.def_addr_3) AS col34,							
			DECODE(m.def_addr_1,i.id_addr,'',DECODE(m.rebate_basis,'DM',f.def_city_cd,'')) AS col35,								
			DECODE(m.def_addr_1,i.id_addr,'',DECODE(m.rebate_basis,'DM',f.def_province_cd,'')) AS col36,								
			DECODE(m.def_addr_1,i.id_addr,'',m.post_cd) AS col37,						
			DECODE(m.rebate_basis,'KT',i.empr_phone,'') AS col39,						
			DECODE(m.rebate_basis,'KT',i.empr_email,'') AS col41,						
			DECODE(m.rebate_basis,'KT',i.empr_fax,'') AS col42,						
			i.sex_code AS col43, 
			i.marital_status AS col44, 
			i.spouse_name AS col45, 
			i.heir AS col46, 
			i.heir_relation AS col47,						
			educ_code AS col48, 
			occup_code AS col49, 
			occupation AS col50,							
			i.biz_type AS col51, 
			f.income_code AS col52, 
			f.fund_code AS col53, 
			f.source_of_funds AS col54,						
			/*b1.bank_name AS col56, 
			b1.bank_acct_num AS col57, 
			b1.bic AS col58, 
			b1.acct_name AS col59, 
			b1.currency AS col60,							
			b2.bank_name AS col61, 
			b2.bank_acct_num AS col62, 
			b2.bic AS col63, 
			b2.acct_name AS col64, 
			b2.currency AS col65,*/						
			f.purpose AS col71, 
			f.mother_name AS col72, 
			f.direct_sid AS col73, 
			f.asset_owner AS col74								
		FROM
		(  
			SELECT cifs, nationality,								
				DECODE(TRIM(i.birth_place),'JAKARTA',TRIM(i.birth_place),NVL(z.city, 'OTHERS')) birth_place,					
				p1.sex_code, id_addr,id_rtrw, i.id_klurahn, i.id_kcamatn,	y.city_cd, y.province_cd, i.id_post_cd, i.id_negara,				
				DECODE(p4.marital_status,'3',DECODE(i.sex_code,'F','4','3'),p4.marital_status ) AS marital_status,					
				spouse_name, NVL(p2.educ_code,'1') educ_code, p3.occup_code,					
				DECODE(p3.occup_code,'1',i.occupation,'') occupation,					
				DECODE(p3.occup_code,'5',i.empr_biz_type,'') biz_type,					
				heir, heir_relation, empr_phone, empr_fax, empr_email, kitas_num, kitas_expiry_dt					
			FROM mst_client_indi i, mst_city y, mst_city z,							
			( 
				SELECT prm_cd_2, prm_desc2 sex_code						
				FROM MST_PARAMETER						
				WHERE prm_cd_1 = 'GENDER'
			) p1,						
			( 
				SELECT prm_cd_2, prm_desc2 educ_code							
				FROM MST_PARAMETER							
				WHERE prm_cd_1 = 'EDUC'
			) p2,							
			( 
				SELECT prm_cd_2, prm_desc2 occup_code							
				FROM MST_PARAMETER							
				WHERE prm_cd_1 = 'WORK'
			) p3,							
			( 
				SELECT prm_cd_2, prm_desc2 marital_status							
				FROM MST_PARAMETER							
				WHERE prm_cd_1 = 'MARITL'
			) p4
			WHERE i.id_kota = y.city(+)							
			AND i.birth_place = z.city(+)						
			AND i.sex_code = p1.prm_cd_2 							
			AND i.educ_code  = p2.prm_cd_2(+)						
			AND i.OCCUP_CODE = p3.prm_cd_2(+)						
			AND i.marital_status = p4.prm_cd_2(+)						
		) i,						
		( 
			SELECT mst_cif.cifs, cif_name, tax_id, ic_type, client_ic_num, ic_expiry_dt, npwp_no, npwp_date, client_birth_dt, client_type_2, country,			
				phone_num, hp_num, e_mail1, fax_num, y.city_cd AS def_city_cd, y.province_cd AS def_province_cd, r1.income_code, r2.fund_code,	 		
				DECODE(funds_code,'90',source_of_funds,'') source_of_funds, mother_name, pu.purpose, direct_sid, asset_owner, skd_no, skd_expiry    				
			FROM MST_CIF, V_SDI_PURPOSE pu, MST_CITY y, 							
			( 
				SELECT prm_cd_2, prm_desc2 income_code						
				FROM MST_PARAMETER						
				WHERE prm_cd_1 = 'INCOME'
			) r1,						
			( 
				SELECT prm_cd_2, prm_desc2 fund_code						
				FROM MST_PARAMETER						
				WHERE prm_cd_1 = 'FUND'
			) r2						
			WHERE mst_cif.annual_income_cd = r1.prm_cd_2(+)							
			AND mst_cif.funds_code = r2.prm_cd_2(+)						
			AND mst_cif.cifs = pu.cifs(+)						
			AND mst_cif.def_city = y.city(+)
		) f,					
		( 
			SELECT m.cifs,NVL(bi.bank_name, p.bank_name) bank_name, b.bank_acct_num, bi.rtgs_code AS bic, b.acct_name, 'IDR' currency					
			FROM MST_CLIENT m, MST_CLIENT_BANK b, MST_BANK_BI bi,						
			( 
				SELECT BANK_CD, BANK_NAME						
				FROM MST_IP_BANK					
				WHERE APPROVED_STAT='A'
			) p					
			WHERE m.cifs = b.cifs						
			AND m.client_Cd = p_client_cd 						
			AND m.bank_acct_num = b.bank_acct_num						
			AND b.bank_cd = bi.ip_bank_cd(+) 						
			AND b.bank_cd = p.BANK_CD(+)
		) b1,						
		(								
			SELECT m.cifs, NVL(bi.bank_name, p.bank_name) bank_name, b.bank_acct_num, bi.rtgs_code AS bic, b.acct_name, 'IDR' currency					
			FROM MST_CLIENT m, MST_CLIENT_BANK b, MST_BANK_BI bi,						
			( 
				SELECT BANK_CD, BANK_NAME						
				FROM MST_IP_BANK					
				WHERE APPROVED_STAT='A'
			) p					
			WHERE m.cifs = b.cifs						
			AND m.client_Cd = p_client_cd 						
			AND m.bank_acct_num <> b.bank_acct_num						
			AND b.bank_cd = bi.ip_bank_cd(+)						
			AND b.bank_cd = p.BANK_CD(+)						
			AND ROWNUM = 1								
		) b2,						
		MST_CLIENT m,
		V_BROKER_SUBREK v
		WHERE client_Cd = p_client_cd 								
		AND m.cifs = f.cifs								
		AND m.cifs = i.cifs								
		AND m.cifs = b1.cifs(+)								
		AND m.cifs = b2.cifs(+);
	
	ELSE -- INSTITUTIONAL
	
		INSERT INTO TMP_SDI
		(
			COL1,
			COL2,
			COL3,
			COL4,
			COL5,
			COL6,
			COL8,
			COL9,
			COL10,
			COL11,
			COL12,
			COL13,
			COL14,
			COL15,
			COL16,
			COL17,
			COL18,
			COL19,
			COL20,
			COL21,
			COL22,
			COL23,
			COL24,
			COL25,
			COL26,
			COL27,
			COL28,
			COL29,
			COL32,
			COL38,
			COL39,
			COL40,
			COL41,
			COL42,
			COL43,
			COL46,
			COL47,
			COL48,
			COL49,
			COL50,
			COL51,
			COL52,
			COL53,
			COL54,
			COL55,
			COL56,
			COL57,
			COL58,
			COL59,
			COL60,
			COL61,
			COL62,
			COL63,
			COL64,
			COL65,
			COL66,
			COL67,
			COL68,
			COL69,
			COL70,
			COL71,
			COL72,
			COL73,
			COL74,
			COL75,
			COL76,
			COL77,
			COL78,
			COL79,
			COL80,
			COL81,
			COL82,
			COL83,
			COL84,
			COL85,
			COL86,
			COL87,
			COL88,
			COL89,
			COL90,
			COL91,
			COL94,
			COL113,
			COL114,
			COL115
		)
		SELECT DECODE (p_type,1,'CREATION','MODIFICATION') AS col1,
			'INSTITUTIONAL' AS col2,
			'DIRECT' AS col3,
			v.broker_cd AS col4,
			p_subrek col5,
			f.cif_name AS col6,			
			f.tax_id AS col8,		
			NVL(c.legal_domicile,f.country) AS col9,		
			f.npwp_no AS col10,		
			TO_CHAR(f.npwp_date,'yyyymmdd') AS col11,			
			f.skd_no AS col12,		
			TO_CHAR(f.SKD_EXPIRY,'yyyymmdd') AS col13,		
			DECODE(f.country,'INDONESIA',DECODE(SUBSTR(f.tempat_pendirian,1,7),'JAKARTA','JAKARTA',f.tempat_pendirian),'FOREIGN') AS col14,		
			TO_CHAR(f.client_birth_dt,'yyyymmdd') AS col15,		
			f.def_Addr_1 AS col16,		
			f.def_Addr_2 AS col17,		
			f.def_Addr_3 AS col18,		
			f.def_city AS col19,			
			y.province AS col20,			
			f.post_cd AS col21,		
			f.country  AS col22,		
			f.phone_num AS col23,		
			f.hp_num    AS col24,		
			f.e_mail1   AS col25,		
			f.fax_num   AS col26,		
			DECODE(m.rebate_basis,'SU',m.def_addr_1,'') AS col27,		
			DECODE(m.rebate_basis,'SU',m.def_addr_2,'') AS col28,		
			DECODE(m.rebate_basis,'SU',m.def_addr_3,'') AS col29,		
			DECODE(m.rebate_basis,'SU',m.post_cd,'') AS col32,		
			r1.biz_code  AS col38,		
			r2.char_cd   AS col39,		
			r3.fund_cd   AS col40,		
			f.act_first  AS col41,		
			f.siup_no    AS col42,		
			SUBSTR(f.autho_person_name,1,40) AS col43,		
			f.autho_person_position AS col46,		
			DECODE(f.autho_person_ic_type,'0',F_CLEAN(f.autho_person_ic_num),'') AS col47,		
			DECODE(f.autho_person_ic_type,'0',TO_CHAR(f.autho_person_ic_expiry,'yyyymmdd'),'') AS col48,		
			DECODE(f.autho_person_ic_type,'4',F_CLEAN(f.autho_person_ic_num),'') AS col49,		
			DECODE(f.autho_person_ic_type,'4',TO_CHAR(f.autho_person_ic_expiry,'yyyymmdd'),'') AS col50,		
			DECODE(f.autho_person_ic_type,'2',F_CLEAN(f.autho_person_ic_num),'') AS col51,		
			DECODE(f.autho_person_ic_type,'2',TO_CHAR(f.autho_person_ic_expiry,'yyyymmdd'),'') AS col52,		
			DECODE(f.autho_person_ic_type,'5',F_CLEAN(f.autho_person_ic_num),'') AS col53,		
			DECODE(f.autho_person_ic_type,'5',TO_CHAR(f.autho_person_ic_expiry,'yyyymmdd'),'') AS col54,		
			a2.first_name AS col55,		
			a2.middle_name AS col56,		
			a2.last_name AS col57,		
			a2.POSITION AS col58,	
			F_CLEAN(a2.KTP_NO) AS col59,	
			TO_CHAR(a2.KTP_EXPIRY,'yyyymmdd') AS col60,	
			F_CLEAN(a2.NPWP_NO) AS col61,	
			TO_CHAR(a2.NPWP_DATE,'yyyymmdd') AS col62,	
			F_CLEAN(a2.PASSPORT_NO) AS col63,	
			TO_CHAR(a2.PASSPORT_EXPIRY,'yyyymmdd') AS col64,	
			F_CLEAN(a2.KITAS_NO) AS col65,	
			TO_CHAR(a2.KITAS_EXPIRY,'yyyymmdd') AS col66,	
			a3.first_name AS col67,		
			a3.middle_name AS col68,		
			a3.last_name AS col69,		
			a3.POSITION AS col70,	
			F_CLEAN(a3.KTP_NO) AS col71,	
			TO_CHAR(a3.KTP_EXPIRY,'yyyymmdd') AS col72,	
			F_CLEAN(a3.NPWP_NO) AS col73,	
			TO_CHAR(a3.NPWP_DATE,'yyyymmdd') AS col74,	
			F_CLEAN(a3.PASSPORT_NO) AS col75,	
			TO_CHAR(a3.PASSPORT_EXPIRY,'yyyymmdd') AS col76,	
			F_CLEAN(a3.KITAS_NO) AS col77,	
			TO_CHAR(a3.KITAS_EXPIRY,'yyyymmdd') AS col78,	
			a4.first_name AS col79,		
			a4.middle_name AS col80,		
			a4.last_name AS col81,		
			a4.POSITION AS col82,	
			F_CLEAN(a4.KTP_NO) AS col83,	
			TO_CHAR(a4.KTP_EXPIRY,'yyyymmdd') AS col84,	
			F_CLEAN(a4.NPWP_NO) AS col185,	
			TO_CHAR(a4.NPWP_DATE,'yyyymmdd') AS col186,	
			F_CLEAN(a4.PASSPORT_NO) AS col87,	
			TO_CHAR(a4.PASSPORT_EXPIRY,'yyyymmdd') AS col88,	
			F_CLEAN(a4.KITAS_NO) AS col89,	
			TO_CHAR(a4.KITAS_EXPIRY,'yyyymmdd') AS col90,	
			r4.asset_cd AS col91,		
			r5.profit_cd AS col94,		
			/*b1.bank_name AS col103,		
			b1.bank_acct_num AS col104,		
			b1.bic AS col105,
			b1.acct_name AS col106,		
			b1.currency AS col107,		
			b2.bank_name AS col108,		
			b2.bank_acct_num AS col109,		
			b2.bic AS col110,
			b2.acct_name AS col111,		
			b2.currency AS col112,	*/	
			pu.purpose AS col113,		
			f.direct_sid AS col114,		
			f.asset_owner AS col115		
		FROM MST_CLIENT m, MST_CIF f, V_SDI_PURPOSE pu, 			
		MST_CITY y, MST_CLIENT_INST c, 			
		( 
			SELECT prm_cd_2, prm_desc2 biz_code			
			FROM MST_PARAMETER			
			WHERE prm_cd_1 = 'BIZTYP'
		) r1,			
		( 
			SELECT prm_cd_2, prm_desc2 char_cd			
			FROM MST_PARAMETER			
			WHERE prm_cd_1 = 'KARAK'
		) r2,			
		( 
			SELECT prm_cd_2, PRM_DESC2 fund_cd			
			FROM MST_PARAMETER			
			WHERE prm_cd_1 = 'FUNDC'
		) r3,			
		( 
			SELECT prm_cd_2, prm_desc2 asset_cd			
			FROM MST_PARAMETER			
			WHERE (prm_cd_1 = 'NASSET' or prm_cd_1 = 'TASSET' )
		) r4,			
		( 
			SELECT prm_cd_2, prm_desc2 profit_cd			
			FROM MST_PARAMETER			
			WHERE prm_cd_1 = 'PROFIT'
		) r5,			
		( 
			SELECT *			
			FROM
			( 
				SELECT cifs, ROW_NUMBER() OVER (PARTITION BY cifs ORDER BY cifs,seqno) norut, first_name, middle_name, last_name, position, 		
					npwp_no, npwp_date, ktp_no, ktp_expiry, passport_no, passport_expiry, kitas_no, kitas_expiry		
				FROM mst_client_autho
			)		
			WHERE norut = 1  
		) a2,		
		( 
			SELECT *			
			FROM
			( 
				SELECT cifs, ROW_NUMBER() OVER (PARTITION BY cifs ORDER BY cifs,seqno) norut, first_name, middle_name, last_name, position, 		
					npwp_no, npwp_date, ktp_no, 		
					ktp_expiry, passport_no, passport_expiry, 		
					kitas_no, kitas_expiry		
				FROM mst_client_autho
			)		
			WHERE norut = 2  
		) a3,		
		( 
			SELECT *		
			FROM
			( 
				SELECT cifs, ROW_NUMBER() OVER (PARTITION BY cifs order by cifs,seqno) norut, first_name, middle_name, last_name, position, 		
					npwp_no, npwp_date, ktp_no, ktp_expiry, passport_no, passport_expiry, kitas_no, kitas_expiry		
				FROM MST_CLIENT_AUTHO
			)		
			WHERE NORUT = 3  
		) a4,		
		( 
			SELECT m.cifs,NVL(bi.bank_name, p.bank_name) bank_name, b.bank_acct_num, bi.rtgs_code AS bic, b.acct_name, 'IDR' currency
			FROM MST_CLIENT m, MST_CLIENT_BANK b, MST_BANK_BI bi,	
			( 
				SELECT BANK_CD, BANK_NAME	
				FROM MST_IP_BANK
				WHERE APPROVED_STAT='A'
			) p
			WHERE m.cifs = b.cifs	
			AND m.client_Cd = p_client_cd
			AND m.bank_acct_num = b.bank_acct_num	
			AND b.bank_cd = bi.ip_bank_cd(+) 	
			AND b.bank_cd = p.BANK_CD(+)
		) b1,	
		(			
			SELECT m.cifs, NVL(bi.bank_name, p.bank_name) bank_name, b.bank_acct_num, bi.rtgs_code AS bic, b.acct_name, 'IDR' currency
			FROM MST_CLIENT m, MST_CLIENT_BANK b, MST_BANK_BI bi,	
			( 
				SELECT BANK_CD, BANK_NAME	
				FROM MST_IP_BANK
				WHERE APPROVED_STAT='A'
			) p
			WHERE m.cifs = b.cifs	
			AND m.client_Cd = p_client_cd
			AND m.bank_acct_num <> b.bank_acct_num	
			AND b.bank_cd = bi.ip_bank_cd(+)	
			AND b.bank_cd = p.BANK_CD(+)	
			AND ROWNUM = 1			
		) b2,
		V_BROKER_SUBREK v
		WHERE client_Cd = p_client_cd
		AND m.cifs = f.cifs			
		AND m.cifs = c.cifs			
		AND f.biz_type = r1.prm_cd_2(+)			
		AND f.inst_type = r2.prm_cd_2(+)			
		AND f.funds_code = r3.prm_cd_2(+)			
		AND f.net_asset_cd = r4.prm_cd_2(+)			
		AND f.profit_cd = r5.prm_cd_2(+)			
		AND m.cifs = pu.cifs(+)			
		AND f.def_city = y.city(+)			
		AND m.cifs = a2.cifs(+)			
		AND m.cifs = a3.cifs(+)			
		AND m.cifs = a4.cifs(+)			
		AND m.cifs = b1.cifs(+)			
		AND m.cifs = b2.cifs(+);
	
	END IF;
		
END SP_INSERT_TMP_SDI;