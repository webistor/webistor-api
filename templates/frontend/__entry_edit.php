<?php namespace components\webhistory; if(!defined('TX')) die('No direct access.'); ?>

<form action="<?php echo url('action=webhistory/save_entry/post'); ?>" method="post" id="edit-form">

  <div class="inner">

      <input type="hidden" name="id" value="<?php echo $data->entry->id; ?>" />
  
      <div class="ctrlHolder">
        <label for="l_url">URL</label>
        <input id="l_url" type="text" name="url" value="<?php echo $data->entry->url->otherwise(tx('Data')->get->url); ?>" />
      </div>
  
      <div class="ctrlHolder">
        <label for="l_title">Title</label>
        <input id="l_title" type="text" name="title" value="<?php echo $data->entry->title->otherwise(tx('Data')->get->title); ?>" />
      </div>
  
      <div class="ctrlHolder">
        <label for="l_tags">Tags</label>
        <input autofocus id="l_tags" type="text" name="tags" value="<?php echo $data->entry->tags->map(function($tag){ return $tag->title; })->join(', '); ?>" />
      </div>
  
      <div class="ctrlHolder" hidden>
        <label for="l_quotes">Quotes</label>
        <textarea  id="l_quotes" name="quotes"></textarea>
      </div>
    
    </div> <!-- /.inner -->
    
    <div class="notes">

      <div class="ctrlHolder" hidden>
        <label for="l_notes">Notes</label>
        <textarea id="l_notes" name="notes"><?php echo $data->entry->notes; ?></textarea>
      </div>
  
      <div class="ctrlHolder" hidden>
        <label for="l_location">Location</label>
        <input id="l_location" type="text" name="location" value="<?php echo $data->entry->location; ?>" />
      </div>
  
      <div class="ctrlHolder" hidden>
        <label for="l_context">Context</label>
        <input id="l_context" type="text" name="context" value="<?php echo $data->entry->context; ?>" />
      </div>
  
      <div class="ctrlHolder" hidden>
        <label for="l_context">Context</label>
        <input id="l_context" type="text" name="context" value="<?php echo $data->entry->context; ?>" />
      </div>
  
      <div class="ctrlHolder">
        <input type="submit" value="Save" />
      </div>
    
    </div> <!-- /.notes -->

</form>

<script>

$(function(){

  var edit_form_inactive = $('#edit-form:not(.active)');

  function openEditForm(){
    console.log('click');
    edit_form_inactive.addClass('active');
  }

  $(function(){

    edit_form_inactive.on('click', openEditForm);

    <?php if(tx('Data')->get->method == 'add' || tx('Data')->get->id->is_set() ): ?>
    openEditForm();
    <?php endif; ?>

  });

});

</script>
