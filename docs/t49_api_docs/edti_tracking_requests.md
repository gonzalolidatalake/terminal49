# Edit a tracking request

> Update a tracking request



## OpenAPI

````yaml patch /tracking_requests/{id}
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
  /tracking_requests/{id}:
    parameters:
      - schema:
          type: string
        name: id
        in: path
        required: true
        description: Tracking Request ID
    patch:
      tags:
        - Tracking Requests
      summary: Edit a tracking request
      description: Update a tracking request
      operationId: patch-track-request-by-id
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                data:
                  type: object
                  required:
                    - attributes
                    - type
                  properties:
                    attributes:
                      type: object
                      properties:
                        ref_number:
                          type: string
                          example: REFNUMBER11
                          description: Tracking request ref number.
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    $ref: '#/components/schemas/tracking_request'
components:
  schemas:
    tracking_request:
      title: Tracking Request
      type: object
      properties:
        id:
          type: string
          format: uuid
        type:
          type: string
          enum:
            - tracking_request
        attributes:
          type: object
          properties:
            request_number:
              type: string
              example: ONEYSH9AME650500
            ref_numbers:
              type: array
              items:
                type: string
              nullable: true
            tags:
              type: array
              items:
                type: string
            status:
              type: string
              enum:
                - pending
                - awaiting_manifest
                - created
                - failed
                - tracking_stopped
            failed_reason:
              type: string
              enum:
                - booking_cancelled
                - duplicate
                - expired
                - internal_processing_error
                - invalid_number
                - not_found
                - retries_exhausted
                - shipping_line_unreachable
                - unrecognized_response
                - data_unavailable
                - null
              description: >-
                If the tracking request has failed, or is currently failing, the
                last reason we were unable to complete the request
              nullable: true
            request_type:
              type: string
              enum:
                - bill_of_lading
                - booking_number
                - container
              example: bill_of_lading
            scac:
              type: string
              example: ONEY
              minLength: 4
              maxLength: 4
            created_at:
              type: string
              format: date-time
            updated_at:
              type: string
              format: date-time
            is_retrying:
              type: boolean
            retry_count:
              type: integer
              description: >-
                How many times T49 has attempted to get the shipment from the
                shipping line
              nullable: true
          required:
            - request_number
            - status
            - request_type
            - scac
            - created_at
        relationships:
          type: object
          properties:
            tracked_object:
              type: object
              properties:
                data:
                  type: object
                  nullable: true
                  properties:
                    id:
                      type: string
                      format: uuid
                    type:
                      type: string
                      enum:
                        - shipment
            customer:
              type: object
              properties:
                data:
                  type: object
                  properties:
                    id:
                      type: string
                      format: uuid
                    type:
                      type: string
                      enum:
                        - party
      required:
        - id
        - type
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