include config.mk

DIR := api
CDK := cd $(DIR) && cdk --profile $(PROFILE)

.ONESHELL: # Use virtualenv: https://stackoverflow.com/a/55404948

venv:
	@. $(DIR)/.env/bin/activate

create_venv:
	@# ensure correct Python version is used:
	@rm -rf $(DIR)/.env
	@python3 -m venv $(DIR)/.env

setup:
	@mkdir $(DIR)
	@$(CDK) init app --language python
	@rm -rf $(DIR)/.git

init: setup create_venv # Needed only one time to bootstrap development

postinit:
	@git mv lambda $(DIR)
	@git mv -f requirements.txt $(DIR)
	@git mv -f src/app.py $(DIR)
	@git mv -f src/stack.py $(DIR)/$(DIR)/$(DIR)_stack.py
	@rm $(DIR)/source.bat

requirements: venv
	@cd $(DIR) && pip install -r requirements.txt

bootstrap: venv postinit requirements
	@$(CDK) bootstrap

synth: venv
	@$(CDK) synth

deploy: requirements
	@$(CDK) deploy
	# TODO print apigw Target Domain Name for DNS

destroy: venv
	@$(CDK) destroy
	@printf 'Remember to remove leftovers in CloudFormation\n'

list: venv
	@$(CDK) ls

diff: requirements
	@$(CDK) diff

all: init bootstrap deploy
