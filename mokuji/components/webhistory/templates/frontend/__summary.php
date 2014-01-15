<?php namespace components\webhistory; if(!defined('TX')) die('No direct access.'); ?>

<?php echo $data->tag_cloud; ?>

<p>
  <!--<b>You've saved <?php echo $data->num_of_entries; ?> entries already!</b>-->
</p>

<?php if(tx('Account')->user->level->get() >= 2): ?>
<table>
  <?php $data->user_entry_count->each(function($row){ ?>
    <tr>
      <td><?php echo $row->user->email; ?></td>
      <td align="right"><?php echo $row->num; ?></td>
    </tr>
  <?php }); ?>
</table>
<?php endif; ?>