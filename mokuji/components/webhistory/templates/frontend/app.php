<?php namespace components\webhistory; if(!defined('MK')) die('No direct access.'); ?>

<div id="nav">
	
	<h1>Webistor</h1>

	<ul id="main-nav">
	
    <li class="active"><a href="<?php echo URL_BASE; ?>">My history</a></li>
    <li><a href="<?php echo URL_BASE; ?>friends/" title="'My friends' is in private beta">My friends</a></li>
    <li><a href="https://webistor.uservoice.com/" target="_blank" data-uv-trigger="contact">Send feedback <small>(new)</small></a></li>
    <li><a class="bookmarklet" title="Drag this bookmarklet to your bookmarks bar" href="javascript:window.location.href='http://webistor.net/?method=add&url='+location.href+'&title='+document.title;">Bookmarklet</a></li>
		
	</ul>
	<ul id="profile-nav">
		<li><img src="#" class="avatar"></li>
		<li>Username <i class="fa fa-caret-down"></i></li>
	
	</ul>

</div> <!-- /#nav -->

<div id="contentwrapper">

  <div id="left" class="clearfix">

	  <div class="header">
		  
		  <h2 class="title">My History</h2>
		
      <div id="actions"
			  <form>
				  <input type="search">
        </form>
		
        <a href="#" class="button blue"><i class="fa fa-link"></i> Add Link</a>		
      </div>
    
    </div> <!-- /.header -->
	
  	<?php echo $data->entry_edit; ?>
  
    <div id="js-webhistory-entry-list">        
          <?php echo $data->entry_list; ?>
    </div>
  
  </div> <!-- /#left -->
  
  <div id="right" class="clearfix">
    
    <form id="tag-src">
		  <input type="search" value="enter tag">
    </form>
    
    <div id="js-webhistory-sidebar" class="span4 wh-pane webhistory-sidebar">
      <?php echo $data->summary; ?>
    </div>
    
  </div> <!-- /#right -->

</div> <!-- /#contentwrapper -->


<script>
//Init Webhistory.
$(function(){
  window.webhistory = new Webhistory({
    search: '<?php echo tx('Data')->get->q; ?>'
  });
})
</script>

<?php /*

        <ul class="nav">
          <li class="active"><a href="<?php echo URL_BASE; ?>">My history</a></li>
          <li><a href="<?php echo URL_BASE; ?>friends/" title="'My friends' is in private beta">My friends</a></li>
          <li><a href="https://webistor.uservoice.com/" target="_blank" data-uv-trigger="contact">Send feedback <small>(new)</small></a></li>
          <li><a class="bookmarklet" title="Drag this bookmarklet to your bookmarks bar" href="javascript:window.location.href='http://webistor.net/?method=add&url='+location.href+'&title='+document.title;">Bookmarklet</a></li>
          <li><a title="@webistor" target="_blank" href="https://twitter.com/webistor"><img src="http://www.intersport.nl/media/wysiwyg/footer/twitter-icon.png" /></a></li>
        </ul>

        <?php if(!tx('Account')->user->check('login')){ ?>

        <form method="post" action="<?php echo url('rest=account/user_session',1); ?>" id="login-form" class="navbar-form pull-right">
          <input id="l_username" autofocus class="span2" name="email" type="text" placeholder="Username">
          <input id="l_password" name="password" type="password" placeholder="Password" class="span2" />
          <input id="l_remember" type="checkbox" name="persistent" value="1" checked="checked" />
          <button type="submit" class="btn">Sign in</button>
        </form>

        <script type="text/javascript">
          jQuery(function($){
            
            $('#login-form').restForm({
              
              success: function(result){
                
                if(result.success === true)
                  window.location = result.target_url;
                
              },
              
              error: function(err){
                $('#l_password').val('');
                $('#l_username').focus().select();
              }
              
            });
            
          });
        </script>

        <?php }else{ ?>

        <div class="navbar-form pull-right mini-username">
          Logged in as <?php echo tx('Account')->user->username->otherwise(tx('Account')->user->email); ?>
          | <a href="<?php echo url('action=account/logout'); ?>">Logout</a>
        </div>

        <?php } ?>

      </div><!--/.nav-collapse -->
    </div>
  </div>
</div>

<div class="container" id="main-content">

  <div class="row">  
    <?php if(!tx('Account')->user->check('login')){ ?>

      <div class="span12">
        <?php echo $data->intro; ?>
      </div>

    <?php }else{ ?>

      <div class="span8 alpha wh-pane list-pane">
        <?php echo $data->entry_edit; ?>

        <div id="js-webhistory-entry-list">        
          <?php echo $data->entry_list; ?>
        </div>

      </div>
      
      <div id="js-webhistory-sidebar" class="span4 wh-pane webhistory-sidebar">
        <?php echo $data->summary; ?>
      </div>

    <?php } ?>
  </div>  

</div> <!-- /container -->

<footer id="footer" class="container">
  <span class="span12">
    <p>Made with tea and cookies<!-- , by <a href="http://www.bartroorda.nl/" target="_blank">Bart Roorda</a> -->.</p>
  </span>
</footer>


<?php echo $data->uservoice_widget; ?>

*/?>