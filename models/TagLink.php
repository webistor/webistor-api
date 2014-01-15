<?php namespace components\webhistory\models; if(!defined('TX')) die('No direct access.');

class TagLink extends \dependencies\BaseModel
{

  protected static

    $table_name = 'webhistory__entries_to_tags',

    $relations = array(
      'Entries'=>array('entry_id' => 'Entries.id'),
      'Tags'=>array('tag_id' => 'Tags.id')
    );

}
