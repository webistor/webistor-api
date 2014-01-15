<?php namespace components\webhistory; if(!defined('TX')) die('No direct access.');

class Modules extends \dependencies\BaseViews
{

  protected
    $default_permission = 2,
    $permissions = array(
      'tag_cloud' => 1,
      'uservoice_widget' => 1
    );

  protected function tag_cloud()
  {

    return array(

      'tags' => $this

        ->table('TagLink')
        ->select('COUNT(*)', 'num')

        ->join('Entries', $entry)
        ->select("$entry.user_id", 'user_id')

        ->join('Tags', $tag)
        ->select("$tag.title", 'title')

        ->where("$entry.user_id", "'".tx('Account')->user->id."'")
        ->group('tag_id')
        ->order('num', 'DESC')
        ->limit('25')

        ->execute()

    );

  }

  protected function uservoice_widget()
  {
    
    $user_info = tx('Sql')->table('account', 'UserInfo')
      ->pk(tx('Account')->user->id->get('int'))
      ->execute_single();

    $user_account = $user_info->account;

    return array(
      'email' => $user_account->email, // User’s email address
      'name' => $user_account->username, // User’s real name
      'created_at' => strtotime($user_account->dt_created), // Unix timestamp for the date the user signed up
      'id' => $user_account->id // Optional: Unique id of the user (if set, this should not change)
    );

  }

}
