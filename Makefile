# Makefile for automating tasks

# Purpose of this Makefile
# A Makefile at the top level of your project is typically used to standardize and simplify common development, testing, build, and deployment tasks across all team members — regardless of platform or role.

# It works by defining shortcut commands (called "targets") that can run complex shell commands with simple instructions like:

install:
	pip install -r requirements.txt

# Makefile for iPlanning project

.PHONY: all build test deploy zip clean

all: build

build:
	cd app && flutter build apk

test:
	cd app && flutter test

backend-run:
	cd backend/python && python3 app/main.py

deploy:
	bash deployment/deploy.sh

zip:
	bash scripts/build_iproject.sh

clean:
	rm -rf app/build

