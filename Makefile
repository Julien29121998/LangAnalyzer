docker:
	echo "building..."
	cd servers && make dockerserv
	cd client && make dockerclient

example:
	cd client && make run