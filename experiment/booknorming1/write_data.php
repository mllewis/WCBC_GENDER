<?php
$post_data = json_decode(file_get_contents('php://input'), true); 
// the directory "data" must be writable by the server
$name = "data/".$post_data['filename'].".csv"; 
$data = $post_data['filedata'];
// check to make sure file doesn't already exist; if it does, add a character "A" to the front of the filename
// if (file_exists($name)) {
// 	$temp="A".$post_data['filename'].".csv";
//     $name="data/".$temp;
// }
// write the file to disk
file_put_contents($name, $data);
?>