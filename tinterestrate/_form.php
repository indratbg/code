<style>
	#tableInt
	{
		background-color:#C3D9FF;
	}
	#tableInt thead, #tableInt tbody
	{
		display:block;
	}
	#tableInt tbody
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


<?php $form=$this->beginWidget('bootstrap.widgets.TbActiveForm',array(
	'id'=>'tinterestrate-form',
	'enableAjaxValidation'=>false,
	'type'=>'horizontal'
)); ?>

	<p class="help-block">Fields with <span class="required">*</span> are required.</p>

	<?php echo $form->errorSummary($modelClient); ?>
	
	<?php 
		foreach($model as $row)
			echo $form->errorSummary(array($row)); 
	?>
	
	<?php 
		foreach($oldModel as $row)
			echo $form->errorSummary(array($row)); 
	?>
	
	<?php echo $form->textFieldRow($modelClient,'client_cd',array('class'=>'span2','disabled'=>'disabled')); ?>
	<?php echo $form->textFieldRow($modelClient,'client_name',array('class'=>'span5','disabled'=>'disabled')); ?>
	
	<div class="row-fluid">
		<div class="span4">
			<?php echo $form->textFieldRow($modelClient,'branch_code',array('class'=>'span3','disabled'=>'disabled')); ?>
		</div>
		<div class="span8">
			<div class="span1">
				<?php echo $form->label($modelClient,'Client Type',array('for'=>'clientType','class'=>'control-label')) ?>
			</div>
			<div class="span2">
				<?php echo $form->textFieldRow($modelClient,'client_type',array('class'=>'span','id'=>'clientType','disabled'=>'disabled','label'=>false,'value'=>$modelClient->client_type_1.$modelClient->client_type_2.$modelClient->client_type_3)); ?>
			</div>
			<?php echo $form->textField($modelClient,'Client Type',array('class'=>'span3','disabled'=>'disabled','value'=>Lsttype3::model()->find("cl_type3 = '$modelClient->client_type_3'")->cl_desc)); ?>
		</div>
	</div>
<!--	
	<br/><br/>
	
	<?php echo $form->textFieldRow($modelClient,'Client Type',array('class'=>'span3','disabled'=>'disabled','value'=>Lsttype3::model()->find("cl_type3 = '$modelClient->client_type_3'")->cl_desc)); ?>
-->	
	<div class="row-fluid">
		<div class="span4">
			<?php echo $form->label($modelClient,'Calculation Mode',array('class'=>'control-label')) ?>
			<?php echo $form->radioButtonListInlineRow($modelClient,'amt_int_flg',array('Y'=>'System','N'=>'Manual'),array('label'=>false)) ?>
		</div>
		<div class="span4">
			<div class="span4">
				<?php echo $form->label($modelClient,'Interest Type',array('class'=>'control-label')) ?>
			</div>
			<?php echo $form->radioButtonListInlineRow($modelClient,'int_accumulated',array('Y'=>'Majemuk','N'=>'Tunggal'),array('label'=>false)) ?>
		</div>
	</div>
	
	<div class="row-fluid">
		<div class="span4">
		<label class="control-label">AR Days</label>
			<?php echo $form->textFieldRow($modelClient,'int_rec_days',array('class'=>'span3','disabled'=>'disabled','label'=>false,'style'=>'text-align:right')); ?>
		</div>
		<div class="span4">
			<div class="span4">
				<label class="control-label">AP Days</label>
			</div>
		<?php echo $form->textFieldRow($modelClient,'int_pay_days',array('class'=>'span3','disabled'=>'disabled','label'=>false,'style'=>'text-align:right')); ?>
		</div>
	</div>
	
	<div class="row-fluid">
		<div class="span2">
			<div class="span1">
				<label class="control-label">PPH23</label>
			</div>
			<?php echo $form->checkBoxListInlineRow($modelClient,'tax_on_interest',array('Y'=>''),array('id'=>'taxOnInterest','label'=>false)) ?>
		</div>
	</div>
	
	<br/><br/>
	
	<input type="hidden" id="rowCnt" name="rowCnt"/>
	
	<table id='tableInt' class='table-bordered table-condensed' style="width:90%;">
		<thead>
			<tr>
				<th width="5%"></th>
				<th width="15%">Client</th>
				<th width="15%">Effective Date</th>
				<th width="15%">AR</th>
				<th width="15%">AP</th>
				<th width="5%">
					<a style="cursor:pointer;" title="add" onclick="addRow()"><img src="<?php echo Yii::app()->request->baseUrl ?>/images/add.png"></a>
				</th>
			</tr>
		</thead>
		<tbody>
		<?php $x = 1;
			foreach($model as $row){ 
		?>
			<tr id="row<?php echo $x ?>">
				<td>
					<?php echo $form->checkBox($row,'save_flg',array('value' => 'Y','name'=>'Tinterestrate['.$x.'][save_flg]','onChange'=>$row->old_client_cd&&!$check[$x-1]->check?'rowControl(this,false)':'rowControl(this,true)')); ?>
				<?php if($row->old_client_cd): ?>
					<input type="hidden" name="Tinterestrate[<?php echo $x ?>][cancel_flg]" value="<?php echo $row->cancel_flg ?>"/>	
				<?php endif; ?>
				</td>
				<td>
					<?php echo $form->textField($row,'client_cd',array('class'=>'span','name'=>'Tinterestrate['.$x.'][client_cd]','readonly'=>!$model->isNewRecord&&$check[$x-1]&&!$check[$x-1]->check&&$row->old_client_cd && $row->save_flg=='Y'?'':'readonly')) ?>
					
				</td>
				<td><?php echo $form->textField($row,'eff_dt',array('class'=>'span','name'=>'Tinterestrate['.$x.'][eff_dt]','readonly'=>$row->save_flg !='Y'?'readonly':'')); ?>
					<input type="hidden" name="Tinterestrate[<?php echo $x ?>][old_eff_dt]" value="<?php echo $row->cancel_flg ?>"/>
				</td>
				
				<td><?php echo $form->textField($row,'int_on_receivable',array('class'=>'span tnumber','name'=>'Tinterestrate['.$x.'][int_on_receivable]','style'=>'text-align:right','readonly'=>$row->save_flg !='Y'?'readonly':'')); ?></td>
				<td><?php echo $form->textField($row,'int_on_payable',array('class'=>'span tnumber','name'=>'Tinterestrate['.$x.'][int_on_payable]','style'=>'text-align:right','readonly'=>$row->save_flg !='Y'?'readonly':'')); ?></td>
				
				<td>
					<a 
						title="<?php if($row->old_client_cd) echo 'cancel';else echo 'delete'?>" 
						onclick="<?php if($row->old_client_cd) echo 'checkCancel(this,\''.$row->cancel_flg.'\','.$x.')';else echo 'deleteRow(this)'?>">
						<img src="<?php echo Yii::app()->request->baseUrl ?>/images/delete.png">
					</a>
					</td>
			</tr>
		<?php $x++;} ?>
		</tbody>
	</table>
	
	
	
	
	<?php 
	if($model)
	{
?>
<?php if($model): ?>
	<?php echo $form->label($model[0], 'Cancel Reason', array('class'=>'control-label cancel_reason'))?>
	<textarea id="cancel_reason" class="span5 cancel_reason" name="cancel_reason" maxlength="200" rows="4" disabled><?php echo $cancel_reason ?></textarea>
<?php endif; ?>
<?php echo $form->datePickerRow($model[0],'cre_dt',array('label'=>false,'disabled'=>'disabled','style'=>'display:none','options'=>array('format' => 'dd/mm/yyyy'))); ?>

<?php
	} 
?>
	<div class="form-actions">
		<?php $this->widget('bootstrap.widgets.TbButton', array(
			'id'=>'btnSubmit',
			'buttonType'=>'submit',
			'type'=>'primary',
			'label'=>$modelClient->isNewRecord ? 'Create' : 'Save',
		)); ?>
	</div>

<?php $this->endWidget(); ?>

<script>
	var rowCount = <?php echo count($model) ?>;
	
	init();

	$("#btnSubmit").click(function()
	{
		assignHiddenValue();
	});
	
	function init()
	{
		var x;
		
		for(x=0;x<rowCount;x++)
		{
			$("#tableInt tbody tr:eq("+x+") td:eq(1) input").datepicker({format : "dd/mm/yyyy"});
		}
		cancel_reason();
	}

	function addRow()
	{
		$("#tableInt").find('tbody')
    		.prepend($('<tr>')
    			.attr('id','row0')
    			.append($('<td>')
				.append($('<input>')
					.attr('name','Treksnab[1][save_flg]')
					.attr('type','checkbox')
					.attr('onChange','rowControl(this,false)')
					.prop('checked',true)
					.val('Y')
				)
			)
        		.append($('<td>')
               		 .append($('<input>')
               		 	.attr('class','span')
               		 	.attr('type','text')
               		 	.attr('readonly','readonly')
               		 	.val('<?php echo $modelClient->client_cd ?>')
               		)
				).append($('<td>')
               		 .append($('<input>')
               		 	.attr('class','span')
               		 	.attr('name','Tinterestrate[0][eff_dt]')
               		 	.attr('type','text')
               		 	.datepicker({format : "dd/mm/yyyy"})
               		)
               	).append($('<td>')
               		 .append($('<input>')
               		 	.attr('class','span tnumber')
               		 	.attr('name','Tinterestrate[0][int_on_receivable]')
               		 	.attr('type','text')
               		 	.attr('onChange','addCommas(this)')
               		 	.css('text-align','right')
               		)
               	).append($('<td>')
               		 .append($('<input>')
               		 	.attr('class','span tnumber')
               		 	.attr('name','Tinterestrate[0][int_on_payable]')
               		 	.attr('type','text')
               		 	.attr('onChange','addCommas(this)')
               		 	.css('text-align','right')
               		)
               	).append($('<td>')
               		 .append($('<a>')
               		 	.attr('onClick','deleteRow()')
               		 	.attr('title','delete')
               		 	.append($('<img>')
               		 		.attr('src','<?php echo Yii::app()->request->baseUrl ?>/images/delete.png')
               		 	)
               		)
               		.css('cursor','pointer')
               	)  	
    		);
    	
    	rowCount++;
    	
    	reassignAttribute();
	}
	
	function deleteRow(obj)
	{
		$(obj).closest('tr').remove();
		rowCount--;
		reassignAttribute();
	}
	
	function addCommas(obj)
	{
		$(obj).val(setting.func.number.addCommas(setting.func.number.removeCommas($(obj).val())));
	}
	
	function assignHiddenValue()
	{
		$("#rowCnt").val(rowCount);
	}
	function rowControl(obj)
	{
		var x = $(obj).closest('tr').prevAll().length;
		
		$("#tableInt tbody tr:eq("+x+")").attr("id","row"+(x+1));	
		
		
		$("#tableInt tbody tr:eq("+x+") td:eq(2) [type=text]").attr("readonly",!$(obj).is(':checked')?true:false);
		$("#tableInt tbody tr:eq("+x+") td:eq(3) [type=text]").attr("readonly",!$(obj).is(':checked')?true:false);
		$("#tableInt tbody tr:eq("+x+") td:eq(4) [type=text]").attr("readonly",!$(obj).is(':checked')?true:false);
		
		
		if(!$(obj).is(':checked') && $(obj).closest('tr').hasClass('markCancel'))$(obj).closest('tr').find('td:eq(5) a:eq(0)').trigger('click'); //unmark the row for cancellation if the checkbox is unchecked
	}
	function reassignAttribute()
	{
		for(x = 0; x<rowCount; x++)
		{
			//Re-assign id untuk row agar urut sesuai dengan baris
			$("#tableInt tbody tr:eq("+x+")").attr("id","row"+(x+1));
			$("#tableInt tbody tr:eq("+x+") td:eq(0) [type=checkbox]").attr("name","Tinterestrate["+(x+1)+"][save_flg]");
			$("#tableInt tbody tr:eq("+x+") td:eq(0) [type=hidden]:eq(1)").attr("name","Tinterestrate["+(x+1)+"][cancel_flg]");
			$("#tableInt tbody tr:eq("+x+") td:eq(0) [type=hidden]:eq(0)").attr("name","Tinterestrate["+(x+1)+"][save_flg]");
			//Re-assign name untuk input field agar urut sesuai dengan baris
			$("#tableInt tbody tr:eq("+x+") td:eq(1) input").attr("name","Tinterestrate["+(x+1)+"][eff_dt]");
			$("#tableInt tbody tr:eq("+x+") td:eq(2) input").attr("name","Tinterestrate["+(x+1)+"][int_on_receivable]");
			$("#tableInt tbody tr:eq("+x+") td:eq(3) input").attr("name","Tinterestrate["+(x+1)+"][int_on_payable]");

			//Re-assign actual parameter untuk function agar urut sesuai dengan baris
			$("#tableInt tbody tr:eq("+x+") td:eq(4) a").attr("onClick","deleteRow("+(x+1)+")");
			
			$("#tableInt tbody tr:eq("+x+") td:eq(0) .old_pk").attr("name","old_pk_id"+(x+1));
			$("#tableInt tbody tr:eq("+x+") td:eq(0) .old_pk").attr("id","old_pk_id"+(x+1));
		}
			//Looping kedua untuk menentukan mana record yang dapat di-cancel dan mana row yang dapat di-delete
		for(x=0;x<rowCount;x++)
   		{
   			if($("[name='Tinterestrate["+(x+1)+"][cancel_flg]']").val())
				$("#tableInt tbody tr:eq("+x+") td:eq(5) a:eq(0)").attr('onClick',"cancel(this,'"+$("[name='Treksnab["+(x+1)+"][cancel_flg]']").val()+"',"+(x+1)+")")		
   			else
   			{
   				$("#tableInt tbody tr:eq("+x+") td:eq(5) a:eq(0)").attr('onClick',"deleteRow(this)");
   			}
   		}
	}
	$(window).resize(function() {
		var body = $("#tableInt").find('tbody');
		if(body.get(0).scrollHeight > body.height()) //check whether  tbody has a scrollbar
		{
			$('thead').css('width', '100%').css('width', '-=17px');	
		}
		else
		{
			$('thead').css('width', '100%');	
		}
		
		alignColumn();
	})
	$(window).trigger('resize');
	
	function alignColumn()//align columns in thead and tbody
	{
		var header = $("#tableInt").find('thead');
		var firstRow = $("#tableInt").find('tbody tr:eq(0)');
		
		firstRow.find('td:eq(0)').css('width',header.find('th:eq(0)').width() + 'px');
		firstRow.find('td:eq(1)').css('width',header.find('th:eq(1)').width() + 'px');
		firstRow.find('td:eq(2)').css('width',header.find('th:eq(2)').width() + 'px');
		firstRow.find('td:eq(3)').css('width',header.find('th:eq(3)').width() + 'px');
		firstRow.find('td:eq(4)').css('width',header.find('th:eq(4)').width() + 'px');
		firstRow.find('td:eq(5)').css('width',header.find('th:eq(5)').width() + 'px');
		firstRow.find('td:eq(6)').css('width',header.find('th:eq(6)').width() + 'px');
		
	}
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
		
		if(cancel_reason)$(".cancel_reason, #temp").show().attr('disabled',false)
		else
			$(".cancel_reason, #temp").hide().attr('disabled',true);
	}
	function cancel(obj, cancel_flg, seq)
	{
		
			$(obj).closest('tr').attr('class',cancel_flg=='N'?'markCancel':''); 
			$('[name="Tinterestrate['+seq+'][cancel_flg]"]').val(cancel_flg=='N'?'Y':'N'); 
			$(obj).attr('onClick',cancel_flg=='N'?"cancel(this,'Y',"+seq+")":"cancel(this,'N',"+seq+")");
			
			$("#tableInt tbody tr:eq("+(seq-1)+") td:eq(0) [type=checkbox]").prop('checked',cancel_flg=='N'?true:false).trigger('change'); //check or uncheck the checkbox
			
			cancel_reason();
		}
		
		
	}
	
</script>