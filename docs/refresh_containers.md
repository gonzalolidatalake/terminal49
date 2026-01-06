# Refresh container

> Schedules the container to be refreshed immediately from all relevant sources.<br /><br />To be alerted of updates you should subscribe to the [relevant webhooks](/api-docs/in-depth-guides/webhooks).<Info> This endpoint is limited to 10 requests per minute.</Info><Note>This is a paid feature. Please contact sales@terminal49.com.</Note>



## OpenAPI

````yaml patch /containers/{id}/refresh
openapi: 3.0.0
info:
  title: Terminal49 API Reference
  version: 0.2.0
  contact:
    name: Terminal49 API support
    url: https://www.terminal49.com
    email: support@terminal49.com
  description: >-
    The Terminal 49 API offers a convenient way to programmatically track your
    shipments from origin to destination.


    Please enter your API key into the "Variables" tab before using these
    endpoints within Postman.
  x-label: Beta
  termsOfService: https://www.terminal49.com/terms
servers:
  - url: https://api.terminal49.com/v2
    description: Production
security:
  - authorization: []
tags:
  - name: Containers
  - name: Shipments
  - name: Locations
  - name: Events
  - name: Tracking Requests
  - name: Webhooks
  - name: Webhook Notifications
  - name: Ports
  - name: Metro Areas
  - name: Terminals
  - name: Routing (Paid)
paths:
  /containers/{id}/refresh:
    parameters:
      - schema:
          type: string
        name: id
        in: path
        required: true
    patch:
      tags:
        - Containers
      summary: Refresh container
      description: >-
        Schedules the container to be refreshed immediately from all relevant
        sources.<br /><br />To be alerted of updates you should subscribe to the
        [relevant webhooks](/api-docs/in-depth-guides/webhooks).<Info> This
        endpoint is limited to 10 requests per minute.</Info><Note>This is a
        paid feature. Please contact sales@terminal49.com.</Note>
      operationId: patch-containers-id-refresh
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                type: object
                properties:
                  message:
                    type: string
                    example: Started refresh for Shipping line, Terminal, Rail
              examples:
                Refresh response:
                  value:
                    message: Started refresh for Shipping line, Terminal, Rail
        '403':
          description: >-
            Forbidden - This API endpoint is not enabled for your account.
            Please contact support@terminal49.com
          content:
            application/json:
              schema:
                type: object
                properties:
                  errors:
                    type: array
                    items:
                      type: object
                      properties:
                        status:
                          type: string
                          example: '403'
                        title:
                          type: string
                          example: API access not enabled
                        detail:
                          type: string
                          example: >-
                            This API endpoint is not enabled for your account.
                            Please contact support@terminal49.com
        '429':
          description: >-
            Too Many Requests - You've hit the refresh limit. Please try again
            in a minute.
          content:
            application/json:
              schema:
                type: object
                properties:
                  errors:
                    type: array
                    items:
                      type: object
                      properties:
                        status:
                          type: string
                          example: '429'
                        title:
                          type: string
                          example: Too Many Requests
                        detail:
                          type: string
                          example: >-
                            You've hit the refresh limit. Please try again in a
                            minute.
          headers:
            Retry-After:
              description: Number of seconds to wait before making another request
              schema:
                type: integer
                example: 60
components:
  securitySchemes:
    authorization:
      name: Authorization
      type: apiKey
      in: header
      description: >-
        `Token YOUR_API_TOKEN`


        The APIs require authentication to be done using header-based API Key
        and Secret Authentication. 


        API key and secret are sent va the `Authorization` request header.


        You send your API key and secret in the following way:


        `Authorization: Token YOUR_API_KEY`

````

---

> To find navigation and other pages in this documentation, fetch the llms.txt file at: https://terminal49.com/docs/llms.txt