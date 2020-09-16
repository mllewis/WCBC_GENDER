<?php
	// get data
	//$post_data = json_decode(file_get_contents('php://input'), true);

	$result_string = $_POST['postresult_string'];
	$worker_id = $_POST['subjectid'];

	// get filename
	$filename = "data/".$worker_id."_data.csv";
 
	// write the file to disk
	file_put_contents($filename, $result_string, FILE_APPEND);
?>