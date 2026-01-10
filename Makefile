all:
	# You need very old docker or custom install
	# Increase swap to at least 1GB first!
 #docker build -t pi0-llm-agent:latest .
	#docker build --progress=plain -t pi0-llm-agent:latest .
	docker build --progress=plain -t pi0-llm-agent:latest . 2>&1 | tee build-log.txt

run:
	docker run --rm -it \
		--memory=450m \
		--cpus=0.9 \
		pi0-llm-agent:latest

remote-build:
	# Enable buildx (once)
	docker buildx create --use --name pi-builder
 docker buildx inspect --bootstrap

 # Build for arm/v6
 docker buildx build --platform linux/arm/v6 -t pi0-llm-agent:latest .
