<?php namespace components\webhistory\models; if(!defined('TX')) die('No direct access.');

class Entries extends \dependencies\BaseModel
{

  protected static

    $table_name = 'webhistory__entries',
  
    $relations = array(
      'TagLink' => array('id' => 'TagLink.entry_id'),
      'Accounts' => array('user_id' => 'Accounts.id')
    );

  public function get_tags()
  {
    
    return $this->table('Tags')
      ->join('TagLink', $taglink)
      ->where("$taglink.entry_id", $this->id)
      ->order("$taglink.sort", 'ASC')
      ->execute();

  }
  
  public function get_rawTags()
  {
    
    return $this->tags->map(function($tag){
      return $tag->title;
    })->join(', ');
    
  }

  public function get_user()
  {
    
    return $this->table('Accounts')
      ->where('id', $this->user_id)
      ->execute_single();

  }

  public function get_screenshot()
  {

    if(!tx('Component')->available('media'))
      return false;
    
    $image = tx('Sql')
      ->table('media', 'Images')
      ->pk($this->screenshot_image_id)
      ->execute_single();
    
    if($image->is_empty())
      return false;

    return $image;

  }

}
