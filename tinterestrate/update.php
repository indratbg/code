<?php
$this->breadcrumbs=array(
	'Tinterestrates'=>array('index'),
	$modelClient->client_cd=>array('view','id'=>$modelClient->client_cd),
	'Update',
);

$this->menu=array(
	array('label'=>'Tinterestrate', 'itemOptions'=>array('class'=>'nav-header')),
	array('label'=>'List','url'=>array('index'),'icon'=>'list'),
	//array('label'=>'Create','url'=>array('create'),'icon'=>'plus'),
	array('label'=>'View','url'=>array('view','client_cd'=>$modelClient->client_cd,'eff_dt'=>''),'icon'=>'eye-open'),
);
?>

<h1>Update Interest Rate</h1>


<?php AHelper::applyFormatting() ?> <!-- apply formatting to date and number -->
<?php AHelper::showFlash($this) ?> <!-- show flash -->
<?php echo $this->renderPartial('_form',array('model'=>$model,'modelClient'=>$modelClient,'oldModel'=>$oldModel,'oldPkId'=>$oldPkId,'cancel_reason'=>$cancel_reason)); ?>