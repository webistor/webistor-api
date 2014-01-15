
<script>
// Include the UserVoice JavaScript SDK (only needed once on a page)
UserVoice=window.UserVoice||[];(function(){var uv=document.createElement('script');uv.type='text/javascript';uv.async=true;uv.src='//widget.uservoice.com/Xommsplvw8Wz9Als0UQMZw.js';var s=document.getElementsByTagName('script')[0];s.parentNode.insertBefore(uv,s)})();

// Set colors
UserVoice.push(['set', {
  position: 'automatic',
  accent_color: '#808283',
  trigger_color: 'white',
  contact_title: 'Send us a message',
  smartvote_title: 'What should we build next?',
  contact_enabled: false,
  screenshot_enabled: true,
  smartvote_enabled: true,
  post_idea_enabled: true
}]);

// Identify the user and pass traits
UserVoice.push(['identify', {
  email:      '<?php echo $data->email; ?>',
  name:       '<?php echo $data->name; ?>',
  created_at: <?php echo $data->created_at; ?>,
  id:         <?php echo $data->id; ?>
}]);


// Or, use your own custom trigger:
//UserVoice.push(['addTrigger', '#id', { mode: 'contact' }]);

// Autoprompt for Satisfaction and SmartVote (only displayed under certain conditions)
UserVoice.push(['autoprompt', {}]);
</script>
