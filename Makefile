docker:
	echo "building..."
	cd servers && make dockerserv
	cd client && make dockerclient

example:
	cd client && make run

run_on_input:
	cp input.txt ./client/sample.txt && cd client && make run