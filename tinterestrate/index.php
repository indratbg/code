<?php
$this->breadcrumbs=array(
	'Tinterestrates'=>array('index'),
	'List',
);

$this->menu=array(
	array('label'=>'Tinterestrate', 'itemOptions'=>array('class'=>'nav-header')),
	array('label'=>'List','url'=>array('index'),'icon'=>'list','itemOptions'=>array('class'=>'active')),
	//array('label'=>'Create','url'=>array('create'),'icon'=>'plus'),
);

Yii::app()->clientScript->registerScript('search', "
$('.search-button').click(function(){
	$('.search-form').toggle();
	return false;
});
$('.search-form form').submit(function(){
	$.fn.yiiGridView.update('tinterestrate-grid', {
		data: $(this).serialize()
	});
	return false;
});
");
?>

<h1>List of Latest Interest Rate</h1>

<?php echo CHtml::link('Advanced Search','#',array('class'=>'search-button btn')); ?>
<div class="search-form" style="display:none">
<?php $this->renderPartial('_search',array(
	'model'=>$model,
)); ?>
</div><!-- search-form -->

<?php AHelper::showFlash($this) ?> <!-- show flash -->

<?php $this->widget('bootstrap.widgets.TbGridView',array(
	'id'=>'tinterestrate-grid',
    'type'=>'striped bordered condensed',
	'dataProvider'=>$model->search(),
	'filter'=>$model,
    'filterPosition'=>'',
	'columns'=>array(
		'branch_code',
		'client_cd',
		'client_name',
		'old_ic_num',
		'ar',
		'ap',
		array('name'=>'eff_dt','type'=>'date'),
		'cl_desc',
		'obs',
		//'interest_type',
		array(
			'class'=>'bootstrap.widgets.TbButtonColumn',
			'template'=>'{view} {update}',
			'updateButtonUrl'=>'Yii::app()->createUrl("finance/tinterestrate/update",$data->getPrimaryKey())',
			'viewButtonUrl'=>'Yii::app()->createUrl("finance/tinterestrate/view",$data->getPrimaryKey())',
		),
	),
)); ?>
