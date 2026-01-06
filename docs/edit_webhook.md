# Edit a webhook

> Update a single webhook



## OpenAPI

````yaml patch /webhooks/{id}
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
  /webhooks/{id}:
    parameters:
      - schema:
          type: string
        name: id
        in: path
        required: true
    patch:
      tags:
        - Webhooks
      summary: Edit a webhook
      description: Update a single webhook
      operationId: patch-webhooks-id
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
                        url:
                          type: string
                          example: >-
                            https://webhook.site/#!/39084fbb-d887-42e8-be08-b9183ad02362
                          format: uri
                          description: The URL of the webhook endpoint.
                        events:
                          type: array
                          description: The list of events to enable for this endpoint.
                          uniqueItems: true
                          minItems: 1
                          items:
                            type: string
                            enum:
                              - container.transport.vessel_arrived
                              - container.transport.vessel_discharged
                              - container.transport.vessel_loaded
                              - container.transport.vessel_departed
                              - container.transport.rail_departed
                              - container.transport.rail_arrived
                              - container.transport.rail_loaded
                              - container.transport.rail_unloaded
                              - container.transport.transshipment_arrived
                              - container.transport.transshipment_discharged
                              - container.transport.transshipment_loaded
                              - container.transport.transshipment_departed
                              - container.transport.feeder_arrived
                              - container.transport.feeder_discharged
                              - container.transport.feeder_loaded
                              - container.transport.feeder_departed
                              - container.transport.empty_out
                              - container.transport.full_in
                              - container.transport.full_out
                              - container.transport.empty_in
                              - container.transport.vessel_berthed
                              - shipment.estimated.arrival
                              - tracking_request.succeeded
                              - tracking_request.failed
                              - tracking_request.awaiting_manifest
                              - tracking_request.tracking_stopped
                              - container.created
                              - container.updated
                              - container.pod_terminal_changed
                              - >-
                                container.transport.arrived_at_inland_destination
                              - >-
                                container.transport.estimated.arrived_at_inland_destination
                              - container.pickup_lfd.changed
                              - container.pickup_lfd_line.changed
                              - container.transport.available
                        active:
                          type: boolean
                        headers:
                          type: array
                          description: >-
                            Optional custom headers to pass with each webhook
                            invocation
                          items:
                            type: object
                            properties:
                              name:
                                type: string
                                description: >-
                                  The name of the header. (Please not this will
                                  be auto-capitalized) 
                              value:
                                type: string
                                description: |
                                  The value to pass for the header
                    type:
                      type: string
                      enum:
                        - webhook
              required:
                - data
            examples: {}
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    $ref: '#/components/schemas/webhook'
components:
  schemas:
    webhook:
      title: webhook
      type: object
      x-examples: {}
      properties:
        id:
          type: string
          format: uuid
        type:
          type: string
          enum:
            - webhook
        attributes:
          type: object
          properties:
            url:
              type: string
              format: uri
              description: https end point
            active:
              type: boolean
              default: true
              description: Whether the webhook will be delivered when events are triggered
            events:
              type: array
              description: The list of events to enabled for this endpoint
              uniqueItems: true
              minItems: 1
              items:
                type: string
                enum:
                  - container.transport.vessel_arrived
                  - container.transport.vessel_discharged
                  - container.transport.vessel_loaded
                  - container.transport.vessel_departed
                  - container.transport.rail_departed
                  - container.transport.rail_arrived
                  - container.transport.rail_loaded
                  - container.transport.rail_unloaded
                  - container.transport.transshipment_arrived
                  - container.transport.transshipment_discharged
                  - container.transport.transshipment_loaded
                  - container.transport.transshipment_departed
                  - container.transport.feeder_arrived
                  - container.transport.feeder_discharged
                  - container.transport.feeder_loaded
                  - container.transport.feeder_departed
                  - container.transport.empty_out
                  - container.transport.full_in
                  - container.transport.full_out
                  - container.transport.empty_in
                  - container.transport.vessel_berthed
                  - shipment.estimated.arrival
                  - tracking_request.succeeded
                  - tracking_request.failed
                  - tracking_request.awaiting_manifest
                  - tracking_request.tracking_stopped
                  - container.created
                  - container.updated
                  - container.pod_terminal_changed
                  - container.transport.arrived_at_inland_destination
                  - container.transport.estimated.arrived_at_inland_destination
                  - container.pickup_lfd.changed
                  - container.pickup_lfd_line.changed
                  - container.transport.available
            secret:
              type: string
              description: A random token that will sign all delivered webhooks
            headers:
              type: array
              nullable: true
              items:
                type: object
                properties:
                  name:
                    type: string
                  value:
                    type: string
          required:
            - url
            - active
            - events
            - secret
      required:
        - id
        - type
      description: ''
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