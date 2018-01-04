<?php $form=$this->beginWidget('bootstrap.widgets.TbActiveForm',array(
	'action'=>Yii::app()->createUrl($this->route),
	'method'=>'get',
	'type'=>'horizontal'
)); ?>

<h4>Primary Attributes</h4>
	<?php echo $form->textFieldRow($model,'client_cd',array('class'=>'span3','maxlength'=>12)); ?>
	<div class="control-group">
		<?php echo $form->label($model,'eff_dt',array('class'=>'control-label')); ?>
		<div class="controls">
			<?php echo $form->textField($model,'eff_dt_date',array('maxlength'=>'2','class'=>'span1','placeholder'=>'dd')); ?>
			<?php echo $form->textField($model,'eff_dt_month',array('maxlength'=>'2','class'=>'span1','placeholder'=>'mm')); ?>
			<?php echo $form->textField($model,'eff_dt_year',array('maxlength'=>'4','class'=>'span1','placeholder'=>'yyyy')); ?>
		</div>
	</div>
	
	<?php echo $form->textFieldRow($model,'branch_code',array('class'=>'span3','maxlength'=>3)); ?>
	
	<?php echo $form->dropDownListRow($model,'cl_desc',CHtml::listData(array_merge(array('0'=>array('cl_desc'=>'ALL','cl_type3'=>'')),Lsttype3::model()->findAll(array('select'=>'cl_desc, cl_desc AS cl_type3'))),'cl_type3','cl_desc')); ?>
	
	<?php echo $form->textFieldRow($model,'ar',array('class'=>'span2')); ?>
	<?php echo $form->textFieldRow($model,'ap',array('class'=>'span2')); ?>

	<div class="form-actions">
		<?php $this->widget('bootstrap.widgets.TbButton', array(
			'buttonType' => 'submit',
			'type'=>'primary',
			'label'=>'Search',
		)); ?>
	</div>

<?php $this->endWidget(); ?>
