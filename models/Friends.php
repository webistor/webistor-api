<?php namespace components\webhistory\models; if(!defined('TX')) die('No direct access.');

class Friends extends \dependencies\BaseModel
{

  protected static

    $table_name = 'webhistory__friends',

    $relations = array(
      'Accounts'=>array('user_id' => 'Accounts.id'),
      'Friends'=>array('friend_id' => 'Accounts.id')
    );

}
