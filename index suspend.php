<?php
$this->breadcrumbs=array(
	'Clients'=>array('index'),
	'List',
);

$this->menu=array(
	array('label'=>'Client', 'itemOptions'=>array('class'=>'nav-header')),
	array('label'=>'List','url'=>array('index'),'icon'=>'list','itemOptions'=>array('class'=>'active')),
	array('label'=>'Create','url'=>array('create'),'icon'=>'plus'),
);

Yii::app()->clientScript->registerScript('search', "
$('.search-button').click(function(){
	$('.search-form').toggle();
	return false;
});
$('.search-form form').submit(function(){
	$.fn.yiiGridView.update('client-grid', {
		data: $(this).serialize()
	});
	return false;
});
");
?>

<h1>List Clients</h1>

<?php echo CHtml::link('Advanced Search','#',array('class'=>'search-button btn')); ?>
<div class="search-form" style="display:none">
<?php $this->renderPartial('_search',array(
	'model'=>$model,
)); ?>
</div><!-- search-form -->

<?php AHelper::showFlash($this) ?> <!-- show flash -->

<?php $this->widget('bootstrap.widgets.TbGridView',array(
	'id'=>'client-grid',
    'type'=>'striped bordered condensed',
	'dataProvider'=>$model->search(),
	'filter'=>$model,
    'filterPosition'=>'',
	'columns'=>array(
		'cif_number',
		'client_name',
		'client_name_abbr',
		'client_type_1',
		'client_type_2',
		'client_type_3',
		/*
		'client_title',
		'client_birth_dt',
		'religion',
		'acct_open_dt',
		'client_race',
		'client_ic_num',
		'chq_payee_name',
		'sett_off_cd',
		'stk_exch',
		'ic_type',
		'curr_cd',
		'def_curr_cd',
		'rem_cd',
		'bank_cd',
		'bank_brch_cd',
		'def_contra_flg',
		'cust_client_flg',
		'cr_lim',
		'susp_stat',
		'def_addr_1',
		'def_addr_2',
		'def_addr_3',
		'post_cd',
		'contact_pers',
		'phone_num',
		'hp_num',
		'fax_num',
		'e_mail1',
		'hand_phone1',
		'phone2_1',
		'regn_cd',
		'desp_pref',
		'stop_pay',
		'old_ic_num',
		'print_flg',
		'rem_own_trade',
		'avg_flg',
		'client_name_ext',
		'branch_code',
		'pph_appl_flg',
		'levy_appl_flg',
		'int_on_payable',
		'int_on_receivable',
		'int_on_adv_recd',
		'grace_period',
		'int_rec_days',
		'int_pay_days',
		'tax_on_interest',
		'agreement_no',
		'npwp_no',
		'rebate',
		'rebate_basis',
		'commission_per',
		'acopen_fee_flg',
		'next_rollover_dt',
		'ac_expiry_dt',
		'commit_fee_dt',
		'roll_fee_dt',
		'recov_charge_flg',
		'upd_dt',
		'cre_dt',
		'user_id',
		'rebate_tottrade',
		'amt_int_flg',
		'internet_client',
		'contra_days',
		'vat_appl_flg',
		'int_accumulated',
		'bank_acct_num',
		'custodian_cd',
		'olt',
		'sid',
		'biz_type',
		'cifs',
		'upd_by',
		'approved_dt',
		'approved_by',
		'approved_stat',
		'reference_name',
		'trade_conf_send_to',
		'trade_conf_send_freq',
		'def_city',
		'commission_per_sell',
		'commission_per_buy',
		'recommended_by_cd',
		'recommended_by_other',
		'transaction_limit',
		'init_deposit_amount',
		'init_deposit_efek',
		'init_deposit_efek_price',
		'init_deposit_efek_date',
		'id_copy_flg',
		'npwp_copy_flg',
		'koran_copy_flg',
		'copy_other_flg',
		'copy_other',
		'client_class',
		'closed_date',
		'susp_trx',
		*/
		array(
			'class'=>'bootstrap.widgets.TbButtonColumn',
		),
	),
)); ?>
