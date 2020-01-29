import json
import logging
from os import environ
import urllib.request
from urllib.parse import urlencode

LOG = logging.getLogger()
LOG.setLevel("DEBUG")


class HandledError(BaseException):
    pass


def send_msg_to_pushover(title, payload):
    """Send payload as message to Pushover API."""
    token = environ["PUSHOVER_TOKEN"]
    userkey = environ["PUSHOVER_USERKEY"]
    url = environ["PUSHOVER_API_ENDPOINT"]

    data = urlencode({
        "token": token,
        "user": userkey,
        "message": payload,
        "title": title,
    }).encode()

    req = urllib.request.Request(url=url, data=data, method="POST")
    return urllib.request.urlopen(req)


def contact_us(body):
    LOG.info("Processing payload %s" % body)

    try:
        body = json.loads(body)
        msg = "Name: %(name)s\nMail: %(email)s\nDesc: %(description)s\n" % body

    except (TypeError, json.JSONDecodeError) as error:
        raise HandledError("JSON body is malformatted: %s" % error)

    except KeyError as error:
        raise HandledError("Key missing: %s" % error)

    LOG.info("Delivering message via Pushover")
    send_msg_to_pushover(title="New /contact_us submission received",
                         payload=msg)
    LOG.info("Message delivered successfully")
    return "message delivered"


def handler(event, context):
    # ref: https://docs.aws.amazon.com/apigateway/latest
    #   /developerguide/set-up-lambda-proxy-integrations.html
    class Response:
        def __init__(self):
            self.statusCode = 500
            self.message = ""
            self.error = None

        def out(self):
            return {
                "isBase64Encoded": False,
                "statusCode": self.statusCode,
                "headers": {"Access-Control-Allow-Origin": environ.get("CORS_ALLOW_ORIGIN", "*")},
                "body": json.dumps({"error": str(self.error)}
                                    if self.error else {"message": self.message}),
            }

    response = Response()

    try:
        path, method = event["path"], event["httpMethod"]
        LOG.info("Received HTTP %s request for path %s" % (method, path))

        if (path == "/contact_us" and method == "POST"):
            response.message = contact_us(event.get("body"))
            response.statusCode = 200

        else:
            raise HandledError("%s %s not allowed" % (method, path))

    except HandledError as error:
        LOG.error(error)
        response.error = error
        response.statusCode = 405

    except Exception as error:
        response.error = error
        LOG.fatal(error)

    return response.out()
