<!--
Toon aantal nieuwe gebruikers per maand.
-->
<?php echo $data->new_users; ?>

<!--
Toon lijst me gebruikers, omgekeerd gesorteerd op totaal aantal entries.
-->
<?php

echo $data->accounts_by_login_date->as_table(array(
  'Email address' => 'email',
  'Number of entries' => 'num_entries'
));

?>

<!--
Toon totaal aantal entries per maand
-->
