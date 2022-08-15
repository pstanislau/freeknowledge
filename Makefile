.SILENT:

help:
	{ grep --extended-regexp '^[a-zA-Z_-]+:.*#[[:space:]].*$$' $(MAKEFILE_LIST) || true; } \
	| awk 'BEGIN { FS = ":.*#[[:space:]]*" } { printf "\033[1;32m%-20s\033[0m%s\n", $$1, $$2 }'

dev: # local dev on http://localhost:1313
	./make.sh dev

dev-nodraft: # local dev without the drafts
	./make.sh dev-nodraft

build: # build static site to ./public
	./make.sh build

upload: # upload website files to s3
	./make.sh upload

create-user: # create user for github actions
	./make.sh create-user

create-certificate: # create certificate linked to route 53
	./make.sh create-certificate

tf-setup-backend: # setup s3 backend
	./make.sh tf-setup-backend

tf-init: # terraform init
	./make.sh tf-init

tf-validate: # terraform validate
	./make.sh tf-validate

tf-apply: # terraform plan + apply
	./make.sh tf-apply

tf-destroy: # terraform destroy
	./make.sh tf-destroy