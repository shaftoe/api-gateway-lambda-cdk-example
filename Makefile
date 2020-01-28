include config.mk

DIR  		  := api
VENV 		  := . $(DIR)/.env/bin/activate
CDK_NOENV := cd $(DIR) && cdk --profile $(AWS_PROFILE)
CDK  		  := $(VENV) && $(CDK_NOENV)

init: # Needed only one time to bootstrap development
	@mkdir -p $(DIR)
	@$(CDK_NOENV) init app --language python
	@rm -rf $(DIR)/.git
	@git mv lambda $(DIR)
	@git mv -f requirements.txt $(DIR)
	@git mv -f src/app.py $(DIR)
	@git mv -f src/stack.py $(DIR)/$(DIR)/$(DIR)_stack.py
	@rm $(DIR)/source.bat

requirements:
	@$(VENV) && cd $(DIR) && pip install -r requirements.txt

bootstrap: requirements
	@$(CDK) bootstrap

synth:
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

destroy:
	@$(CDK) destroy
	@printf 'Remember to remove leftovers in CloudFormation\n'

list:
	@$(CDK) ls

diff: requirements
	@$(CDK) diff

all: init bootstrap deploy
