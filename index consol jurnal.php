<style>
	.filter-group *
	{
		float:left;
	}
	#tableGen
	{
		background-color:#C3D9FF;
	}
	#tableGen thead, #tableGen tbody
	{
		display:block;
	}
	#tableGen tbody
	{
		max-height:300px;
		overflow:auto;
		background-color:#FFFFFF;
	}
	.markCancel
	{
		background-color:#BB0000;
	}
</style>

<?php
$this->breadcrumbs=array(
	'Consolidation Journal Entry'=>array('index'),
	'List',
);

$this->menu=array(
	array('label'=>'Consolidation Journal Entry', 'itemOptions'=>array('style'=>'font-size:30px;font-weight:bold;color:black;margin-left:-17px;margin-top:8px;')),
	array('label'=>'List','url'=>array('index'),'icon'=>'list','itemOptions'=>array('class'=>'active','style'=>'float:right')),
		//array('label'=>'Create','url'=>array('create'),'icon'=>'plus','itemOptions'=>array('style'=>'float:right')),
	array('label'=>'Approval','url'=>Yii::app()->request->baseUrl.'?r=inbox/tconsoljrn/index','icon'=>'list','itemOptions'=>array('style'=>'float:right')),
	
	
);
?>

<?php AHelper::showFlash($this) ?> <!-- show flash -->
<?php AHelper::applyFormatting() ?> 


<?php $form=$this->beginWidget('bootstrap.widgets.TbActiveForm',array(
	'id'=>'Tconsoljrn-form',
	'enableAjaxValidation'=>false,
	'type'=>'horizontal'
)); ?>

<?php echo $form->errorSummary($modelfilter); ?>
<?php 
	foreach($model as $row)
		echo $form->errorSummary(array($row)); 
?>

<br/>

<?php $no_urut = Tconsoljrn::model()->findBySql("Select max(tal_id) as tal_id from t_consol_jrn")->tal_id;

?>

<div class="row-fluid control-group">
	<div class="span2">
		<label>Report Date</label>
	</div>
	<div class="span2" style="margin-left: -50px">
<?php echo $form->textField($modelfilter,'rep_date',array('required'=>true,'class'=>'span','placeholder'=>'dd/mm/yyyy','style'=>'width:100px;'));?>		
	</div>
	<div class="span8">
			<?php $this->widget('bootstrap.widgets.TbButton', array(
			'buttonType'=>'submit',
			'type'=>'primary',
			'htmlOptions'=>array('id'=>'btnFilter','style'=>'margin-left:0px;','class'=>'btn-small'),
			'label'=>'Retrieve',
		)); ?>
	</div>
</div>




	



<input type="hidden" name="rowCount" id="rowCount" />
<input type="hidden" name="scenario" id="scenario" />

<table id='tableGen' class='table-bordered table-condensed'>
	<thead>
		<tr>
			<th id="header0"><input style="margin-left:10px;" type="checkbox" id="checkBoxAll" value="1" onClick= "changeAll()"/></th>
			<th id="header1" >Journal Code</th>
			<th id="header2" >Date</th>
			<th id="header3">No. Urut</th>
			<th id="header4">Entity</th>
			<th id="header5">Gl Main Acct Cd</th>
			<th id="header6">Sub Acct Cd</th>
			<th id="header7">Debit/Credit</th>
			<th id="header8">Amount</th>
			<th id="header9">Description</th>
			<th id="header10">
				<a title="add"  style="cursor: pointer" onclick="addRow()"><img src="<?php echo Yii::app()->request->baseUrl ?>/images/add.png" /></a>
			</th>
		</tr>
	</thead>
	<tbody>
	<?php $x = 1;
		foreach($model as $row){
		
	?>
		<tr id="row<?php echo $x ?>" class="<?php if($row->cancel_flg == 'Y')echo 'markCancel' ?>">
			<td width="20px" class="save_flg">
				<?php echo $form->checkBox($row,'save_flg',array('onChange'=>'rowControl(this)','class'=>'checkBoxDetail','value' => 'Y','name'=>'Tconsoljrn['.$x.'][save_flg]','style'=>'margin-left:10px;')); ?>
					<?php if($row->old_xn_doc_num): ?>
					<input type="hidden" name="Tconsoljrn[<?php echo $x ?>][cancel_flg]" value="<?php echo $row->cancel_flg ?>"/>	
				<?php endif; ?>
			</td>
			<td width="60px" class="folder_cd">
			<?php echo $form->textField($row,'folder_cd',array('readonly'=>$row->save_flg !='Y'?'readonly':'','id'=>"folder_cd_$x",'class'=>'span','name'=>'Tconsoljrn['.$x.'][folder_cd]'));?>
			</td>
			<td width="80px" class="doc_date">
				<?php echo $form->textField($row,'doc_date',array('readonly'=>$row->save_flg !='Y'?'readonly':'','class'=>'span tdate','name'=>'Tconsoljrn['.$x.'][doc_date]'));?>
			<input type="hidden" name="Tconsoljrn[<?php echo $x ?>][old_doc_date]" value="<?php echo $row->old_doc_date ?>" />
			<input type="hidden" name="Tconsoljrn[<?php echo $x ?>][old_xn_doc_num]" value="<?php echo $row->old_xn_doc_num ?>" />
			</td>
			<td width="40px">
				<?php echo $form->textField($row,'tal_id',array('readonly'=>$row->save_flg !='Y'?'readonly':'','class'=>'span','name'=>'Tconsoljrn['.$x.'][tal_id]'));?>
				<input type="hidden" name="Tconsoljrn[<?php echo $x ?>][old_tal_id]" value="<?php echo $row->old_tal_id ?>" />
			</td>
			<td width="50px">
				<?php echo $form->dropDownList($row,'entity',array('YJ'=>'YJ','LIM'=>'LIM'),array('readonly'=>$row->save_flg !='Y'?'readonly':'','class'=>'span','name'=>'Tconsoljrn['.$x.'][entity]'));?>
			</td>
			<td width="50px">
				<?php echo $form->textField($row,'gl_acct_cd',array('readonly'=>$row->save_flg !='Y'?'readonly':'','class'=>'span','name'=>'Tconsoljrn['.$x.'][gl_acct_cd]'));?>
			</td>
			<td width="70px">
				<?php echo $form->textField($row,'sl_acct_cd',array('readonly'=>$row->save_flg !='Y'?'readonly':'','class'=>'span','name'=>'Tconsoljrn['.$x.'][sl_acct_cd]'));?>
			</td>
			<td width="80px"  class="dbcr">
				<?php echo $form->dropDownList($row,'db_cr_flg',array('C'=>'CREDIT','D'=>'DEBIT'),array('readonly'=>$row->save_flg !='Y'?'readonly':'','onchange'=>'init()','class'=>'span','name'=>'Tconsoljrn['.$x.'][db_cr_flg]'));?>
			</td>
			<td width="120px" class="curr_val">
				<?php echo $form->textField($row,'curr_val',array('readonly'=>$row->save_flg !='Y'?'readonly':'','onchange'=>'init()','class'=>'span','name'=>'Tconsoljrn['.$x.'][curr_val]','style'=>'text-align:right;'));?>
			</td>
			<td width="210px" class="ledger_nar">
				<?php echo $form->textField($row,'ledger_nar',array('readonly'=>$row->save_flg !='Y'?'readonly':'','class'=>'span','name'=>'Tconsoljrn['.$x.'][ledger_nar]'));?>
			</td>
			<td width="30px">
				<a style="cursor: pointer"
				title="<?php if($row->old_xn_doc_num) echo 'cancel';else echo 'delete'?>" 
					onclick="<?php if($row->old_xn_doc_num) echo 'cancel(this,\''.$row->cancel_flg.'\','.$x.')';else echo 'deleteRow(this)'?>">
					<img src="<?php echo Yii::app()->request->baseUrl ?>/images/delete.png">	
			</td>
			
		</tr>
	<?php $x++;
} ?>
	</tbody>
</table>
<div class="row-fluid">
	<div class="span7" style="text-align: right; ">
		<label  id="label_balance" style="margin-right: 20px;">Balance</label>
	</div>
	<div class="span5"  style="margin-left: 0px">
		<?php echo $form->textField($modelfilter,'balance',array('class'=>'span5','style'=>'width:125px;text-align:right'));?>
	</div>
	
</div>
<br class="temp"/>
	
	<?php if($model): ?>
		<?php echo $form->label($modelfilter, 'Cancel Reason', array('class'=>'control-label cancel_reason'))?>
		<textarea id="cancel_reason" class="span5 cancel_reason" name="cancel_reason" maxlength="200" rows="4" disabled><?php echo $cancel_reason ?></textarea>
		<?php endif; ?>
	<br class="temp"/><br class="temp"/>



<div class="form-actions"  class="text-center">
	<?php $this->widget('bootstrap.widgets.TbButton', array(
			'buttonType'=>'submit',
			'type'=>'primary',
			'htmlOptions'=>array('id'=>'btnProses','style'=>'margin-left:100px;','class'=>'btn'),
			'label'=>'Save',
		)); ?>
</div>


<?php echo $form->datePickerRow($modelfilter,'cre_dt',array('label'=>false,'disabled'=>'disabled','style'=>'display:none','options'=>array('format' => 'dd/mm/yyyy'))); ?>

<?php $this->endWidget(); ?>
<script>
var rowCount =<?php echo count($model);?>;

var authorizedCancel = true;
init();
otorisasi;
function otorisasi(){
	$.ajax({
    		'type'     :'POST',
    		'url'      : '<?php echo $this->createUrl('ajxValidateCancel'); ?>',
			'dataType' : 'json',
			'statusCode':
			{
				403		: function(data){
					authorizedCancel = false;
				}
			}
		});
	//	cancel_reason();
}
function init(){
	$('#Tconsoljrn_rep_date').datepicker({format : "dd/mm/yyyy"});
	
	var balance=0;
	$("#tableGen").children('tbody').children('tr').each(function()
		{
		$(this).children('td.ledger_nar').children('[type=text]').val($(this).children('td.ledger_nar').children('[type=text]').val().toUpperCase());
		$(this).children('td.folder_cd').children('[type=text]').val($(this).children('td.folder_cd').children('[type=text]').val().toUpperCase());
		
		$(this).children('td.curr_val').children('[type=text]').val(setting.func.number.addCommasDec($(this).children('td.curr_val').children('[type=text]').val()));
		$(this).children('td.doc_date').children('[type=text]').datepicker({format : "dd/mm/yyyy"});
		
	
		if($(this).children('td.curr_val').children('[type=text]').val() =='' || $(this).children('td.curr_val').children('[type=text]').val() == null){
		$(this).children('td.curr_val').children('[type=text]').val('0');
	
	
		}
		
		var curr_val = parseInt(setting.func.number.removeCommas($(this).children('td.curr_val').children('[type=text]').val())) * 100
		
		var dbcrFlg = $(this).children('td.dbcr').children('select').val();
		
		if(dbcrFlg == 'D' && (!$(this).hasClass('markCancel')))
			{
				//alert(curr_val);
				balance +=curr_val;
			}
			else if(dbcrFlg == 'C' && (!$(this).hasClass('markCancel'))){
				balance -=curr_val;
			}
			
	
	});
	balance = balance/100;
	$('#Tconsoljrn_balance').val(setting.func.number.addCommasDec(balance));
	
}

function checkBalance(){
	var balance = 0;
		var curr_bal= 0;
		var curr_balance=0;
		var credit=0;
		var t_credit=0;
		$("#tableGen").children('tbody').children('tr').each(function()
		{
	if($(this).children('td.curr_val').children('[type=text]').val() =='' || $(this).children('td.curr_val').children('[type=text]').val() == null){
		$(this).children('td.curr_val').children('[type=text]').val('0');
	
	
		}
		
		var curr_val = parseInt(setting.func.number.removeCommas($(this).children('td.curr_val').children('[type=text]').val())) * 100
		
		var dbcrFlg = $(this).children('td.dbcr').children('select').val();
		
		
		
			if(dbcrFlg == 'D' && (!$(this).hasClass('markCancel')))
			{
				balance += amt;
				curr_balance += curr_amt;
				curr_bal = curr_balance /100;
			}
			else if(dbcrFlg == 'C' && (!$(this).hasClass('markCancel')))
			{
				balance -= amt;
				credit +=amt;
				t_credit =credit/100;
			}
			else
			{
				return false;
			}
		
		
		});
		
		
		
		if(balance != 0){
			alert("             Amount not balanace \nTotal Debit "+curr_bal +" dan Total Credit "+ t_credit);
			return false;
		}
		else 
			//alert(curr_bal);
			
		// $('#Tjvchh_curr_amt').val(curr_bal);
			return true; 
		
		
}

	
	
	$('#btnFilter').click(function(){
		$('#scenario').val('filter');
	});
	
	$('#btnProses').click(function(){
		$('#scenario').val('proses');
		$('#rowCount').val(rowCount);
	})
	
if(rowCount ==0){
	
	 $(window).resize(function() {
		//adjustWidth();
		// adjustWidthNull();
	})
	$(window).trigger('resize');
}

	$(window).resize(function() {
		adjustWidth();
		 adjustWidthNull();
	})
	$(window).trigger('resize');
	
	function adjustWidth(){
		$("#header0").width($("#tableGen tbody tr:eq(0) td:eq(0)").width());
		$("#header1").width($("#tableGen tbody tr:eq(0) td:eq(1)").width());
		$("#header2").width($("#tableGen tbody tr:eq(0) td:eq(2)").width());
		$("#header3").width($("#tableGen tbody tr:eq(0) td:eq(3)").width());
		$("#header4").width($("#tableGen tbody tr:eq(0) td:eq(4)").width());
		$("#header5").width($("#tableGen tbody tr:eq(0) td:eq(5)").width());
		$("#header6").width($("#tableGen tbody tr:eq(0) td:eq(6)").width());
		$("#header7").width($("#tableGen tbody tr:eq(0) td:eq(7)").width());
		$("#header8").width($("#tableGen tbody tr:eq(0) td:eq(8)").width());
		$("#header9").width($("#tableGen tbody tr:eq(0) td:eq(9)").width());
		$("#header10").width($("#tableGen tbody tr:eq(0) td:eq(10)").width());

	}
		function adjustWidthNull(){
		$("#header0").width('20px');
		$("#header1").width('50px');
		$("#header2").width('80px');
		$("#header3").width('40px');
		$("#header4").width('50px');
		$("#header5").width('50px');
		$("#header6").width('70px');
		$("#header7").width('80px');
		$("#header8").width('120px');
		$("#header9").width('210px');
		$("#header10").width('30px');

	}
	var urut = parseInt('<?php echo $no_urut;?>');
	function addRow()
	{ 	
		var tahun =$('#Tconsoljrn_rep_date').val().substr(6,9);
        var bulan =parseInt($('#Tconsoljrn_rep_date').val().substr(3,2))-1;
       	var hari =$('#Tconsoljrn_rep_date').val().substr(0,2);
		
			 var currentDate = new Date();
		    var day = currentDate.getDate();
		    var month = currentDate.getMonth() + 1;
		    var year = currentDate.getFullYear();
		    if($('#Tconsoljrn_rep_date').val() =='' || $('#Tconsoljrn_rep_date').val() == null){
		    	tahun=year;
		    	bulan=month;
		    	hari=day;
		    }
    
		
       
		$("#tableGen").find('tbody')
    		.prepend($('<tr>')
    			.attr('id','row'+(rowCount+1))
    			  	.append($('<td>')
					.append($('<input>')
						.attr('class','checkBoxDetail')
						.attr('name','Tconsoljrn[1][save_flg]')
						.attr('type','checkbox')
						.attr('onChange','rowControl(this,false)')
						.prop('checked',true)
						.val('Y')
					.css('margin-left','10px')
				)
				.css('width','15px')
				
			).append($('<td>')
						.attr('class','folder_cd')
               		 .append($('<input>')
               		 	.attr('class','span')
               		 	.attr('id','folder_cd_1')
               		 	.attr('name','Tconsoljrn[1][folder_cd]')
               		 	.attr('onchange','init()')
               		 	.attr('type','text')
               		)
               		.css('width','50px')
               	)
			
				.append($('<td>')
               		 .append($('<input>')
               		 	.attr('class','span tdate doc_date')
               		 	.attr('name','Tconsoljrn[1][doc_date]')
               		 	.attr('type','text')
               		 	.datepicker({format : "dd/mm/yyyy"})
               		 	
               		 	
               		 	.datepicker('update',new Date(tahun,bulan,hari))
               		 	.val($('#Tconsoljrn_rep_date').val())
               		 	.attr('placeholder','dd/mm/yyyy')
               		)
               		.css('width','80px')
               	)
				.append($('<td>')
               		 .append($('<input>')
               		 	.attr('class','span')
               		 	.attr('name','Tconsoljrn[1][tal_id]')
               		 	.attr('type','text')
               		 	.val(urut+1)
               		)
               		.css('width','40px')
               	)
			
        	.append($('<td>')
               		 .append($('<select>')
               		 	.attr('class','span')
               		 	.attr('name','Tconsoljrn[1][entity]')
               		 	
               		 	.append($('<option>')
               		 		.val('YJ')
               		 		.html('YJ')
               		 	)
               		 	.append($('<option>')
               		 		.val('LIM')
               		 		.html('LIM')
               		 	)
               		)
               		 	.css('width','50px')
               	)
			.append($('<td>')
               		 .append($('<input>')
               		 	.attr('class','span')
               		 	.attr('name','Tconsoljrn[1][gl_acct_cd]')
               		 	.attr('type','text')
               		)
               		.css('width','50px')
               	)
			.append($('<td>')
               		 .append($('<input>')
               		 	.attr('class','span')
               		 	.attr('name','Tconsoljrn[1][sl_acct_cd]')
               		 	.attr('type','text')
               		)
               		.css('width','70px')
               	)
			.append($('<td>')
               	 	.attr('class','dbcr')
               		 .append($('<select>')
               		 	.attr('class','span')
               		 	.attr('name','Tconsoljrn[1][db_cr_flg]')
               		 	.attr('required','required')
               		 	.attr('onchange','init()')
               		 	.append($('<option>')
               		 	.attr('value','C')
               		 	.html('CREDIT'))
               		 	.append($('<option>')
               		 	.attr('value','D')
               		 	.html('DEBIT'))
               		)
               		.css('width','80px')
               	)
               	.append($('<td>')
               			.attr('class','curr_val')
               		 .append($('<input>')
               		 	.attr('class','span')
               		 	.attr('name','Tconsoljrn[1][curr_val]')
               		 	.attr('type','text')
               		 	.css('text-align','right')
               		 	.attr('onchange','init()')
               		 	
               		 	.focus(
               		 		function()
               		 		{
               		 			$(this).val(setting.func.number.removeCommas($(this).val()));
               		 		}
               		 	)
               		 	.blur(
               		 		function()
               		 		{
               		 			$(this).val(setting.func.number.addCommasDec($(this).val()));
               		 		}
               		 	)
               		)
               		.css('width','120px')
               	)
               	.append($('<td>')
               		.attr('class','ledger_nar')
               		 .append($('<input>')
               		 	.attr('class','span')
               		 	.attr('name','Tconsoljrn[1][ledger_nar]')
               		 	.attr('type','text')
               		 	.attr('onchange','init()')
               		)
               		.css('width','210px')
               	)
               	.append($('<td>')
               		
               		.append('&nbsp;')
               		 .append($('<a>')
           		 		.attr('onClick','deleteRow(this)')
           		 		.attr('title','delete')
           		 		.append($('<i>')
           		 			.attr('class','icon-remove')
           		 		)
               		)
               		.css('cursor','pointer')
               	)  
               	
             	
    		);
    	
    	rowCount++;
    	$('#folder_cd_1').focus();
    	reassignId();
    	urut++;
    	
	}
	function deleteRow(obj)
	{
		$(obj).closest('tr').remove();
		rowCount--;
		reassignId();
	}
	
	function reassignId()
   	{
   		for(x=0;x<rowCount;x++)
   		{
			$("#tableGen tbody tr:eq("+x+")").attr("id","row"+(x+1));	
			$("#tableGen tbody tr:eq("+x+") td:eq(1) [type=text]").attr("id","folder_cd_"+(x));
			$("#tableGen tbody tr:eq("+x+") td:eq(0) [type=checkbox]").attr("name","Tconsoljrn["+(x+1)+"][save_flg]");
			$("#tableGen tbody tr:eq("+x+") td:eq(0) [type=hidden]:eq(1)").attr("name","Tconsoljrn["+(x+1)+"][cancel_flg]");
			$("#tableGen tbody tr:eq("+x+") td:eq(0) [type=hidden]:eq(0)").attr("name","Tconsoljrn["+(x+1)+"][save_flg]");
			$("#tableGen tbody tr:eq("+x+") td:eq(1) [type=text]").attr("name","Tconsoljrn["+(x+1)+"][folder_cd]");
			$("#tableGen tbody tr:eq("+x+") td:eq(2) [type=text]").attr("name","Tconsoljrn["+(x+1)+"][doc_date]");
			$("#tableGen tbody tr:eq("+x+") td:eq(2) [type=hidden]:eq(0)").attr("name","Tconsoljrn["+(x+1)+"][old_doc_date]");
			$("#tableGen tbody tr:eq("+x+") td:eq(2) [type=hidden]:eq(1)").attr("name","Tconsoljrn["+(x+1)+"][old_xn_doc_num]");
			$("#tableGen tbody tr:eq("+x+") td:eq(3) [type=text]").attr("name","Tconsoljrn["+(x+1)+"][tal_id]");
			$("#tableGen tbody tr:eq("+x+") td:eq(3) [type=hidden]").attr("name","Tconsoljrn["+(x+1)+"][old_tal_id]");
			$("#tableGen tbody tr:eq("+x+") td:eq(4) select").attr("name","Tconsoljrn["+(x+1)+"][entity]");
			$("#tableGen tbody tr:eq("+x+") td:eq(5) [type=text]").attr("name","Tconsoljrn["+(x+1)+"][gl_acct_cd]");
			$("#tableGen tbody tr:eq("+x+") td:eq(6) [type=text]").attr("name","Tconsoljrn["+(x+1)+"][sl_acct_cd]");
			$("#tableGen tbody tr:eq("+x+") td:eq(7) select").attr("name","Tconsoljrn["+(x+1)+"][db_cr_flg]");
			$("#tableGen tbody tr:eq("+x+") td:eq(8) [type=text]").attr("name","Tconsoljrn["+(x+1)+"][curr_val]");
			$("#tableGen tbody tr:eq("+x+") td:eq(9) [type=text]").attr("name","Tconsoljrn["+(x+1)+"][ledger_nar]");
			
		}
				//Looping kedua untuk menentukan mana record yang dapat di-cancel dan mana row yang dapat di-delete
		for(x=0;x<rowCount;x++)
   		{
   			if($("[name='Tconsoljrn["+(x+1)+"][cancel_flg]']").val())
				$("#tableGen tbody tr:eq("+x+") td:eq(10) a:eq(0)").attr('onClick',"cancel(this,'"+$("[name='Tconsoljrn["+(x+1)+"][cancel_flg]']").val()+"',"+(x+1)+")")		
   			else
   			{
   				$("#tableGen tbody tr:eq("+x+") td:eq(10) a:eq(0)").attr('onClick',"deleteRow(this)");
   			}
   		}
}

function changeAll()
	{
		if($("#checkBoxAll").is(':checked'))
		{
			$(".checkBoxDetail").prop('checked',true);
		}
		else
		{
			$(".checkBoxDetail").prop('checked',false);
		}
	}
	
	function rowControl(obj)
	{
		var x = $(obj).closest('tr').prevAll().length;
		if(!$(obj).is(':checked') && $("#tableGen tbody tr:eq("+x+") td:eq(4) [type=hidden]").val())resetValue(obj,x); // Reset Value when the checkbox is unchecked and the row contains an existing record
		$("#tableGen tbody tr:eq("+x+")").attr("id","row"+(x+1));	
		
		$("#tableGen tbody tr:eq("+x+") td:eq(1) [type=text]").attr("readonly",!$(obj).is(':checked')?true:false);
		$("#tableGen tbody tr:eq("+x+") td:eq(2) [type=text]").attr("readonly",!$(obj).is(':checked')?true:false);
		$("#tableGen tbody tr:eq("+x+") td:eq(3) [type=text]").attr("readonly",!$(obj).is(':checked')?true:false);
		$("#tableGen tbody tr:eq("+x+") td:eq(4) select").attr("readonly",!$(obj).is(':checked')?true:false);
		$("#tableGen tbody tr:eq("+x+") td:eq(5) [type=text]").attr("readonly",!$(obj).is(':checked')?true:false);
		$("#tableGen tbody tr:eq("+x+") td:eq(6) [type=text]").attr("readonly",!$(obj).is(':checked')?true:false);
		$("#tableGen tbody tr:eq("+x+") td:eq(7) select").attr("readonly",!$(obj).is(':checked')?true:false);
		$("#tableGen tbody tr:eq("+x+") td:eq(8) [type=text]").attr("readonly",!$(obj).is(':checked')?true:false);
		$("#tableGen tbody tr:eq("+x+") td:eq(9) [type=text]").attr("readonly",!$(obj).is(':checked')?true:false);
		
		if(!$(obj).is(':checked') && $(obj).closest('tr').hasClass('markCancel'))$(obj).closest('tr').find('td:eq(10) a:eq(0)').trigger('click'); //unmark the row for cancellation if the checkbox is unchecked
	}
	cancel_reason();
	function cancel_reason()
	{
		var cancel_reason = false;
		
		for(x=0;x<rowCount;x++)
		{
			if($("#row"+(x+1)).hasClass('markCancel'))
			{
				cancel_reason = true;
				break;
			}
		}
		
		if(cancel_reason)$(".cancel_reason, .temp").show().attr('disabled',false)
		else
			$(".cancel_reason, .temp").hide().attr('disabled',true);
	}
	function cancel(obj, cancel_flg, seq)
	{ 
		if(authorizedCancel)
		{
			$(obj).closest('tr').attr('class',cancel_flg=='N'?'markCancel':''); 
			$('[name="Tconsoljrn['+seq+'][cancel_flg]"]').val(cancel_flg=='N'?'Y':'N'); 
			$(obj).attr('onClick',cancel_flg=='N'?"cancel(this,'Y',"+seq+")":"cancel(this,'N',"+seq+")");
			
			$("#tableGen tbody tr:eq("+(seq-1)+") td:eq(0) [type=checkbox]").prop('checked',cancel_flg=='N'?true:false).trigger('change'); //check or uncheck the checkbox
			
			cancel_reason();
		}
		else
			alert('You are not authorized to perform this action');	
		}
</script>
