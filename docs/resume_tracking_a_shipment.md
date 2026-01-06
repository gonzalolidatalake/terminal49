# Resume tracking a shipment

> Resume tracking a shipment.  Keep in mind that some information is only made available by our data sources at specific times, so a stopped and resumed shipment may have some information missing.



## OpenAPI

````yaml patch /shipments/{id}/resume_tracking
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
  /shipments/{id}/resume_tracking:
    parameters:
      - schema:
          type: string
        name: id
        in: path
        required: true
    patch:
      tags:
        - Shipments
      summary: Resume tracking a shipment
      description: >-
        Resume tracking a shipment.  Keep in mind that some information is only
        made available by our data sources at specific times, so a stopped and
        resumed shipment may have some information missing.
      operationId: patch-shipments-id-resume-tracking
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    $ref: '#/components/schemas/shipment'
components:
  schemas:
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