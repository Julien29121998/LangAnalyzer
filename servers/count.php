<?php
header('Content-Type: application/json');
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    http_response_code(200);
    $json = file_get_contents('php://input');
    $data = json_decode($json);
    if(isset($data->text)){
        echo json_encode(freq_analysis($data->text));
    }
    else{
        http_response_code(400);
        echo "{\"status\":\"err\"}";
    }
}
else{
    http_response_code(405);
    echo "{\"status\":\"err\"}";
}
?>

<?php
function freq_analysis($text){
    $occurences = array_fill(0,26,0);
    $total = 0;
    $special = 0;
    for($i=0; $i<strlen($text); $i++){
        $val = ord($text[$i])-65;
        if($val>=0&&$val<=25){
            $occurences[$val]+=1;
            $total+=1;
        }
        else{
            $special+=1;
        }
    }
    return array("status"=>"ok","counts"=>$occurences,
    "total"=>$total,"special"=>$special,"debug_sample"=>substr($text,0,8));
}
?>