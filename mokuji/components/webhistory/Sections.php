<?php namespace components\webhistory; if(!defined('TX')) die('No direct access.');

class Sections extends \dependencies\BaseViews
{

  protected
    $permissions = array(
      'intro' => 0,
      'summary' => 1,
      'entry_list' => 1,
      'entry_edit' => 0,
      'entry_edit' => 0,
      'ejs_list_entry' => 0,
      'ejs_full_entry' => 0
    );

  protected function intro(){
  }

  protected function entry_edit(){

    return array(
      'entry' => ( tx('Data')->get->id->gt(0) ? $this->table('Entries')->where('id', tx('Data')->get->id)->where('user_id', tx('Account')->user->id)->execute_single() : Data() )
    );

  }

  protected function ejs_list_entry(){}
  protected function ejs_full_entry(){}
 
  protected function summary()
  {

    $ret = Data(array(
      'tag_cloud' => $this->module('tag_cloud'),
      'num_of_entries' => $this->helper('query_entries')->select('COUNT(*)', 'num')->group('user_id')->execute_single()->num,
      'user_entry_count' => $this->helper('query_entries', array('all_users' => true))->select('COUNT(*)', 'num')->group('user_id')->order('num', 'DESC')->execute()
    ));

    return $ret;

  }

}

