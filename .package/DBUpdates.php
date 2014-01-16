<?php namespace components\webhistory; if(!defined('TX')) die('No direct access.');

//Make sure we have the things we need for this class.
mk('Component')->check('update');

class DBUpdates extends \components\update\classes\BaseDBUpdates
{
  
  protected
    $component = 'webhistory',
    $updates = array(
      '0.1' => '0.2',
      '0.2' => '0.3'
    );
  
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
