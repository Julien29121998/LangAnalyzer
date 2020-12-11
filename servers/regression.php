<?php
header('Content-Type: application/json');
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $json = file_get_contents('php://input');
    $data = json_decode($json);
    if(isset($data->dataset)&&isset($data->model)){
        http_response_code(200);
        echo json_encode(determination_coef($data->dataset,$data->model));
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
function mean($dataset){
    $sum=0;
    for($i=0; $i<sizeof($dataset); $i++){
        $sum+=$dataset[$i];
    }
    return $sum/sizeof($dataset);
}
function total_sum_squares($dataset){
    $mean = mean($dataset);
    $tss=0;
    for($i=0; $i<sizeof($dataset); $i++){
        $tss+=pow(($dataset[$i]-$mean),2);
    }  
    return $tss;
}
function residual_sum_squares($dataset,$model){
    $rss = 0;
    for($i=0; $i<sizeof($dataset); $i++){
        $rss+=pow(($dataset[$i]-$model[$i]),2);
    }
    return $rss;
}
function determination_coef($dataset,$model){
    $r2=1-(residual_sum_squares($dataset,$model)/total_sum_squares($dataset));
    return array("status"=>"ok","r2"=>$r2);
}
?>