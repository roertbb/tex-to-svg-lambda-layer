download:
	wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz

build: 
	docker build -t roertbb/tex-to-svg-lambda-layer .
	mkdir build
	docker run --rm -it -v $(shell pwd):/var/host roertbb/tex-to-svg-lambda-layer zip --symlinks -r -9 /var/host/build/layer.zip .

clean:
	rm ./build/*

# ---

STACK_NAME ?= latex-layer 
DEPLOYMENT_BUCKET ?= lambda-pdf-latex

build/output.yaml: template.yaml build/layer.zip
	aws cloudformation package --template $< --s3-bucket $(DEPLOYMENT_BUCKET) --output-template-file $@

deploy: build/output.yaml
	aws cloudformation deploy --template $< --stack-name $(STACK_NAME)
	aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query Stacks[].Outputs --output table