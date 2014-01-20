<?php namespace components\webhistory; if(!defined('TX')) die('No direct access.');

//Make sure we have the things we need for this class.
mk('Component')->check('update');

class DBUpdates extends \components\update\classes\BaseDBUpdates
{
  
  protected
    $component = 'webhistory',
    $updates = array(
      '0.1' => '0.2',
      '0.2' => '0.3',
      '0.3' => '0.4'
    );
  
  //Update to v0.4
  public function update_to_0_4($dummydata, $forced)
  {

    $debug = false;

    // Add `user_id` column to `tags` table.
    mk('Sql')->query('
      ALTER TABLE `#__webhistory__tags`
        ADD COLUMN `user_id` INT(10) NOT NULL AFTER `id`;
    ');

    //Set user id for entries that existed
    // before this table modification.
    if($debug) echo "<h1>Tags:</h1>";

    tx('Sql')
      ->table('webhistory', 'Tags')
      ->where('user_id', 0)
      ->execute()

      //Loop tags without a value for `user_id`.
      ->each(function($tag){

        if($debug) echo "<h2>Tag: {$tag->title}</h2>";
        if($debug) trace($tag->dump());

        //Get the users who are using this tag.
        tx('Sql')
          ->table('webhistory', 'TagLink')
          ->join('Entries', $entry)
          ->select("$entry.user_id", 'user_id')
          ->where('tag_id', $tag->id->get())
          ->where("$entry.user_id", '!', 'NULL')
          ->group("$entry.user_id")
          ->execute()

          //Loop all users who use this tag
          // and link them to the [existing|new] tag.
          ->each(function($user_who_uses_this_tag)use(&$tag){

            if($debug) echo "<h3>User who uses this tag: {$user_who_uses_this_tag->user_id}</h3>";
            if($debug) trace($user_who_uses_this_tag->dump());

            //If the existing tag isn't linked to a user yet.
            if($tag->user_id->get() == 0){
              
              //Link this tag to the user.
              $tag->user_id->set($user_who_uses_this_tag->user_id->get());
              $tag->save();

            }

            //Or else: add a new tag for this user.
            else{

              //Create new tag.
              $new_tag = tx('Sql')
                ->model('webhistory', 'Tags')
                ->set(array(
                  'user_id' => $user_who_uses_this_tag->user_id->get(),
                  'title' => $tag->title
                ))
                ->save();

              //Select all old TagLink entries from this user.
              tx('Sql')
                ->table('webhistory', 'TagLink')
                ->join('Entries', $entry)
                ->where("$entry.user_id", "'".$user_who_uses_this_tag->user_id->get()."'")
                ->where('tag_id', "'".$tag->id->get()."'")
                ->execute()
                ->each(function($link)use($new_tag){

                  //And relink the user to this new tag.
                  $link->merge(array('tag_id', $new_tag->id->get()));
                  $link->save();

                });

            }

          });

      });
      
  }
  
  //Update to v0.3
  public function update_to_0_3($dummydata, $forced)
  {
    
    mk('Sql')->query('
      ALTER TABLE `#__webhistory__tags`
        ADD COLUMN `color` VARCHAR(50) NULL DEFAULT NULL AFTER `title`;  
    ');
    
  }
  
  //Update to v0.2.
  public function update_to_0_2($dummydata, $forced)
  {

    //Queue self-deployment with CMS component.
    $this->queue(array(
      'component' => 'cms',
      'min_version' => '3.0'
      ), function($version){
        
        mk('Component')->helpers('cms')->_call('ensure_pagetypes', array(
          array(
            'name' => 'webhistory',
            'title' => 'Webistor'
          ),
          array(
            'admin_stats' => 'MANAGER'
          )
        ));
        
      }
    ); //END - Queue CMS 3.0+

  }
  
  //Installer.
  public function install_0_1($dummydata, $forced)
  {

    if($forced === true){
      mk('Sql')->query('DROP TABLE IF EXISTS `#__webhistory__entries`');
      mk('Sql')->query('DROP TABLE IF EXISTS `#__webhistory__entries_to_tags`');
      mk('Sql')->query('DROP TABLE IF EXISTS `#__webhistory__friends`');
      mk('Sql')->query('DROP TABLE IF EXISTS `#__webhistory__tags`');
    }
    
    mk('Sql')->query('
      CREATE TABLE IF NOT EXISTS `#__webhistory__entries` (
        `id` int(10) NOT NULL AUTO_INCREMENT,
        `user_id` int(10) DEFAULT \'0\',
        `group_id` int(10) DEFAULT \'0\',
        `dt_created` datetime DEFAULT NULL,
        `dt_last_modified` datetime DEFAULT NULL,
        `url` varchar(255) DEFAULT NULL,
        `title` varchar(255) DEFAULT NULL,
        `quotes` text,
        `notes` text,
        `location` varchar(255) DEFAULT NULL,
        `context` varchar(255) DEFAULT NULL,
        `song` varchar(255) DEFAULT NULL,
        PRIMARY KEY (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    ');
    mk('Sql')->query('
      CREATE TABLE IF NOT EXISTS `#__webhistory__entries_to_tags` (
        `entry_id` int(10) unsigned DEFAULT NULL,
        `tag_id` int(10) unsigned DEFAULT NULL,
        `sort` smallint(5) unsigned DEFAULT NULL,
        PRIMARY KEY (`entry_id`, `tag_id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    ');
    mk('Sql')->query('
      CREATE TABLE IF NOT EXISTS `#__webhistory__friends` (
        `user_id` int(10) unsigned NOT NULL,
        `friend_id` int(10) unsigned NOT NULL,
        PRIMARY KEY (`user_id`, `friend_id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    ');
    mk('Sql')->query('
      CREATE TABLE IF NOT EXISTS `#__webhistory__tags` (
        `id` int(10) NOT NULL AUTO_INCREMENT,
        `title` varchar(50) DEFAULT NULL,
        PRIMARY KEY (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    ');
    
  }

}
