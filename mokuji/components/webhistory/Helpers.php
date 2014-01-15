<?php namespace components\webhistory; if(!defined('TX')) die('No direct access.');

class Helpers extends \dependencies\BaseComponent
{
  
  protected
    $permissions = array(
      'get_users' => 2,
      'get_categories' => 2,
      'query_entries' => 1
    );

  public function get_users($user_id = null)
  {
  
    return $this
      ->table('Accounts')
      ->order('username')
      ->execute();
    
  }

  public function get_categories($category_id = null)
  {
  
    return $this
      ->table('Categories')
      ->order('title')
      ->execute();
    
  }
  
  public function query_entries($options = null)
  {
  
    $options = Data($options);

    $q = $this
      ->table('Entries')
      ->is($options->all_users->is('false'), function($q){
        $q->where('user_id', tx('Account')->user->id);
      });

    return $q;

  }

}
