<?php namespace components\webhistory; if(!defined('TX')) die('No direct access.'); ?>

<table class="tag-list">
  <?php $data->tags->each(function($tag){ ?>
  <tr>
    <td>
      <a class="tag orange" href="<?php echo url('?q='.$tag->title); ?>">
        <span class="btn-add-tag" title="Click to add this tag to the add/edit form"><i class="icon-plus"></i></span>
        <span class="tag-title" title="Click to show all '<?php echo $tag->title; ?>' entries"><?php echo $tag->title; ?></span>
      </a>
    </td>
    <td align="right" class="num-right">
      <?php echo $tag->num; ?>
    </td>
  </tr>
  <?php }); ?>
</table>

<script>

$(function(){

  $('.btn-add-tag').on('click', function(e){

    e.preventDefault();

    console.log('test');

    $('#l_tags').val( $('#l_tags').val() + $(this).closest('a').find('.tag-title').text() + ', ' );
    $('#l_tags').focus();

  });
  
});

</script>
