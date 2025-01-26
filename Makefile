#!/usr/bin/env make
virtfuzz-repo:
	git clone https://github.com/WesleySoftware/VirtFuzz
guestimage: virtfuzz-repo
	# create a bullseye image (because bullseye is still supported)
	cd ./VirtFuzz/guestimage/ && \
	./create-image.sh -d bullseye
docker: guestimage
	docker build . -t virtfuzz
clean:
	rm -rf VirtFuzz
	#docker rmi virtfuzz