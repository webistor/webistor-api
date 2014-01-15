<?php namespace components\webhistory; if(!defined('TX')) die('No direct access.');

class EntryPoint extends \dependencies\BaseEntryPoint
{
  
  public function entrance()
  {
    
    if(tx('Config')->system()->check('backend'))
    {
      
      //Display a login page?
      if(!tx('Account')->user->check('login'))
      {
        
        return $this->template('tx_login', 'tx_login', array(), array(
          'content' => tx('Component')->sections('account')->get_html('login_form')
        ));
        
      }
      
      //Show view.
      return $this->template('tuxion', 'tuxion_backend', array(
        'plugins' => array(
          load_plugin('jquery'),
          load_plugin('jsFramework')
        ),
        'scripts' => array(
          'tuxion_backend' => '<script type="text/javascript" src="'.URL_COMPONENTS.'/tuxion/includes/backend.js"></script>',
          'sisyphus' => '<script type="text/javascript" src="https://raw.github.com/simsalabim/sisyphus/master/sisyphus.min.js"></script>'
        )
      ),
      array(
        'content' => $this->view('items')
      ));
      
    }
    else
    {
      
      //Display a login page?
      if(false && !tx('Account')->user->check('login'))
      {
        
        return $this->template('tx_login', 'tx_login', array(), array(
          'content' => tx('Component')->sections('account')->get_html('login_form')
        ));
        
      }
      else
      {

        //Show view.
        return $this->template('minimal', 'webhistory', array('plugins' => array(
          load_plugin('jquery'),
          load_plugin('jquery_tmpl'),
          load_plugin('jslite'),
          load_plugin('jquery_rest'),
          load_plugin('ejs')
        )),
        array(
          'content' => $this->view('app')
        ));

      }
      
    }
    
  }
  
}
