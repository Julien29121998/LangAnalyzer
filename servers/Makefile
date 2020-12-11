build:
	echo "building server image"
	docker build -t srv . > build.log
dockerserv: build
	echo "runing servers"
	docker run -d -p 8470:80 --name srv -v `pwd`:/var/www/html php:7.2-apache && docker rename srv srv1
	docker run -d -p 8971:80 --name srv -v `pwd`:/var/www/html php:7.2-apache && docker rename srv srv2
	docker run -d -p 8972:80 --name srv -v `pwd`:/var/www/html php:7.2-apache && docker rename srv srv3
	docker run -d -p 8974:80 --name srv -v `pwd`:/var/www/html php:7.2-apache && docker rename srv srv4