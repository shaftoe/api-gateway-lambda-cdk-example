#!/usr/bin/env python3
from os import environ

from aws_cdk import core

from api.api_stack import ApiStack


app = core.App()

ApiStack(
  app,
  environ['CDK_APP_NAME'],
  tags={
    'Managed': 'cdk',
    'Name': environ['CDK_APP_NAME'],
  },
)

app.synth()
