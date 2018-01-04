CREATE PROCEDURE SP_VALIDATION_SAVE_MKBD(
P_UPDATE_DATE DATE,
P_UDATE_SEQ NUMBER,
P_ERROR_CD OUT NUMBER,
P_ERROR_MSG VARCHAR2)
IS


  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  V_ERR          EXCEPTION;
  V_CNT NUMBER(5);
  V_AMT NUMBER;
  V_AMT_VD51 NUMBER;
  V_AMT_VD52 NUMBER;
  V_MKBD_CD NUMBER;
BEGIN

	
	BEGIN
	SELECT COUNT(1) INTO V_CNT FROM LAP_MKBD_VD51 WHERE update_date=P_UPDATE_DATE AND update_seq=P_UPDATE_SEQ AND APPROVED_STAT='A' AND ROWNUM<=1;
	EXCEPTION
	WHEN OTHERS THEN
		V_ERROR_CD :=-5;
		V_ERROR_MSG := SUBSTR('CHECK MKBD REPORT IN INBOX'||SQLERRM,1,200);
		RAISE V_ERR;
	END;

	IF V_CNT=0 THEN
		V_ERROR_CD :=-10;
		V_ERROR_MSG := 'Cannot save text file, please check approval';
		RAISE V_ERR;
	END IF;

	IF V_CNT>0 THEN

		--CEK APAKAH SAMA TOTAL VD51 DAN VD52
		BEGIN
		SELECT round(C1,2) as c1 INTO V_AMT_VD51 FROM INSISTPRO_RPT.LAP_MKBD_VD51 WHERE 
		 update_date = P_UPDATE_DATE and update_seq = P_UPDATE_SEQ AND  mkbd_cd =113 AND APPROVED_STAT='A' ;
		EXCEPTION
		WHEN OTHERS THEN
			V_ERROR_CD :=-15;
			V_ERROR_MSG := SUBSTR('CHECK TOTAL BARIS 113 LAP_MKBD_VD51 '||SQLERRM,1,200);
			RAISE V_ERR;
		END;
		BEGIN
		SELECT round(C1,2) as c1 INTO V_AMT_VD52 FROM INSISTPRO_RPT.LAP_MKBD_VD52 WHERE 
		 update_date = P_UPDATE_DATE and update_seq = P_UPDATE_SEQ AND  mkbd_cd =173 AND APPROVED_STAT='A' ;
		EXCEPTION
		WHEN OTHERS THEN
			V_ERROR_CD :=-20;
			V_ERROR_MSG := SUBSTR('CHECK TOTAL BARIS 173 LAP_MKBD_VD52 '||SQLERRM,1,200);
			RAISE V_ERR;
		END;


		IF V_AMT_VD51 <> V_AMT_VD52 THEN
			V_ERROR_CD :=-25;
			V_ERROR_MSG := 'Total MKBD VD51 tidak sama dengan MKBD VD52';
			RAISE V_ERR;
		END IF;

		BEGIN
		SELECT C2  INTO V_AMT FROM INSISTPRO_RPT.LAP_MKBD_VD59 WHERE  update_date = P_UPDATE_DATE and update_seq = P_UPDATE_SEQ
		AND mkbd_cd =104 AND APPROVED_STAT='A';
		EXCEPTION
		WHEN OTHERS THEN
			V_ERROR_CD :=-30;
			V_ERROR_MSG := SUBSTR('CHECK NILAI MINIMUM MKBD PADA LAP_MKBD_VD59 BARIS 104 '||SQLERRM,1,200);
			RAISE V_ERR;
		END;

		IF V_AMT <= 0 THEN
			V_ERROR_CD :=-35;
			V_ERROR_MSG := 'Tidak memenuhi nilai minimum MKBD, nilai saat ini adalah '||V_AMT;
			RAISE V_ERR;
		END IF;

		BEGIN
		select COUNT(1),MKBD_CD from INSISTPRO_RPT.LAP_MKBD_VD51 WHERE
		 update_date = P_UPDATE_DATE and update_seq =P_UPDATE_SEQ AND APPROVED_STAT='A' 
						 AND C1<0 GROUP BY MKBD_CD
		EXCEPTION
		WHEN OTHERS THEN
			V_ERROR_CD :=-30;
			V_ERROR_MSG := 'VD 5-1 bernilai minus pada kolom B baris '||
			RAISE V_ERR;
		END;





	END IF;

	
			//cek vd51
			$sql_vd51 = "select COUNT(1),MKBD_CD from INSISTPRO_RPT.LAP_MKBD_VD51 WHERE update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A' 
						 AND C1<0 GROUP BY MKBD_CD";
			$cek_vd51 = DAO::queryAllSql($sql_vd51);	
			
			if($cek_vd51)
			{	foreach($cek_vd51 as $row)
				{
					$this->addError('vd51', 'VD 5-1 bernilai minus pada kolom B baris '.$row['mkbd_cd']);	
				}
			}
			
			//cek vd52
			$sql_vd52 = "select COUNT(1),MKBD_CD from INSISTPRO_RPT.LAP_MKBD_VD52 WHERE update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A' 
						 AND C1<0 GROUP BY MKBD_CD";
			$cek_vd52 = DAO::queryAllSql($sql_vd52);	
			
			if($cek_vd52)
			{	foreach($cek_vd52 as $row)
				{
					$this->addError('vd52', 'VD 5-2 bernilai minus pada kolom B baris '.$row['mkbd_cd']);	
				}
			}
			//cek vd53
			$sql_vd53 = "select COUNT(1),MKBD_CD from INSISTPRO_RPT.LAP_MKBD_VD53 WHERE update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A' 
						 AND C1<0 GROUP BY MKBD_CD";
			$cek_vd53 = DAO::queryAllSql($sql_vd53);	
			if($cek_vd53)
			{	foreach($cek_vd53 as $row)
				{
					$this->addError('vd53', 'VD 5-3 bernilai minus pada kolom B baris '.$row['mkbd_cd']);	
				}
			}
			//cek vd54
			$sql_vd54 = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD54 Where
					 	update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A'  
					 	And	(market_value<0 or nab<0 or risiko_persen<0 or batasan_mkbd<0 or risiko<0)
						 Group By Mkbd_Cd";
			$cek_vd54 = DAO::queryAllSql($sql_vd54);	
			if($cek_vd54)
			{	foreach($cek_vd54 as $row)
				{
					$this->addError('vd54', 'VD 5-4 bernilai minus pada baris '.$row['mkbd_cd']);	
				}
			}
			//cek vd55
			$sql_vd55 = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD55 Where
					 	update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A'  
					 	And	(NILAI_EFEK<0 or NILAI_LINDUNG<0 or NILAI_TUTUP<0 or NILAI_HAIRCUT<0 or NILAI_HAIRCUT_LINDUNG<0 or PENGEMBALIAN<0)
						 Group By Mkbd_Cd";
			$cek_vd55 = DAO::queryAllSql($sql_vd55);	
			if($cek_vd55)
			{	foreach($cek_vd55 as $row)
				{
					$this->addError('vd55', 'VD 5-5 bernilai minus pada baris '.$row['mkbd_cd']);	
				}
			}
	
			//cek vd56
			$sql_vd56 = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD56 Where
					 	update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A'  
					 	And	(c1<0 or c2<0 or c3<0 or c4<0)
						 Group By Mkbd_Cd";
			$cek_vd56 = DAO::queryAllSql($sql_vd56);	
			if($cek_vd56)
			{	foreach($cek_vd56 as $row)
				{
					$this->addError('vd56', 'VD 5-6 bernilai minus pada baris '.$row['mkbd_cd']);	
				}
			}
			//cek vd57
			$sql_vd57 = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD57 Where
					 	update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A'  
					 	And	(c1<0 or c2<0 or c3<0 or c4<0)
						 Group By Mkbd_Cd";
			$cek_vd57 = DAO::queryAllSql($sql_vd57);	
			if($cek_vd57)
			{	foreach($cek_vd57 as $row)
				{
					$this->addError('vd57', 'VD 5-7 bernilai minus pada baris '.$row['mkbd_cd']);	
				}
			}
			//cek vd58
			$sql_vd58 = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD58 Where
					 	update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A'  
					 	And	c1<0 
						 Group By Mkbd_Cd";
			$cek_vd58 = DAO::queryAllSql($sql_vd58);	
			if($cek_vd58)
			{	foreach($cek_vd58 as $row)
				{
					$this->addError('vd58', 'VD 5-8 bernilai minus pada baris '.$row['mkbd_cd']);	
				}
			}
			//cek vd59
			$sql_vd59 = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD59 Where
					 	update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A'  
					 	And	(c1<0 or c2<0 )
						 Group By Mkbd_Cd";
			$cek_vd59 = DAO::queryAllSql($sql_vd59);	
			if($cek_vd59)
			{	foreach($cek_vd59 as $row)
				{
					$this->addError('vd59', 'VD 5-9 bernilai minus pada baris '.$row['mkbd_cd']);	
				}
			}
			//cek vd510A
			$sql_vd510a = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510a Where
					 	update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A'  
					 	And	(REPO_VAL<0 or RETURN_VAL<0 or SUM_QTY<0 or MARKET_VAL<0 or RANKING<0)
						 Group By Mkbd_Cd";
			$cek_vd510a = DAO::queryAllSql($sql_vd510a);	
			if($cek_vd510a)
			{	foreach($cek_vd510a as $row)
				{
					$this->addError('vd510a', 'VD 5-10 A bernilai minus pada baris '.$row['mkbd_cd']);	
				}
			}
			//cek vd510B
			$sql_vd510b = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510b Where
					 	update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A'  
					 	And	(REPO_VAL<0 or RETURN_VAL<0 or SUM_QTY<0 or MARKET_VAL<0 or RANKING<0)
						 Group By Mkbd_Cd";
			$cek_vd510b = DAO::queryAllSql($sql_vd510b);	
			if($cek_vd510b)
			{	foreach($cek_vd510b as $row)
				{
					$this->addError('vd510b', 'VD 5-10 B bernilai minus pada baris '.$row['mkbd_cd']);	
				}
			}
			//cek vd510C
			$sql_vd510c = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510c Where
					 	update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A'  
					 	And	(BUY_PRICE<0 or PRICE<0 or MARKET_VAL<0 or PERSEN_MARKET<0 or RANKING<0)
						 Group By Mkbd_Cd";
			$cek_vd510c = DAO::queryAllSql($sql_vd510c);	
			if($cek_vd510c)
			{	foreach($cek_vd510b as $row)
				{
					$this->addError('vd510c', 'VD 5-10 C bernilai minus pada baris '.$row['mkbd_cd']);	
				}
			}
			//cek vd510D
			$sql_vd510d = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510d Where
					 	update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A'  
					 	And	(end_bal<0 or stk_val<0 or ratio<0 or lebih_client<0 or lebih_porto<0)
						 Group By Mkbd_Cd";
			$cek_vd510d = DAO::queryAllSql($sql_vd510d);	
			if($cek_vd510d)
			{	foreach($cek_vd510d as $row)
				{
					$this->addError('vd510d', 'VD 5-10 D bernilai minus pada baris '.$row['mkbd_cd']);	
				}
			}
			//cek vd510E
			$sql_vd510e = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510e Where
					 	update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A'  
					 	And	(price<0 or market_val<0 )
						 Group By Mkbd_Cd";
			$cek_vd510e = DAO::queryAllSql($sql_vd510e);	
			if($cek_vd510e)
			{	foreach($cek_vd510e as $row)
				{
					$this->addError('vd510e', 'VD 5-10 E bernilai minus pada baris '.$row['mkbd_cd']);	
				}
			}
			//cek vd510F
			$sql_vd510f = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510f Where
					 	update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A'  
					 	And	(nilai_komitment<0 or haircut<0 or unsubscribe_amt<0 or bank_garansi<0 or ranking<0)
						 Group By Mkbd_Cd";
			$cek_vd510f = DAO::queryAllSql($sql_vd510f);	
			if($cek_vd510f)
			{	foreach($cek_vd510f as $row)
				{
					$this->addError('vd510f', 'VD 5-10 F bernilai minus pada baris '.$row['mkbd_cd']);	
				}
			}
	
			//cek vd510G
			$sql_vd510g = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510g Where
					 	update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A'  
					 	And	(NILAI<0 or RANKING<0 )
						 Group By Mkbd_Cd";
			$cek_vd510g = DAO::queryAllSql($sql_vd510g);	
			if($cek_vd510g)
			{	foreach($cek_vd510g as $row)
				{
					$this->addError('vd510g', 'VD 5-10 G bernilai minus pada baris '.$row['mkbd_cd']);	
				}
			}
			//cek vd510H
			$sql_vd510h = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510h Where
					 	update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A'  
					 	And	(SUDAH_REAL<0 or BELUM_REAL<0 and ranking<0 )
						 Group By Mkbd_Cd";
			$cek_vd510h = DAO::queryAllSql($sql_vd510h);	
			if($cek_vd510h)
			{	foreach($cek_vd510h as $row)
				{
					$this->addError('vd510h', 'VD 5-10 H bernilai minus pada baris '.$row['mkbd_cd']);	
				}
			}
			//cek vd510I
			$sql_vd510i = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510i Where
					 	update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A'  
					 	And	(NILAI_RPH<0 or UNTUNG_RUGI<0 and RANKING<0 )
						 Group By Mkbd_Cd";
			$cek_vd510i = DAO::queryAllSql($sql_vd510i);	
			if($cek_vd510i)
			{	foreach($cek_vd510i as $row)
				{
					$this->addError('vd510i', 'VD 5-10 I bernilai minus pada baris '.$row['mkbd_cd']);	
				}
			}
			
			//validasi vd56 baris 20 dana nasabah pemilik rekening harus sama dengan detail baris 24 bagian nasabah dan <>'KSEI'
			$sql ="	select b.c3-a.c3 total from
					(select sum(c3)c3 from INSISTPRO_RPT.lap_mkbd_vd56  where update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A'  
					and mkbd_cd=24 and milik='NASABAH' and bank_acct_cd='-')a
					,
					(select c3 from INSISTPRO_RPT.lap_mkbd_vd56 where update_date = '$this->update_date' and update_seq = '$this->update_seq' AND APPROVED_STAT='A'  
					and mkbd_cd='20')b ";
			$exec = DAO::queryRowSql($sql);
			
			if($exec['total'] != 0)
			{
				$this->addError('vd56', 'Total baris VD56 baris 20 tidak sama dengan total saldo di bagian detail');	
			}
			
		}
	
		$cek_bond = Tbondtrx::model()->findAll("trx_date= '$this->gen_dt' and  Approved_Sts In ('E','A') 
				And ((Nvl(Sett_Val,0) + Nvl(Sett_For_Curr,0)) = 0) And (Nvl(Journal_Status,'X') <> 'A' Or Doc_Num Is Null)");
		if($cek_bond)
		{
			$this->addError('gen_dt', "Masih ada bond yang belum dijurnal");
		}	
		
	


  P_ERROR_CD     := 1 ;
  P_ERROR_MSG    := '';
  
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_CD  := V_ERROR_CD;
  P_ERROR_MSG := V_ERROR_MSG;
WHEN OTHERS THEN
  P_ERROR_CD  := -1 ;
  P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE),1,200);
  RAISE;
END SP_VALIDATION_SAVE_MKBD;