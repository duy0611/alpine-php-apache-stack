### Makefile ###
################

.PHONY: build-docker
build-docker:
	docker build . -t alpine-php7-apache2

.PHONY: run-docker
run-docker: build-docker
	docker run --rm -d -p 80:80 --name php-webserver alpine-php7-apache2
	@echo "Run following to test the webserver: "
	@echo "curl http://localhost/index.html"

.PHONY: stop-docker
stop-docker:
	docker stop php-webserver

.PHONY: run-docker-compose
run-docker-compose:
	docker-compose -f docker-compose.yml up --build -d
	@echo "Run following to test the webserver: "
	@echo "curl http://localhost/index.php"
	@echo "curl http://localhost/info.php"

.PHONY: stop-docker-compose
stop-docker-compose:
	docker-compose -f docker-compose.yml down
