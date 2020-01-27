include config.mk

DIR  		  := api
VENV 		  := . $(DIR)/.env/bin/activate
CDK_NOENV := cd $(DIR) && cdk --profile $(AWS_PROFILE)
CDK  		  := $(VENV) && $(CDK_NOENV)
CHECK_PY  := if [ $(shell python --version 2>&1 | cut -c 8) -eq "3" ]; then true;

install_venv: # in the unfortunate case your workstation is still running Python v2
	@mkdir -p $(DIR)
	@$(CHECK_PY) else python3 -m venv $(DIR)/.env; fi

check_python:
	@$(CHECK_PY) else printf 'error: Python v3 required\n'; exit 1; fi

init: install_venv # Needed only one time to bootstrap development
	@$(CDK_NOENV) init app --language python
	@rm -rf $(DIR)/.git
	@git mv lambda $(DIR)
	@git mv -f requirements.txt $(DIR)
	@git mv -f src/app.py $(DIR)
	@git mv -f src/stack.py $(DIR)/$(DIR)/$(DIR)_stack.py
	@rm $(DIR)/source.bat

requirements: check_python
	@$(VENV) && cd $(DIR) && pip install -r requirements.txt

bootstrap: check_python requirements
	@$(CDK) bootstrap

synth: check_python
	@$(CDK) synth

deploy: requirements
	@$(CDK) deploy
	@printf '###########################################################################\n'
	@printf '# remember to add the DNS record to enable owned domain:\n#\n'
	@printf '# $(CDK_BASE_DOMAIN)	CNAME	'
	@aws apigateway get-domain-name \
		--profile $(AWS_PROFILE) \
		--domain-name $(CDK_BASE_DOMAIN) \
		|	grep regionalDomainName \
		| cut -d ':' -f 2 \
		| tr -d ',' \
		| tr -d '"'
	@printf '###########################################################################\n'

destroy: check_python
	@$(CDK) destroy
	@printf 'Remember to remove leftovers in CloudFormation\n'

list: check_python
	@$(CDK) ls

diff: requirements
	@$(CDK) diff

all: init bootstrap deploy
