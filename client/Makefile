dockerclient:
	echo "building client"
	docker build -t jbenard/tpcalc . > build.log && docker run -dit -v `pwd`:/project -p 15672:15672 --name calc_client jbenard/tpcalc

run:
	echo "run test"
	docker exec -it calc_client ruby controller.rb "sample.txt" 8470 8971 8972 8974