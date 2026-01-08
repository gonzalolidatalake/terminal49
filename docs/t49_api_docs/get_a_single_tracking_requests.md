# Get a single tracking request

> Get the details and status of an existing tracking request. 



## OpenAPI

````yaml get /tracking_requests/{id}
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
    get:
      tags:
        - Tracking Requests
      summary: Get a single tracking request
      description: 'Get the details and status of an existing tracking request. '
      operationId: get-track-request-by-id
      parameters:
        - schema:
            type: string
          in: query
          name: include
          description: >-
            Comma delimited list of relations to include. 'tracked_object' is
            included by default.
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
                  included:
                    type: array
                    items:
                      anyOf:
                        - $ref: '#/components/schemas/account'
                        - $ref: '#/components/schemas/shipment'
                        - $ref: '#/components/schemas/shipping_line'
              examples:
                With Status Created:
                  value:
                    data:
                      id: ba4cb904-827f-4038-8e31-1e92b3356218
                      type: tracking_request
                      attributes:
                        request_number: MEDUFR030802
                        request_type: bill_of_lading
                        scac: MSCU
                        ref_numbers: []
                        created_at: '2020-04-04T16:13:35-07:00'
                        updated_at: '2020-04-04T17:13:35-07:00'
                        status: created
                        failed_reason: null
                      relationships:
                        tracked_object:
                          data:
                            id: eb6f218a-0b4a-47f9-8ef9-759aa5e0ea83
                            type: shipment
                      links:
                        self: >-
                          /v2/tracking_requests/ba4cb904-827f-4038-8e31-1e92b3356218
                    included:
                      - id: eb6f218a-0b4a-47f9-8ef9-759aa5e0ea83
                        type: shipment
                        attributes:
                          created_at: '2020-04-04T16:13:37-07:00'
                          bill_of_lading_number: MEDUFR030802
                          ref_numbers: []
                          shipping_line_scac: MSCU
                          shipping_line_name: Mediterranean Shipping Company
                          port_of_lading_locode: FRFOS
                          port_of_lading_name: Fos-Sur-Mer
                          port_of_discharge_locode: USOAK
                          port_of_discharge_name: Oakland
                          pod_vessel_name: MSC ALGECIRAS
                          pod_vessel_imo: '9605243'
                          pod_voyage_number: 920A
                          destination_locode: USOAK
                          destination_name: Oakland
                          destination_timezone: America/Los_Angeles
                          destination_ata_at: '2019-06-21T18:46:00-07:00'
                          destination_eta_at: null
                          pol_etd_at: null
                          pol_atd_at: '2019-05-24T03:00:00-07:00'
                          pol_timezone: Europe/Paris
                          pod_eta_at: null
                          pod_ata_at: '2019-06-21T18:46:00-07:00'
                          pod_timezone: America/Los_Angeles
                        relationships:
                          port_of_lading:
                            data:
                              id: 6d8c6c29-72a6-49ad-87b7-fd045f202212
                              type: port
                          port_of_discharge:
                            data:
                              id: 42d1ba3a-f4b8-431d-a6fe-49fd748a59e7
                              type: port
                          pod_terminal:
                            data: null
                          destination:
                            data:
                              id: 42d1ba3a-f4b8-431d-a6fe-49fd748a59e7
                              type: port
                          containers:
                            data:
                              - id: 11c1fa10-52a5-48e2-82f4-5523756b3d0f
                                type: container
                        links:
                          self: /v2/shipments/eb6f218a-0b4a-47f9-8ef9-759aa5e0ea83
                Multiple containers:
                  value:
                    data:
                      id: 62c30bd4-d7fc-40dc-9fd6-fb39224301f5
                      type: tracking_request
                      attributes:
                        request_number: '212157148'
                        request_type: bill_of_lading
                        scac: MAEU
                        ref_numbers: []
                        shipment_tags: []
                        created_at: '2021-07-27T16:44:14Z'
                        updated_at: '2021-07-27T17:44:14Z'
                        status: created
                        failed_reason: null
                        is_retrying: false
                        retry_count: null
                      relationships:
                        tracked_object:
                          data:
                            id: dfc9f601-f6fe-412e-a71c-feabcc2dd4e3
                            type: shipment
                        customer:
                          data: null
                      links:
                        self: >-
                          /v2/tracking_requests/62c30bd4-d7fc-40dc-9fd6-fb39224301f5
                    links:
                      self: >-
                        https://api.terminal49.com/v2/tracking_requests/62c30bd4-d7fc-40dc-9fd6-fb39224301f5?filter%5Bstatus%5D=created
                    included:
                      - id: dfc9f601-f6fe-412e-a71c-feabcc2dd4e3
                        type: shipment
                        attributes:
                          created_at: '2021-07-27T16:44:16Z'
                          ref_numbers: null
                          tags: []
                          bill_of_lading_number: '212157148'
                          shipping_line_scac: MAEU
                          shipping_line_name: Maersk
                          shipping_line_short_name: Maersk
                          port_of_lading_locode: MYTPP
                          port_of_lading_name: Tanjung Pelepas
                          port_of_discharge_locode: null
                          port_of_discharge_name: null
                          pod_vessel_name: null
                          pod_vessel_imo: null
                          pod_voyage_number: null
                          destination_locode: null
                          destination_name: null
                          destination_timezone: null
                          destination_ata_at: null
                          destination_eta_at: null
                          pol_etd_at: null
                          pol_atd_at: null
                          pol_timezone: Asia/Kuala_Lumpur
                          pod_eta_at: '2021-09-15T15:00:00Z'
                          pod_ata_at: null
                          pod_timezone: null
                          line_tracking_last_attempted_at: null
                          line_tracking_last_succeeded_at: '2021-07-27T16:44:16Z'
                          line_tracking_stopped_at: null
                          line_tracking_stopped_reason: null
                        relationships:
                          port_of_lading:
                            data:
                              id: 6c387786-252c-476d-9f99-7d835b6b978b
                              type: port
                          port_of_discharge:
                            data: null
                          pod_terminal:
                            data: null
                          destination:
                            data: null
                          destination_terminal:
                            data: null
                          containers:
                            data:
                              - id: 965880c9-a37e-4ed7-a060-9c49c0f0c5ed
                                type: container
                              - id: ea1f8e08-fcdf-498d-9cb5-0c370b023eeb
                                type: container
                              - id: 67f55105-8ea2-4137-9244-f9cc204f5766
                                type: container
                              - id: 5ab5d058-772c-466c-bc73-0b8767ad5a79
                                type: container
                        links:
                          self: /v2/shipments/dfc9f601-f6fe-412e-a71c-feabcc2dd4e3
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
    shipment:
      title: Shipment model
      type: object
      x-examples: {}
      description: ''
      properties:
        id:
          type: string
          format: uuid
        relationships:
          type: object
          properties:
            destination:
              type: object
              properties:
                data:
                  type: object
                  nullable: true
                  properties:
                    type:
                      type: string
                      enum:
                        - port
                        - metro_area
                    id:
                      type: string
                      format: uuid
                  required:
                    - type
                    - id
            port_of_lading:
              type: object
              properties:
                data:
                  type: object
                  nullable: true
                  properties:
                    type:
                      type: string
                      enum:
                        - port
                    id:
                      type: string
                      format: uuid
                  required:
                    - type
                    - id
            containers:
              type: object
              properties:
                data:
                  type: array
                  items:
                    type: object
                    properties:
                      type:
                        type: string
                        enum:
                          - container
                      id:
                        type: string
                        format: uuid
                    required:
                      - type
                      - id
            port_of_discharge:
              type: object
              properties:
                data:
                  type: object
                  nullable: true
                  properties:
                    type:
                      type: string
                      enum:
                        - port
                    id:
                      type: string
                      format: uuid
                  required:
                    - type
                    - id
            pod_terminal:
              type: object
              properties:
                data:
                  type: object
                  properties:
                    type:
                      type: string
                      enum:
                        - terminal
                    id:
                      type: string
                      format: uuid
                  required:
                    - type
                    - id
            destination_terminal:
              type: object
              properties:
                data:
                  type: object
                  properties:
                    type:
                      type: string
                      enum:
                        - terminal
                        - rail_terminal
                    id:
                      type: string
                      format: uuid
                  required:
                    - type
                    - id
            line_tracking_stopped_by_user:
              type: object
              properties:
                data:
                  type: object
                  properties:
                    type:
                      type: string
                      enum:
                        - user
                    id:
                      type: string
                      format: uuid
                  required:
                    - type
                    - id
        attributes:
          type: object
          properties:
            bill_of_lading_number:
              type: string
            normalized_number:
              type: string
              description: >-
                The normalized version of the shipment number used for querying
                the carrier
            ref_numbers:
              type: array
              items:
                type: string
              nullable: true
            created_at:
              type: string
              format: date-time
            tags:
              type: array
              items:
                type: string
            port_of_lading_locode:
              type: string
              description: UN/LOCODE
              nullable: true
            port_of_lading_name:
              type: string
              nullable: true
            port_of_discharge_locode:
              type: string
              description: UN/LOCODE
              nullable: true
            port_of_discharge_name:
              type: string
              nullable: true
            destination_locode:
              type: string
              description: UN/LOCODE
              nullable: true
            destination_name:
              type: string
              nullable: true
            shipping_line_scac:
              type: string
            shipping_line_name:
              type: string
            shipping_line_short_name:
              type: string
            customer_name:
              type: string
              nullable: true
            pod_vessel_name:
              type: string
              nullable: true
            pod_vessel_imo:
              type: string
              nullable: true
            pod_voyage_number:
              type: string
              nullable: true
            pol_etd_at:
              type: string
              format: date-time
              nullable: true
            pol_atd_at:
              type: string
              format: date-time
              nullable: true
            pod_eta_at:
              type: string
              format: date-time
              nullable: true
            pod_original_eta_at:
              type: string
              format: date-time
              nullable: true
            pod_ata_at:
              type: string
              format: date-time
              nullable: true
            destination_eta_at:
              type: string
              format: date-time
              nullable: true
            destination_ata_at:
              type: string
              format: date-time
              nullable: true
            pol_timezone:
              type: string
              description: IANA tz
              nullable: true
            pod_timezone:
              type: string
              description: IANA tz
              nullable: true
            destination_timezone:
              type: string
              description: IANA tz
              nullable: true
            line_tracking_last_attempted_at:
              type: string
              format: date-time
              description: >-
                When Terminal49 last tried to update the shipment status from
                the shipping line
              nullable: true
            line_tracking_last_succeeded_at:
              type: string
              format: date-time
              description: >-
                When Terminal49 last successfully updated the shipment status
                from the shipping line
              nullable: true
            line_tracking_stopped_at:
              type: string
              format: date-time
              description: When Terminal49 stopped checking at the shipping line
              nullable: true
            line_tracking_stopped_reason:
              type: string
              enum:
                - all_containers_terminated
                - past_arrival_window
                - past_full_out_window
                - no_updates_at_line
                - cancelled_by_user
                - booking_cancelled
                - null
              description: The reason Terminal49 stopped checking
              nullable: true
          required:
            - bill_of_lading_number
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
          required:
            - self
      required:
        - id
        - type
        - attributes
        - relationships
        - links
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