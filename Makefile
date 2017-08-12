# Note: tabs by space can't not used for Makefile!
MONGO_PORT=27017

###############################################################################
# Initial Settings
###############################################################################
mongoinit:
	#After running mongodb
	mongo 127.0.0.1:$(MONGO_PORT)/admin --eval "var port = $(MONGO_PORT);" ./docker/mongo/init.js
	mongorestore -h 127.0.0.1:${MONGO_PORT} --db hiromaily docker/mongo/dump/hiromaily

dbinit:
	export DB_NAME=hiromaily
	sh ./data/sql/setup.sh


###############################################################################
# Managing Dependencies
###############################################################################
changegit:
	cd ${GOPATH}/src/github.com/aws/aws-sdk-go
	git checkout v0.9.17

update:
	go get -u github.com/tools/godep
	go get -u -d -v ./...

godep:
	rm -rf Godeps
	rm -rf ./vendor
	godep save ./...


###############################################################################
# Golang detection and formatter
###############################################################################
fmt:
	go fmt `go list ./... | grep -v '/vendor/'`

vet:
	go vet `go list ./... | grep -v '/vendor/'`

lint:
	golint ./... | grep -v '^vendor\/' || true
	misspell `find . -name "*.go" | grep -v '/vendor/'`
	ineffassign .

chk:
	go fmt `go list ./... | grep -v '/vendor/'`
	go vet `go list ./... | grep -v '/vendor/'`
	golint ./... | grep -v '^vendor\/' || true
	misspell `find . -name "*.go" | grep -v '/vendor/'`
	ineffassign .


###############################################################################
# Docker TODO:delete it
###############################################################################
dcstart:
	docker start web-redisd
	docker start web-mysqld
	docker start web-mongod

dcstop:
	docker stop web-redisd
	docker stop web-mysqld
	docker stop web-mongod

dcmongo:
	docker exec -it web-mongo bash


###############################################################################
# Docker-Compose
###############################################################################
dcfirst:
	docker-compose build
	docker-compose up mongo
	#
	mongo 127.0.0.1:$(MONGO_PORT)/admin --eval "var port = $(MONGO_PORT);" ./docker/mongo/init.js
	mongorestore -h 127.0.0.1:${MONGO_PORT} --db hiromaily docker/mongo/dump/hiromaily

dcbld:
	docker-compose build

dcbld:
	docker-compose up

dcfull:
	docker-compose up --build


###############################################################################
# Local Build
###############################################################################
#dcdb:
#	docker-compose up mysql redis mongo

bld:
	go build -i -v -o ${GOPATH}/bin/ginserver ./cmd/ginserver/

bldproxy:
	go build -i -v -o ${GOPATH}/bin/reverseproxy ./cmd/reverseproxy/

bldswg:
	go build -i -v -o ${GOPATH}/bin/swgserver ./swagger/go-swagger/cmd/swagger-server/


###############################################################################
# Execution
###############################################################################
run:
	go run ./cmd/ginserver/main.go

exec:
	ginserver -f ./data/toml/settings.toml

execproxy:
	PORTS=(8080 8081 8082)
	for port in ${PORTS[@]}
	do
		echo 'port is ${port}'
		ginserver -f ./configs/settings.toml -P ${port} &
	done
	sleep 5s

	reverseproxy -f ./configs/settings.toml
	#proxy.hiromaily.com:9990

execswg:
	swgserver


###############################################################################
# Test
###############################################################################
quicktest:
	go test -run TestLogin -v cmd/ginserver/*.go -f ../../data/toml/settings.toml

test:
	# Create Test Data
	export DB_NAME=hiromaily2
	export DB_PORT=13306
	export DB_USER=root
	export DB_PASS=root
	sh ./data/sql/setup.sh

	# Execute
	go test -v -covermode=count -coverprofile=profile.cov cmd/ginserver/*.go \
	-f ../../data/toml/settings.toml -om 0

	go test -v -covermode=count -coverprofile=profile.cov cmd/ginserver/*.go \
	-run "TestGetUserAPIRequestOnTable" \
	-f ../../data/toml/settings.toml -om 1

	go test -v -covermode=count -coverprofile=profile.cov cmd/ginserver/*.go \
	-run "TestGetUserAPIRequestOnTable" \
	-f ../../data/toml/settings.toml -om 2

	go test -v -covermode=count -coverprofile=profile.cov cmd/ginserver/*.go \
	-run "TestGetJwtAPIRequestOnTable|TestGetUserAPIRequestOnTable" \
	-f ../../data/toml/settings.toml -om 1

	go test -v -covermode=count -coverprofile=profile.cov cmd/ginserver/*.go \
	-run "TestGetJwtAPIRequestOnTable|TestGetUserAPIRequestOnTable" \
	-f ../../data/toml/settings.toml -om 2


###############################################################################
# Heroku
###############################################################################
herokudeploy:
	git push -f heroku master
