# List webhook notifications

> Return the list of  webhook notifications. This can be useful for reconciling your data if your endpoint has been down. 



## OpenAPI

````yaml get /webhook_notifications
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
  /webhook_notifications:
    get:
      tags:
        - Webhook Notifications
      summary: List webhook notifications
      description: >-
        Return the list of  webhook notifications. This can be useful for
        reconciling your data if your endpoint has been down. 
      operationId: get-webhook-notifications
      parameters:
        - schema:
            type: integer
          in: query
          name: page[number]
        - schema:
            type: integer
          in: query
          name: page[size]
        - schema:
            type: string
          in: query
          description: Comma delimited list of relations to include.
          name: include
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
                      $ref: '#/components/schemas/webhook_notification'
                  links:
                    $ref: '#/components/schemas/links'
                  meta:
                    $ref: '#/components/schemas/meta'
                  included:
                    type: array
                    items:
                      anyOf:
                        - $ref: '#/components/schemas/webhook'
                        - $ref: '#/components/schemas/tracking_request'
                        - $ref: '#/components/schemas/transport_event'
                        - $ref: '#/components/schemas/estimated_event'
components:
  schemas:
    webhook_notification:
      title: webhook_notification
      type: object
      properties:
        id:
          type: string
          format: uuid
        type:
          type: string
          enum:
            - webhook_notification
        attributes:
          type: object
          properties:
            event:
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
            delivery_status:
              type: string
              default: pending
              enum:
                - pending
                - succeeded
                - failed
              description: >-
                Whether the notification has been delivered to the webhook
                endpoint
            created_at:
              type: string
          required:
            - event
            - delivery_status
            - created_at
        relationships:
          type: object
          properties:
            webhook:
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
                        - webhook
            reference_object:
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
                        - tracking_request
                        - estimated_event
                        - transport_event
                        - container_updated_event
          required:
            - webhook
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
    transport_event:
      title: Transport Event Model
      type: object
      properties:
        id:
          type: string
          format: uuid
        type:
          type: string
          enum:
            - transport_event
        attributes:
          type: object
          properties:
            event:
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
                - container.transport.arrived_at_inland_destination
                - container.transport.estimated.arrived_at_inland_destination
                - container.pickup_lfd.changed
                - container.pickup_lfd_line.changed
                - container.transport.available
            voyage_number:
              type: string
              nullable: true
            timestamp:
              type: string
              format: date-time
              nullable: true
            timezone:
              type: string
              description: IANA tz
              nullable: true
            location_locode:
              type: string
              description: UNLOCODE of the event location
              nullable: true
            created_at:
              type: string
              format: date-time
            data_source:
              type: string
              enum:
                - shipping_line
                - terminal
                - ais
              example: shipping_line
              description: The original source of the event data
        relationships:
          type: object
          properties:
            shipment:
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
                        - shipment
            location:
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
                        - port
                        - metro_area
            vessel:
              type: object
              properties:
                data:
                  type: object
                  nullable: true
                  properties:
                    id:
                      type: string
                      format: uuid
                    name:
                      type: string
                      enum:
                        - vessel
            terminal:
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
                        - terminal
                        - rail_terminal
            container:
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
                        - container
      required:
        - id
        - type
    estimated_event:
      title: Estimated Event Model
      type: object
      properties:
        id:
          type: string
          format: uuid
        type:
          type: string
          enum:
            - estimated_event
        attributes:
          type: object
          required:
            - created_at
            - estimated_timestamp
            - event
          properties:
            created_at:
              type: string
              description: When the estimated event was created
              format: date-time
            estimated_timestamp:
              type: string
              format: date-time
            event:
              type: string
              enum:
                - shipment.estimated.arrival
            location_locode:
              type: string
              description: UNLOCODE of the event location
              nullable: true
            timezone:
              type: string
              description: IANA tz
              nullable: true
            voyage_number:
              type: string
              nullable: true
            data_source:
              type: string
              enum:
                - shipping_line
                - terminal
              description: The original source of the event data
        relationships:
          type: object
          required:
            - shipment
          properties:
            shipment:
              type: object
              required:
                - data
              properties:
                data:
                  type: object
                  required:
                    - id
                    - type
                  properties:
                    id:
                      type: string
                      format: uuid
                    type:
                      type: string
                      enum:
                        - shipment
            port:
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
                        - port
            vessel:
              type: object
              description: |+

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
                        - vessel
      required:
        - id
        - type
        - attributes
        - relationships
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