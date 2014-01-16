<?php namespace components\webhistory\models; if(!defined('TX')) die('No direct access.');

class Tags extends \dependencies\BaseModel
{

  protected static

    $table_name = 'webhistory__tags',

    $relations = array(
      'TagLink'=>array('id' => 'TagLink.tag_id'),
      'Entries'=>array('id' => 'TagLink.tag_id')
    );

}
