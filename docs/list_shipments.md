# List shipments

> Returns a list of your shipments. The shipments are returned sorted by creation date, with the most recent shipments appearing first.

This api will return all shipments associated with the account. Shipments created via the `tracking_request` API aswell as the ones added via the dashboard will be retuned via this endpoint. 



## OpenAPI

````yaml get /shipments
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
  /shipments:
    get:
      tags:
        - Shipments
      summary: List shipments
      description: >-
        Returns a list of your shipments. The shipments are returned sorted by
        creation date, with the most recent shipments appearing first.


        This api will return all shipments associated with the account.
        Shipments created via the `tracking_request` API aswell as the ones
        added via the dashboard will be retuned via this endpoint. 
      operationId: get-shipments
      parameters:
        - schema:
            type: integer
            default: 1
          in: query
          name: page[number]
          description: |+

        - schema:
            type: integer
            default: 30
          in: query
          name: page[size]
          description: |+

        - schema:
            type: string
          in: query
          name: q
          description: >-

            Search shipments by master bill of lading, reference number, or
            container number.
          deprecated: true
        - schema:
            type: string
          in: query
          name: include
          description: Comma delimited list of relations to include
        - schema:
            type: string
          in: query
          name: number
          description: Search shipments by the original request tracking `request_number`
        - schema:
            type: boolean
          in: query
          name: filter[tracking_stopped]
          description: Filter shipments by whether they are still tracking or not
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
                      $ref: '#/components/schemas/shipment'
                  included:
                    type: array
                    items:
                      anyOf:
                        - $ref: '#/components/schemas/container'
                        - $ref: '#/components/schemas/port'
                        - $ref: '#/components/schemas/terminal'
                  links:
                    $ref: '#/components/schemas/links'
                  meta:
                    $ref: '#/components/schemas/meta'
              examples:
                En-route to NY with inland move:
                  value:
                    data:
                      - id: 62738624-7032-4a50-892e-c55826228c25
                        type: shipment
                        attributes:
                          created_at: '2024-06-26T17:28:59Z'
                          ref_numbers: []
                          tags: []
                          bill_of_lading_number: OOLU2148468620
                          normalized_number: '2148468620'
                          shipping_line_scac: OOLU
                          shipping_line_name: Orient Overseas Container Line
                          shipping_line_short_name: OOCL
                          customer_name: Sodor Steamworks
                          port_of_lading_locode: CNNBG
                          port_of_lading_name: Ningbo
                          port_of_discharge_locode: USLAX
                          port_of_discharge_name: Los Angeles
                          pod_vessel_name: EVER FORWARD
                          pod_vessel_imo: '9850551'
                          pod_voyage_number: 1119E
                          destination_locode: USCLE
                          destination_name: Cleveland
                          destination_timezone: America/New_York
                          destination_ata_at: null
                          destination_eta_at: '2024-07-02T08:00:00Z'
                          pol_etd_at: null
                          pol_atd_at: '2024-06-09T03:42:00Z'
                          pol_timezone: Asia/Shanghai
                          pod_eta_at: null
                          pod_original_eta_at: null
                          pod_ata_at: '2024-06-22T13:36:00Z'
                          pod_timezone: America/Los_Angeles
                          line_tracking_last_attempted_at: '2024-06-26T17:28:59Z'
                          line_tracking_last_succeeded_at: '2024-06-26T17:28:59Z'
                          line_tracking_stopped_at: null
                          line_tracking_stopped_reason: null
                        links:
                          self: /v2/shipments/62738624-7032-4a50-892e-c55826228c25
                        relationships:
                          port_of_lading:
                            data:
                              id: 2a90c27b-c2ee-45e2-892f-5c695d74e2d0
                              type: port
                          port_of_discharge:
                            data:
                              id: 47b27584-4ec9-4e2f-95e1-7a42928cc40c
                              type: port
                          pod_terminal:
                            data:
                              id: 42c53b13-0d29-4fa6-8663-7343a56319f1
                              type: terminal
                          destination:
                            data:
                              id: 3b1cc325-ffe9-400a-82ce-f5c4891af382
                              type: port
                          destination_terminal:
                            data:
                              id: ce22669e-14b2-4501-b782-f0a360f07cd0
                              type: terminal
                          line_tracking_stopped_by_user:
                            data: null
                          containers:
                            data:
                              - id: 7aefc29e-0898-4825-8376-4f998b51d033
                                type: container
                      - id: baaa725e-aa0e-4937-ac78-54d9e2e8621e
                        type: shipment
                        attributes:
                          created_at: '2024-06-26T16:47:42Z'
                          ref_numbers: []
                          tags: []
                          bill_of_lading_number: HDMUTAOM72244900
                          normalized_number: TAOM72244900
                          shipping_line_scac: HDMU
                          shipping_line_name: Hyundai Merchant Marine
                          shipping_line_short_name: Hyundai
                          customer_name: Sodor Steamworks
                          port_of_lading_locode: CNQDG
                          port_of_lading_name: Qingdao
                          port_of_discharge_locode: USSAV
                          port_of_discharge_name: Savannah
                          pod_vessel_name: UMM SALAL
                          pod_vessel_imo: '9525857'
                          pod_voyage_number: 0038E
                          destination_locode: USROQ
                          destination_name: Rossville
                          destination_timezone: America/Chicago
                          destination_ata_at: null
                          destination_eta_at: '2024-06-30T07:05:00Z'
                          pol_etd_at: null
                          pol_atd_at: '2024-05-07T03:01:00Z'
                          pol_timezone: Asia/Shanghai
                          pod_eta_at: null
                          pod_original_eta_at: null
                          pod_ata_at: '2024-06-20T21:27:00Z'
                          pod_timezone: America/New_York
                          line_tracking_last_attempted_at: '2024-06-26T16:48:04Z'
                          line_tracking_last_succeeded_at: '2024-06-26T16:48:04Z'
                          line_tracking_stopped_at: null
                          line_tracking_stopped_reason: null
                        links:
                          self: /v2/shipments/baaa725e-aa0e-4937-ac78-54d9e2e8621e
                        relationships:
                          port_of_lading:
                            data:
                              id: 0ccbe8af-c8d0-4abd-a842-3bfad1d82024
                              type: port
                          port_of_discharge:
                            data:
                              id: 6129528d-846e-4571-ae16-b5328a4285ab
                              type: port
                          pod_terminal:
                            data:
                              id: a243bdf8-0da3-4056-a6a7-05fe8ab43999
                              type: terminal
                          destination:
                            data:
                              id: 87ca3f37-e4d1-46eb-9eb1-6b5ffafde95d
                              type: port
                          destination_terminal:
                            data: null
                          line_tracking_stopped_by_user:
                            data: null
                          containers:
                            data:
                              - id: 772cd872-9677-4c68-9b7a-4e9e843b00e2
                                type: container
                              - id: 52efc544-0de1-452f-bcf8-0290a6ce5c11
                                type: container
                              - id: 3107692e-61ad-4b4c-b3d4-78348b2e37ff
                                type: container
                      - id: 7721a48c-5e93-43c9-9f5f-5be10a87fdde
                        type: shipment
                        attributes:
                          created_at: '2024-06-26T16:28:39Z'
                          ref_numbers: []
                          tags: []
                          bill_of_lading_number: OOLU2738424980
                          normalized_number: '2738424980'
                          shipping_line_scac: OOLU
                          shipping_line_name: Orient Overseas Container Line
                          shipping_line_short_name: OOCL
                          customer_name: Sodor Steamworks
                          port_of_lading_locode: ITSPE
                          port_of_lading_name: La Spezia
                          port_of_discharge_locode: USSAV
                          port_of_discharge_name: Savannah
                          pod_vessel_name: OOCL GUANGZHOU
                          pod_vessel_imo: '9404869'
                          pod_voyage_number: 162E
                          destination_locode: USATL
                          destination_name: Atlanta
                          destination_timezone: America/New_York
                          destination_ata_at: null
                          destination_eta_at: '2024-06-27T06:42:00Z'
                          pol_etd_at: null
                          pol_atd_at: '2024-06-05T08:03:00Z'
                          pol_timezone: Europe/Rome
                          pod_eta_at: null
                          pod_original_eta_at: null
                          pod_ata_at: '2024-06-23T15:34:00Z'
                          pod_timezone: America/New_York
                          line_tracking_last_attempted_at: '2024-06-26T16:28:39Z'
                          line_tracking_last_succeeded_at: '2024-06-26T16:28:39Z'
                          line_tracking_stopped_at: null
                          line_tracking_stopped_reason: null
                        links:
                          self: /v2/shipments/7721a48c-5e93-43c9-9f5f-5be10a87fdde
                        relationships:
                          port_of_lading:
                            data:
                              id: b5656766-a56f-4b32-8e03-d240e7519604
                              type: port
                          port_of_discharge:
                            data:
                              id: 6129528d-846e-4571-ae16-b5328a4285ab
                              type: port
                          pod_terminal:
                            data:
                              id: a243bdf8-0da3-4056-a6a7-05fe8ab43999
                              type: terminal
                          destination:
                            data:
                              id: 7daf9ea3-3018-4d62-b88c-43803df9030c
                              type: port
                          destination_terminal:
                            data:
                              id: 022ef8fc-1e2a-4ad6-8eae-330d65eb1c8e
                              type: terminal
                          line_tracking_stopped_by_user:
                            data: null
                          containers:
                            data:
                              - id: 2a25fd3e-a18e-47cc-9cea-62771e82d0f2
                                type: container
                              - id: 6cdc725d-2b31-40f9-86dd-76225390a488
                                type: container
                              - id: 2f1e9a9d-4689-4f4d-84a8-64409b56521d
                                type: container
                      - id: 32b5ad78-43ba-42d9-bdc0-4cf12320e020
                        type: shipment
                        attributes:
                          created_at: '2024-06-26T15:59:52Z'
                          ref_numbers: []
                          tags: []
                          bill_of_lading_number: OOLU2738277190
                          normalized_number: '2738277190'
                          shipping_line_scac: OOLU
                          shipping_line_name: Orient Overseas Container Line
                          shipping_line_short_name: OOCL
                          customer_name: Sodor Steamworks
                          port_of_lading_locode: CNQDG
                          port_of_lading_name: Qingdao
                          port_of_discharge_locode: USLAX
                          port_of_discharge_name: Los Angeles
                          pod_vessel_name: EVER FORWARD
                          pod_vessel_imo: '9850551'
                          pod_voyage_number: 1119E
                          destination_locode: USMEM
                          destination_name: Memphis
                          destination_timezone: America/Chicago
                          destination_ata_at: null
                          destination_eta_at: '2024-07-01T14:00:00Z'
                          pol_etd_at: null
                          pol_atd_at: '2024-06-02T18:22:00Z'
                          pol_timezone: Asia/Shanghai
                          pod_eta_at: null
                          pod_original_eta_at: null
                          pod_ata_at: '2024-06-22T13:36:00Z'
                          pod_timezone: America/Los_Angeles
                          line_tracking_last_attempted_at: '2024-06-26T15:59:52Z'
                          line_tracking_last_succeeded_at: '2024-06-26T15:59:52Z'
                          line_tracking_stopped_at: null
                          line_tracking_stopped_reason: null
                        links:
                          self: /v2/shipments/32b5ad78-43ba-42d9-bdc0-4cf12320e020
                        relationships:
                          port_of_lading:
                            data:
                              id: 0ccbe8af-c8d0-4abd-a842-3bfad1d82024
                              type: port
                          port_of_discharge:
                            data:
                              id: 47b27584-4ec9-4e2f-95e1-7a42928cc40c
                              type: port
                          pod_terminal:
                            data:
                              id: 42c53b13-0d29-4fa6-8663-7343a56319f1
                              type: terminal
                          destination:
                            data:
                              id: ba0b9f68-2025-40ca-ae12-1c2210cca333
                              type: port
                          destination_terminal:
                            data:
                              id: d0ec0da1-8a3a-4b11-b1e3-5716bbc71dc3
                              type: terminal
                          line_tracking_stopped_by_user:
                            data: null
                          containers:
                            data:
                              - id: 60d2fd62-14e2-4ca2-a927-9633fc58fdff
                                type: container
                              - id: 0ffe3e75-b3df-4d20-b9f4-97bbbcec404d
                                type: container
                      - id: bd117d3b-8fa4-487c-9bab-25c15e227d1a
                        type: shipment
                        attributes:
                          created_at: '2024-06-26T15:59:35Z'
                          ref_numbers: []
                          tags: []
                          bill_of_lading_number: OOLU2147973020
                          normalized_number: '2147973020'
                          shipping_line_scac: OOLU
                          shipping_line_name: Orient Overseas Container Line
                          shipping_line_short_name: OOCL
                          customer_name: Sodor Steamworks
                          port_of_lading_locode: IDSUB
                          port_of_lading_name: Surabaya
                          port_of_discharge_locode: USLAX
                          port_of_discharge_name: Los Angeles
                          pod_vessel_name: CMA CGM A.LINCOLN
                          pod_vessel_imo: '9780859'
                          pod_voyage_number: 1TU70E1MA
                          destination_locode: null
                          destination_name: null
                          destination_timezone: null
                          destination_ata_at: null
                          destination_eta_at: null
                          pol_etd_at: null
                          pol_atd_at: '2024-05-14T02:37:00Z'
                          pol_timezone: Asia/Jakarta
                          pod_eta_at: null
                          pod_original_eta_at: null
                          pod_ata_at: '2024-06-23T21:58:00Z'
                          pod_timezone: America/Los_Angeles
                          line_tracking_last_attempted_at: '2024-06-26T15:59:35Z'
                          line_tracking_last_succeeded_at: '2024-06-26T15:59:35Z'
                          line_tracking_stopped_at: null
                          line_tracking_stopped_reason: null
                        links:
                          self: /v2/shipments/bd117d3b-8fa4-487c-9bab-25c15e227d1a
                        relationships:
                          port_of_lading:
                            data:
                              id: 4201ab42-c51f-48ac-b7a1-12146e02c6a2
                              type: port
                          port_of_discharge:
                            data:
                              id: 47b27584-4ec9-4e2f-95e1-7a42928cc40c
                              type: port
                          pod_terminal:
                            data:
                              id: eaa2580c-5f5b-4198-85e4-821145d62098
                              type: terminal
                          destination:
                            data: null
                          destination_terminal:
                            data: null
                          line_tracking_stopped_by_user:
                            data: null
                          containers:
                            data:
                              - id: 815ff702-fdb5-4455-a28e-314c345d7481
                                type: container
                    meta:
                      size: 5
                      total: 34044
                    links:
                      self: https://api.terminal49.com/v2/shipments?page[size]=5
                      current: >-
                        https://api.terminal49.com/v2/shipments?page[number]=1&page[size]=5
                      next: >-
                        https://api.terminal49.com/v2/shipments?page[number]=2&page[size]=5
                      last: >-
                        https://api.terminal49.com/v2/shipments?page[number]=6809&page[size]=5
        '422':
          description: Unprocessable Entity
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
                Errors:
                  value:
                    error:
                      - title: Invalid arrival_date_from
                        detail: >-
                          filter['arrival_from'] must be in the format
                          'YYYY-MM-DD' and a valid date
                      - title: Invalid arrival_date_to
                        detail: >-
                          filter['arrival_from'] must be in the format
                          'YYYY-MM-DD' and a valid date
                      - title: Invalid port_of_lading
                        detail: >-
                          port_of_discharge must be an array of 5 character
                          UN/LOCODEs
                      - title: Invalid port_of_discharge
                        detail: >-
                          port_of_discharge must be an array of 5 character
                          UN/LOCODEs
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
    container:
      title: Container model
      type: object
      x-examples:
        Example Container:
          id: ff77a822-23a7-4ccd-95ca-g534c071baaf3
          type: container
          attributes:
            number: KOCU4959010
            ref_numbers:
              - REF-1
              - REF-2
            seal_number: '210084213'
            created_at: '2021-10-18T09:52:33Z'
            equipment_type: dry
            equipment_length: 40
            equipment_height: high_cube
            weight_in_lbs: 20210
            fees_at_pod_terminal: []
            holds_at_pod_terminal: []
            pickup_lfd: '2022-01-21T08:00:00Z'
            pickup_appointment_at: null
            pod_full_out_chassis_number: APMZ418805
            location_at_pod_terminal: Delivered 02/11/2022 14:18
            availability_known: true
            available_for_pickup: false
            pod_arrived_at: '2022-01-03T10:30:00Z'
            pod_discharged_at: '2022-01-08T09:15:00Z'
            final_destination_full_out_at: null
            pod_full_out_at: '2022-02-11T22:18:00Z'
            empty_terminated_at: null
            terminal_checked_at: '2022-02-11T22:45:32Z'
            pod_rail_carrier_scac: UPRR
            ind_rail_carrier_scac: CSXT
            pod_timezone: America/Los_Angeles
            final_destination_timezone: null
            empty_terminated_timezone: null
            pod_last_tracking_request_at: '2022-02-11T22:40:00Z'
            shipment_last_tracking_request_at: '2022-02-11T22:40:00Z'
            pod_rail_loaded_at: '2022-02-11T22:18:00Z'
            pod_rail_departed_at: '2022-02-11T23:30:00Z'
            ind_eta_at: null
            ind_ata_at: '2022-02-15T01:12:00Z'
            ind_rail_unloaded_at: '2022-02-15T07:54:00Z'
            ind_facility_lfd_on: null
            import_deadlines:
              pickup_lfd_terminal: null
              pickup_lfd_rail: '2022-02-20T08:00:00Z'
              pickup_lfd_line: '2022-02-25T08:00:00Z'
            current_status: delivered
          relationships:
            shipment:
              data:
                id: x92acf88-c263-43ddf-b005-aca2a32d47f1
                type: shipment
            pod_terminal:
              data:
                id: x551cac7-aff5-40a6-9c63-49facf19cc3df
                type: terminal
            pickup_facility:
              data:
                id: d7d8d314-b02b-4caa-b04f-d3d4726f4107
                type: terminal
            transport_events:
              data:
                - id: xecfe2d1-c498-4022-a9f8-ec56722e1215
                  type: transport_event
                - id: 2900a9b8-d9e2-4696-abd86-4a767b885d23
                  type: transport_event
                - id: 5ad0dce1-x78e4-464d-af5f-a36190428a2c
                  type: transport_event
                - id: 876575d5-5ede-40d6-a093-c3a4cfcxaa1c7
                  type: transport_event
                - id: dc2a9d8f-75e6-43xa5-a04e-58458495f08c
                  type: transport_event
                - id: 50xd2ea1-01ac-473d-8a08-3b5d77d2b793
                  type: transport_event
                - id: 9d1f55xe3-6758-4be7-872a-30451ddd957e
                  type: transport_event
            raw_events:
              data:
                - id: 38084a1d-a2eb-434e-81ac3-606c89a61c4b
                  type: raw_event
                - id: 53680df3-93d5-4385-86c5-a33ee41b4c1f
                  type: raw_event
                - id: 7d9cdf70-51e8-4b75-a8229-f5d691495ab6
                  type: raw_event
                - id: e62d41ac-8738-42e8-b582-35ef28ae88e2
                  type: raw_event
                - id: 1209172b-acd8-4ce0-8821-dbc4934208b3
                  type: raw_event
                - id: 4265ea5f-2b9a-436f-98fa-803d8ed49acb2
                  type: raw_event
                - id: c3cb2eb7-6c0a-4db8-8742-517b97b175d5
                  type: raw_event
                - id: b1959f36-a218-4b6e-863a9-2e0b4ad5159c
                  type: raw_event
      description: Represents the equipment during a specific journey.
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
          properties:
            number:
              type: string
            ref_numbers:
              type: array
              items:
                type: string
            equipment_type:
              type: string
              enum:
                - dry
                - reefer
                - open top
                - flat rack
                - bulk
                - tank
                - null
              nullable: true
            equipment_length:
              type: integer
              enum:
                - null
                - 10
                - 20
                - 40
                - 45
              nullable: true
            equipment_height:
              type: string
              enum:
                - standard
                - high_cube
                - null
              nullable: true
            weight_in_lbs:
              type: number
              nullable: true
            created_at:
              type: string
              format: date-time
            seal_number:
              type: string
              nullable: true
            pickup_lfd:
              type: string
              format: date-time
              description: >-
                Coalesces `import_deadlines` values giving preference to
                `pickup_lfd_line`
              nullable: true
            pickup_appointment_at:
              type: string
              format: date-time
              description: >-
                When available the pickup appointment time at the terminal is
                returned.
              nullable: true
            availability_known:
              type: boolean
              description: >-
                Whether Terminal 49 is receiving availability status from the
                terminal.
            available_for_pickup:
              type: boolean
              description: >-
                If availability_known is true, then whether container is
                available to be picked up at terminal.
              nullable: true
            pod_arrived_at:
              type: string
              format: date-time
              description: Time the vessel arrived at the POD
              nullable: true
            pod_discharged_at:
              type: string
              format: date-time
              description: Discharge time at the port of discharge
              nullable: true
            pod_full_out_at:
              type: string
              format: date-time
              description: Full Out time at port of discharge. Null for inland moves.
              nullable: true
            terminal_checked_at:
              type: string
              format: date-time
              description: When the terminal was last checked.
              nullable: true
            pod_full_out_chassis_number:
              type: string
              description: >-
                The chassis number used when container was picked up at POD (if
                available)
              nullable: true
            location_at_pod_terminal:
              type: string
              description: Location at port of discharge terminal
              nullable: true
            final_destination_full_out_at:
              type: string
              format: date-time
              description: Pickup time at final destination for inland moves.
              nullable: true
            empty_terminated_at:
              type: string
              format: date-time
              description: Time empty container was returned.
              nullable: true
            holds_at_pod_terminal:
              type: array
              items:
                $ref: '#/components/schemas/terminal_hold'
            fees_at_pod_terminal:
              type: array
              items:
                $ref: '#/components/schemas/terminal_fee'
            pod_timezone:
              type: string
              description: >-
                IANA tz. Applies to attributes pod_arrived_at,
                pod_discharged_at, pickup_appointment_at, pod_full_out_at.
              nullable: true
            final_destination_timezone:
              type: string
              description: IANA tz. Applies to attribute final_destination_full_out_at.
              nullable: true
            empty_terminated_timezone:
              type: string
              description: IANA tz. Applies to attribute empty_terminated_at.
              nullable: true
            pod_rail_carrier_scac:
              type: string
              description: >-
                The SCAC of the rail carrier for the pickup leg of the
                container's journey.(BETA)
              nullable: true
            ind_rail_carrier_scac:
              type: string
              description: >-
                The SCAC of the rail carrier for the delivery leg of the
                container's journey.(BETA)
              nullable: true
            pod_last_tracking_request_at:
              type: string
              format: date-time
              nullable: true
            shipment_last_tracking_request_at:
              type: string
              format: date-time
              nullable: true
            pod_rail_loaded_at:
              type: string
              format: date-time
              nullable: true
            pod_rail_departed_at:
              type: string
              format: date-time
              nullable: true
            ind_eta_at:
              type: string
              format: date-time
              nullable: true
            ind_ata_at:
              type: string
              format: date-time
              nullable: true
            ind_rail_unloaded_at:
              type: string
              format: date-time
              nullable: true
            ind_facility_lfd_on:
              type: string
              format: date-time
              description: Please use `import_deadlines.pickup_lfd_rail`
              nullable: true
              deprecated: true
            import_deadlines:
              type: object
              description: Import pickup deadlines for the container
              properties:
                pickup_lfd_terminal:
                  type: string
                  format: date-time
                  description: >-
                    The last free day for pickup before demmurage accrues.
                    Corresponding timezone is pod_timezone.
                  nullable: true
                pickup_lfd_rail:
                  type: string
                  format: date-time
                  description: >-
                    The last free day for pickup before demmurage accrues.
                    Corresponding timezone is final_destination_timezone.
                  nullable: true
                pickup_lfd_line:
                  type: string
                  format: date-time
                  description: >-
                    The last free day as reported by the line. Corresponding
                    timezone is final_destination_timezone or pod_timezone.
                  nullable: true
              nullable: true
            current_status:
              type: string
              description: >-
                The current status of the container in its journey. [Read guide
                to learn more.](/api-docs/in-depth-guides/container-statuses)
              enum:
                - new
                - on_ship
                - available
                - not_available
                - grounded
                - on_rail
                - picked_up
                - off_dock
                - delivered
                - dropped
                - loaded
                - empty_returned
                - awaiting_inland_transfer
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
                    type:
                      type: string
                      enum:
                        - shipment
            pickup_facility:
              type: object
              properties:
                data:
                  type: object
                  properties:
                    id:
                      type: string
                    type:
                      type: string
                      enum:
                        - terminal
            pod_terminal:
              type: object
              properties:
                data:
                  type: object
                  properties:
                    id:
                      type: string
                    type:
                      type: string
                      enum:
                        - terminal
            transport_events:
              type: object
              properties:
                data:
                  type: array
                  items:
                    type: object
                    properties:
                      id:
                        type: string
                      type:
                        type: string
                        enum:
                          - transport_event
            raw_events:
              type: object
              properties:
                data:
                  type: array
                  items:
                    type: object
                    properties:
                      id:
                        type: string
                      type:
                        type: string
                        enum:
                          - raw_event
      required:
        - id
        - type
        - attributes
    port:
      title: Port model
      type: object
      properties:
        id:
          type: string
          format: uuid
        attributes:
          type: object
          properties:
            name:
              type: string
            code:
              type: string
              description: UN/LOCODE
            state_abbr:
              type: string
              x-stoplight:
                id: jixah1a0q3exs
              nullable: true
            city:
              type: string
              x-stoplight:
                id: 657ij4boc7kyv
              nullable: true
            country_code:
              type: string
              description: 2 digit country code
            time_zone:
              type: string
              description: IANA tz
            latitude:
              type: number
              x-stoplight:
                id: 480os7a90z6kk
              nullable: true
            longitude:
              type: number
              x-stoplight:
                id: nfdetqgx5p1yv
              nullable: true
        type:
          type: string
          enum:
            - port
      required:
        - id
        - type
    terminal:
      title: Terminal model
      type: object
      properties:
        id:
          type: string
          format: uuid
        relationships:
          type: object
          required:
            - port
          properties:
            port:
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
                        - port
        attributes:
          type: object
          required:
            - name
          properties:
            name:
              type: string
            nickname:
              type: string
            firms_code:
              type: string
              description: CBP FIRMS Code or CBS Sublocation Code
            smdg_code:
              type: string
              description: SMDG Code
            bic_facility_code:
              type: string
              description: BIC Facility Code
            street:
              type: string
              description: Street part of the address
            city:
              type: string
              description: City part of the address
            state:
              type: string
              description: State part of the address
            state_abbr:
              type: string
              description: State abbreviation for the state
            zip:
              type: string
              description: ZIP code part of the address
            country:
              type: string
              description: Country part of the address
        type:
          type: string
          enum:
            - terminal
      required:
        - attributes
        - relationships
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
    terminal_hold:
      title: terminal_hold
      type: object
      properties:
        name:
          type: string
        status:
          type: string
          enum:
            - pending
            - hold
        description:
          type: string
          description: Text description from the terminal (if any)
          nullable: true
      required:
        - name
        - status
    terminal_fee:
      title: terminal_fee
      type: object
      properties:
        type:
          type: string
          enum:
            - demurrage
            - exam
            - extended_dwell_time
            - other
            - total
        amount:
          type: number
          description: The fee amount in local currency
        currency_code:
          type: string
          description: The ISO 4217 currency code of the fee is charged in. E.g. USD
          example: USD
      required:
        - type
        - amount
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