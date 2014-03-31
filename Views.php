<?php namespace components\webhistory; if(!defined('TX')) die('No direct access.');

class Views extends \dependencies\BaseViews
{

  protected
    $permissions = array(
      'app' => 0,
      'entries' => 1,
      'email_template' => 0,
      'email_user_invited' => 0
    );

  protected function admin_stats($options)
  {

    return array(

      'accounts_by_login_date' => $this

        ->table('Entries')
        ->select('COUNT(*)', 'num_entries')

        ->join('Accounts', $account)
        ->select("$account.email", 'email')

        ->where("$account.id", '!', 'NULL')

        ->group('user_id')
        ->order('num_entries', 'DESC')

        ->execute(),

      'new_users' => $this

        ->section('admin_stats__new_users_chart')

    );

  }

  protected function app($options)
  {

    $only_if_authorised = (tx('Account')->user->level->get() >= 1 ? array(
      'entry_edit' => $this->section('entry_edit'),
      'summary' => $this->section('summary'),
      'uservoice_widget' => $this->module('uservoice_widget')
    ) : array());

    return Data(array(
      'intro' => $this->section('intro')
    ))->merge($only_if_authorised);
    
  }

  protected function entries($options)
  {

    return array(
      'edit_entry' => $this->section('edit_entry'),
      'admin_toolbar' => (tx('Component')->available('cms') ? tx('Component')->sections('cms')->get_html('admin_toolbar') : false)
    );

  }
  
  protected function email_template($options){
    return $options;
  }

  protected function email_user_invited($options){
    return $options;
  }

}
