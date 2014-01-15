<?php namespace components\webhistory; if(!defined('TX')) die('No direct access.');

class Actions extends \dependencies\BaseComponent
{

  protected $permissions = array(
    'save_entry' => 1,
    'delete_item' => 1
  );

  protected function save_entry($data)
  {
    
    $entry_id = 0;
    $data->screenshot_image_id = ($data->screenshot_image_id->get() > 0 ? $data->screenshot_image_id : null);
    tx($data->id->get('int') > 0 ? 'Updating a entry.' : 'Adding a new entry', function()use($data, &$entry_id){
      
      //Append user object for easy access.
      $user_id = tx('Data')->session->user->id;
      
      //Save entry.
      $entry = tx('Sql')->table('webhistory', 'Entries')->pk($data->id->get('int'))->execute_single()->is('empty')
        ->success(function()use($data, $user_id, &$entry_id){
          $entry_id = tx('Sql')->model('webhistory', 'Entries')->merge($data->having('url', 'title', 'tags', 'quotes', 'notes', 'location', 'context', 'song', 'screenshot_image_id'))->merge(array('user_id' => $user_id, 'dt_created' => date("Y-m-d H:i:s")))->save()->id;
        })
        ->failure(function($item)use($data, $user_id, &$entry_id){
          $item->merge($data->having('url', 'title', 'tags', 'quotes', 'notes', 'location', 'context', 'song', 'screenshot_image_id'))->merge(array('dt_last_modified', date("Y-m-d H:i:s")))->save();
          $entry_id = $item->id;
        });

    })
    
    ->failure(function($info){
      throw $info->exception;
    });

    //Delete all tag links for this item.
    tx('Sql')->query("DELETE FROM #__webhistory__entries_to_tags WHERE entry_id = ".$entry_id->get('int'));

    //Loop given tags.
    $sort = 1;
    Data(explode(',', $data->tags->get()))->each(function($tag)use($entry_id, &$sort){

      //Trim spaces und so.      
      $tag = trim($tag->get());

      //Check if tag exists in database.
      tx('Sql')->table('webhistory', 'Tags')->where('title', "'".$tag."'")->execute_single()->is('empty')

        //If not: insert tag.
        ->success(function()use($tag, &$tag_id){
          $tag_id = tx('Sql')->model('webhistory', 'Tags')->set(array('title' => $tag))->save()->id;
        })
        //If tag exists: get tag_id.
        ->failure(function($r)use(&$tag_id){
          $tag_id = $r->id;
        });

      //Now save taglink.
      tx('Sql')->query("INSERT #__webhistory__entries_to_tags (entry_id, tag_id, sort) VALUES ({$entry_id}, {$tag_id}, {$sort})");

      $sort++;

    });

    tx('Url')->redirect(url('', true));
    
  }

  protected function delete_item($data)
  {
    
    tx('Sql')->table('webhistory', 'Entries')
      ->pk($data->entry_id)
      ->where('user_id', tx('Account')->user->id)
      ->execute_single()
      ->is('empty', function()use($data){
        throw new \exception\User('Could not delete this item, because no entry was found in the database with id %s.', $data->id);
      })
      ->delete();
   
    tx('Url')->redirect(url('', true));
  
  }
 

}
