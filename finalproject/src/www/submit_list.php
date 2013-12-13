<?php
$pipe = fopen('./nfqueue.fifo', 'w');
fwrite($pipe, "data\ndata2\n");
fflush($pipe);
fclose($pipe);
?>
<html>You are here.</html>
