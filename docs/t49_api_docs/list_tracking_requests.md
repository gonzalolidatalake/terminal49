# List tracking requests

> Returns a list of your tracking requests. The tracking requests are returned sorted by creation date, with the most recent tracking request appearing first.



## OpenAPI

````yaml get /tracking_requests
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
  /tracking_requests:
    parameters: []
    get:
      tags:
        - Tracking Requests
      summary: List tracking requests
      description: >-
        Returns a list of your tracking requests. The tracking requests are
        returned sorted by creation date, with the most recent tracking request
        appearing first.
      operationId: get-tracking-requests
      parameters:
        - schema:
            type: string
          in: query
          name: q
          description: >-
            A search term to be applied against request_number and
            reference_numbers.
          deprecated: true
        - schema:
            type: string
          in: query
          name: filter[request_number]
          description: filter by `request_number`
        - schema:
            type: string
            enum:
              - created
              - pending
              - failed
            example: created
          in: query
          name: filter[status]
          description: filter by `status`
        - schema:
            type: string
            example: MSCU
          in: query
          name: filter[scac]
          description: filter by shipping line `scac`
        - schema:
            type: string
            example: '2020-04-28T22:59:15Z'
            format: date-time
          in: query
          name: filter[created_at][start]
          description: >-
            filter by tracking_requests `created_at` after a certain ISO8601
            timestamp
        - schema:
            type: string
            example: '2020-04-28T22:59:15Z'
            format: date-time
          in: query
          description: >-
            filter by tracking_requests `created_at` before a certain ISO8601
            timestamp
          name: filter[created_at][end]
        - schema:
            type: string
            example: '2020-04-28T22:59:15Z'
            format: date-time
          in: query
          name: filter[updated_at][start]
          description: >-
            filter by tracking_requests `updated_at` after a certain ISO8601
            timestamp
        - schema:
            type: string
            example: '2020-04-28T22:59:15Z'
            format: date-time
          in: query
          description: >-
            filter by tracking_requests `updated_at` before a certain ISO8601
            timestamp
          name: filter[updated_at][end]
        - schema:
            type: string
          in: query
          name: include
          description: >-
            Comma delimited list of relations to include. 'tracked_object' is
            included by default.
        - schema:
            type: integer
          in: query
          name: page[number]
        - schema:
            type: integer
          in: query
          name: page[size]
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/tracking_request'
                  links:
                    $ref: '#/components/schemas/links'
                  meta:
                    $ref: '#/components/schemas/meta'
                  included:
                    type: array
                    items:
                      anyOf:
                        - $ref: '#/components/schemas/account'
                        - $ref: '#/components/schemas/shipping_line'
                        - type: object
                          properties:
                            id:
                              type: string
                              format: uuid
                            type:
                              type: string
                              enum:
                                - shipment
                            links:
                              type: object
                              properties:
                                self:
                                  type: string
                                  format: uri
                          description: ''
              examples: {}
        '404':
          description: Not Found
          content:
            application/json:
              schema:
                type: object
                properties:
                  errors:
                    type: array
                    items:
                      $ref: '#/components/schemas/error'
              examples:
                Not Found:
                  value:
                    errors:
                      - status: '404'
                        title: Not Found
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
    links:
      title: links
      type: object
      properties:
        last:
          type: string
          format: uri
        next:
          type: string
          format: uri
        prev:
          type: string
          format: uri
        first:
          type: string
          format: uri
        self:
          type: string
          format: uri
    meta:
      title: meta
      type: object
      properties:
        size:
          type: integer
        total:
          type: integer
    account:
      title: Account model
      type: object
      properties:
        id:
          type: string
          format: uuid
        type:
          type: string
          enum:
            - container
        attributes:
          type: object
          required:
            - company_name
          properties:
            company_name:
              type: string
      required:
        - id
        - type
        - attributes
      x-examples: {}
    shipping_line:
      title: Shipping line model
      type: object
      properties:
        id:
          type: string
          format: uuid
        attributes:
          type: object
          required:
            - scac
            - name
            - alternative_scacs
            - short_name
            - bill_of_lading_tracking_support
            - booking_number_tracking_support
            - container_number_tracking_support
          properties:
            scac:
              type: string
              minLength: 4
              maxLength: 4
            name:
              type: string
            alternative_scacs:
              type: array
              x-stoplight:
                id: jwf70hnip0xwb
              description: Additional SCACs which will be accepted in tracking requests
              items:
                x-stoplight:
                  id: nrqnwg5y2u0ni
                type: string
                minLength: 4
                maxLength: 4
            short_name:
              type: string
            bill_of_lading_tracking_support:
              type: boolean
            booking_number_tracking_support:
              type: boolean
            container_number_tracking_support:
              type: boolean
        type:
          type: string
          enum:
            - shipping_line
      required:
        - id
        - attributes
        - type
    error:
      title: Error model
      type: object
      properties:
        detail:
          type: string
          nullable: true
        title:
          type: string
          nullable: true
        source:
          type: object
          nullable: true
          properties:
            pointer:
              type: string
              nullable: true
            parameter:
              type: string
              nullable: true
        code:
          type: string
          nullable: true
        status:
          type: string
          nullable: true
        meta:
          type: object
          nullable: true
          properties:
            tracking_request_id:
              type: string
              format: uuid
              nullable: true
      required:
        - title
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