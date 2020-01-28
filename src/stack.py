from os import environ
from aws_cdk import (
    aws_apigateway,
    aws_certificatemanager,
    aws_lambda,
    aws_logs,
    core,
)

class ApiStack(core.Stack):

    def __init__(self, scope: core.Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        my_lambda = aws_lambda.Function(
            self,
            environ['CDK_APP_NAME'],
            runtime=aws_lambda.Runtime.PYTHON_3_8,
            code=aws_lambda.Code.asset('lambda'),
            handler='contact_us.handler',
            environment={
                'CORS_ALLOW_ORIGIN': environ.get('CORS_ALLOW_ORIGIN', '*'),
                'PUSHOVER_API_ENDPOINT': environ['PUSHOVER_API_ENDPOINT'],
                'PUSHOVER_TOKEN': environ['PUSHOVER_TOKEN'],
                'PUSHOVER_USERKEY': environ['PUSHOVER_USERKEY'],
            },
            log_retention=aws_logs.RetentionDays.ONE_WEEK,
        )

        cert = aws_certificatemanager.Certificate(
            self,
            '{}-certificate'.format(environ['CDK_APP_NAME']),
            domain_name=environ['CDK_BASE_DOMAIN'],
        )

        domain = aws_apigateway.DomainNameOptions(
            certificate=cert,
            domain_name=environ['CDK_BASE_DOMAIN'],
        )

        cors = aws_apigateway.CorsOptions(
            allow_methods=["POST"],
            allow_origins=[environ['CORS_ALLOW_ORIGIN']]
                            if environ.get('CORS_ALLOW_ORIGIN')
                            else aws_apigateway.Cors.ALL_ORIGINS,
        )

        aws_apigateway.LambdaRestApi(
            self,
            '{}-gateway'.format(environ['CDK_APP_NAME']),
            handler=my_lambda,
            domain_name=domain,
            default_cors_preflight_options=cors,
        )
