<?php namespace components\webhistory; if(!defined('TX')) die('No direct access.');

class Json extends \dependencies\BaseComponent
{
  
  protected
    $default_permission = 1,
    $permissions = array(
    );
  
  public function get_entries($options, $sub_routes)
  {
    
    //Fetch one.
    if($sub_routes->{0}->is_set()){
      
      return mk('Sql')->table('webhistory', 'Entries')
        ->pk($sub_routes->{0}->get('int'))
        ->where('user_id', mk('Account')->user->id)
        ->execute_single()
        ->is('set', function($entry){
          $entry->tags;
          $entry->rawTags;
        });
      
    }
    
    //Fetch all, or search.
    else{
      
      return mk('Sql')->table('webhistory', 'Entries', $E)
        ->where('user_id', mk('Account')->user->id)
        
        //Search functionality.
        ->is($options->search->is('set')->and_not('empty'), function($q)use($E, $options){
          
          $search = str_replace(',', '|', $options->search->get());
          $search = str_replace(' ', '|', $search);
          
          $q
          ->join('TagLink', $TL)->left()
          ->workwith($TL)
          ->join('Tags', $T)->inner()
          ->workwith($E)
          
          ->where(tx('Sql')->conditions()
            ->add('1', array("$T.title", '', "REGEXP('".$search."')" ))
            ->add('2', array("$E.url", '', "REGEXP('".$search."')" ))
            ->add('3', array("$E.title", '', "REGEXP('".$search."')" ))
            ->add('4', array("$E.notes", '', "REGEXP('".$search."')" ))
            ->combine('combined', array('1', '2', '3', '4'), 'OR')
            ->utilize('combined'));
          
        })
        
        ->order('dt_created', 'DESC')
        ->group("$E.id")
        ->limit(100)
        ->execute()
        ->each(function($entry){
          $entry->tags;
          $entry->rawTags;
        });
      
    }
    
  }
  
  public function post_entries($data, $sub_routes, $options)
  {
    
    $user_id = mk('Account')->user->id;
    
    $model = mk('Sql')->model('webhistory', 'Entries')
      ->merge($data->having('url', 'title', 'notes'))
      ->merge(array('user_id' => $user_id, 'dt_created' => date("Y-m-d H:i:s")))
      ->save();
    
    $tags = explode(',', $data->rawTags->get());
    $sort = 1;
    foreach($tags as $tag){
      
      $tag = trim($tag);
      if(empty($tag)) continue;
      
      //Check if tag exists in database.
      mk('Sql')->table('webhistory', 'Tags')->where('title', mk('Sql')->escape($tag))->execute_single()->is('empty')
        
        //If not: insert tag.
        ->success(function()use($tag, &$tag_id){
          $tag_id = tx('Sql')->model('webhistory', 'Tags')->set(array('title' => $tag))->save()->id;
        })
        
        //If tag exists: get tag_id.
        ->failure(function($r)use(&$tag_id){
          $tag_id = $r->id;
        });
      
      //Now save the tag-link.
      mk('Sql')->model('webhistory', 'TagLink')->merge(array('entry_id'=>$model->id, 'tag_id'=>$tag_id, 'sort'=>$sort))->save();
      
      $sort++;
      
    }
    
    $model->tags;
    $model->rawTags;
    
    return $model;
    
  }
  
  public function put_entries($data, $sub_routes, $options)
  {
    
    $user_id = mk('Account')->user->id;
    
    $model = mk('Sql')->table('webhistory', 'Entries')
      ->pk($sub_routes->{0})
      ->where('user_id', mk('Account')->user->id)
      ->execute_single()
      ->is('empty', function(){
        throw new \exception\NotFound('No entry with this ID.');
      })
      
      ->merge($data->having('url', 'title', 'notes'))
      ->save();
    
    //Delete existing tags.
    mk('Sql')->table('webhistory', 'TagLink')
      ->where('entry_id', $model->id)
      ->execute()
      ->each(function($link){
        $link->delete();
      });
    
    $tags = explode(',', $data->rawTags->get());
    $sort = 1;
    foreach($tags as $tag){
      
      $tag = trim($tag);
      if(empty($tag)) continue;
      
      //Check if tag exists in database.
      mk('Sql')->table('webhistory', 'Tags')->where('title', mk('Sql')->escape($tag))->execute_single()->is('empty')
        
        //If not: insert tag.
        ->success(function()use($tag, &$tag_id){
          $tag_id = tx('Sql')->model('webhistory', 'Tags')->set(array('title' => $tag))->save()->id;
        })
        
        //If tag exists: get tag_id.
        ->failure(function($r)use(&$tag_id){
          $tag_id = $r->id;
        });
      
      //Now save the tag-link.
      mk('Sql')->model('webhistory', 'TagLink')->merge(array('entry_id'=>$model->id, 'tag_id'=>$tag_id, 'sort'=>$sort))->save();
      
      $sort++;
      
    }
    
    $model->tags;
    $model->rawTags;
    
    return $model;
    
  }
  
  public function delete_entries($options, $sub_routes)
  {
    
    //Fetch one.
    if(!$sub_routes->{0}->is_set())
      throw new \exception\NotFound('No ID given.');
    
    mk('Sql')->table('webhistory', 'Entries')
      ->pk($sub_routes->{0}->get('int'))
      ->where('user_id', mk('Account')->user->id)
      ->execute_single()
      ->is('empty', function(){
        throw new \exception\NotFound('No item found with this ID.');
      })
      ->delete();
    
  }
  
  public function get_tags($options, $sub_routes)
  {
    
    //Fetch one.
    if($sub_routes->{0}->is_set()){
      
      return mk('Sql')->table('webhistory', 'Tags')
        ->pk($sub_routes->{0}->get('int'))
        ->where('user_id', mk('Account')->user->id)
        ->execute_single()
        ->is('set', function($entry){
          $entry->tags;
          $entry->rawTags;
        });
      
    }
    
    //Fetch all, or search.
    else{
      
      return mk('Sql')

        ->table('webhistory', 'TagLink', $link)
        ->select('COUNT(*)', 'num')

        ->join('Entries', $entry)
        ->select("$entry.user_id", 'user_id')
        ->where("$entry.user_id", mk('Account')->user->id)

        ->join('Tags', $tag)
        ->select("$tag.title", 'title')
        
        //Search functionality.
        ->is($options->search->is('set')->and_not('empty'), function($q)use($options){
          
          $search = str_replace(',', '|', $options->search->get());
          $search = str_replace(' ', '|', $search);
          
          $q
          ->join('TagLink', $TL)->left()
          ->workwith($TL)
          ->join('Tags', $T)->inner()
          ->workwith($E)
          
          ->where(tx('Sql')->conditions()
            ->add('1', array("$T.title", '', "REGEXP('".$search."')" ))
            ->add('2', array("$E.url", '', "REGEXP('".$search."')" ))
            ->add('3', array("$E.title", '', "REGEXP('".$search."')" ))
            ->add('4', array("$E.notes", '', "REGEXP('".$search."')" ))
            ->combine('combined', array('1', '2', '3', '4'), 'OR')
            ->utilize('combined'));
          
        })
        
        ->group('tag_id')
        ->order('num', 'DESC')
        ->limit(75)

        ->execute();
      
    }
    
  }
  
  // /* ---------- Frontend ---------- */

  // public function get_entries($data, $args)
  // {

  //   $self = $this;

  //   tx('Fetching entries.', function()use($self, $data, $args, &$result){

  //     $list_friends = Data(false);

  //     $search = $args[0];

  //     if(strpos($search, 'list::friends') !== false){
  //       $list_friends->set(true);
  //     }

  //     $search = str_replace('list::friends', '', $search);
  //     $search = Data(trim($search));

  //     $result = $self->table('Entries', $entry)

  //     ->is($list_friends->is('set')->and_is('true'), function($q){

  //       $friend_ids = tx('Sql')->table('webhistory', 'Accounts')->where('id', tx('Account')->user->id)->execute_single()->friends_ids;
  //       $q->where('user_id', 'IN', $friend_ids);

  //     })->failure(function($q){
  //       $q->where('user_id', tx('Account')->user->id);
  //     })

  //     ->is($search->is('set')->and_not('empty'), function($q)use($entry, $search){

  //       $search = str_replace(',', '|', $search);
  //       $search = str_replace(' ', '|', $search);

  //       $q
  //       ->join('TagLink', $taglink)->left()
  //       ->workwith($taglink)
  //       ->join('Tags', $tag)->inner()
  //       ->workwith($entry)

  //       ->where(tx('Sql')->conditions()
  //         ->add('1', array("$tag.title", '', "REGEXP('".$search."')" ))
  //         ->add('2', array("$entry.url", '', "REGEXP('".$search."')" ))
  //         ->add('3', array("$entry.title", '', "REGEXP('".$search."')" ))
  //         ->add('4', array("$entry.notes", '', "REGEXP('".$search."')" ))
  //         ->combine('combined', array('1', '2', '3', '4'), 'OR')
  //         ->utilize('combined'));

  //     })

  //     ->order('dt_created', 'DESC')
  //     ->group("$entry.id")
  //     ->limit(100)
  //     ->execute()
  //     ->each(function($row){
  //       $row->tags;
  //     });

  //   });

  //   return $result;

  // }

}
