<?php namespace components\webhistory\models; if(!defined('TX')) die('No direct access.');

class Accounts extends \dependencies\BaseModel
{
  
  protected static
    
    $table_name = 'core_users',
    
    $relations = array(
      'UserInfo' => array('id' => 'Account.UserInfo.user_id'),
      'Entries' => array('id' => 'Entries.user_id')
    );
  
  public function get_is_administrator(){
    return $this->level->get('int') == 2;
  }
  
  public function get_user_info(){
    return tx('Sql')->table('account', 'UserInfo')->where('user_id', $this->id)->execute_single();
  }

  public function get_friends_ids()
  {

    $ret = array();

    tx('Sql')
      ->table('webhistory', 'Friends')
      ->where('user_id', $this->id)
      ->execute()
      ->each(function($row)use(&$ret){
        $ret[] = $row->friend_id->get();
      });

    return $ret;

  }
  
}

