
OUTPUT  = pedroarthur/zookeeper-4k8s
VERSION = 3.4.9-1

all: docker.build

docker.build:
	docker build \
		--build-arg  http_proxy=$(http_proxy) \
	 	--build-arg https_proxy=$(https_proxy) \
		-t $(OUTPUT):$(VERSION) .

docker.push:
	docker push $(OUTPUT):$(VERSION)

