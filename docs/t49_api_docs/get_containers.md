# Get a container

> Retrieves the details of a container.



## OpenAPI

````yaml get /containers/{id}
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
  /containers/{id}:
    parameters:
      - schema:
          type: string
        name: id
        in: path
        required: true
    get:
      tags:
        - Containers
      summary: Get a container
      description: Retrieves the details of a container.
      operationId: get-containers-id
      parameters:
        - schema:
            type: string
          in: query
          name: include
          description: Comma delimited list of relations to include
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    $ref: '#/components/schemas/container'
                  included:
                    type: array
                    items:
                      anyOf:
                        - $ref: '#/components/schemas/shipment'
                        - $ref: '#/components/schemas/terminal'
                        - $ref: '#/components/schemas/transport_event'
              examples:
                Example Container:
                  value:
                    data:
                      id: 55a700e4-7005-45a9-92fd-1ff38641dbd9
                      type: container
                      attributes:
                        number: CAIU7432986
                        seal_number: null
                        created_at: '2024-06-26T15:05:21Z'
                        ref_numbers: []
                        pod_arrived_at: null
                        pod_discharged_at: '2024-06-22T04:00:00Z'
                        final_destination_full_out_at: null
                        holds_at_pod_terminal: []
                        available_for_pickup: true
                        equipment_type: dry
                        equipment_length: 40
                        equipment_height: high_cube
                        weight_in_lbs: null
                        pod_full_out_at: null
                        empty_terminated_at: null
                        terminal_checked_at: '2024-06-26T17:51:12Z'
                        fees_at_pod_terminal: []
                        pickup_lfd: '2024-07-07T04:00:00Z'
                        pickup_appointment_at: null
                        pod_full_out_chassis_number: null
                        location_at_pod_terminal: Yard - Y0709A
                        pod_last_tracking_request_at: '2024-06-26T17:51:12Z'
                        shipment_last_tracking_request_at: '2024-06-26T15:05:20Z'
                        availability_known: true
                        pod_timezone: America/New_York
                        final_destination_timezone: US/Eastern
                        empty_terminated_timezone: US/Eastern
                        pod_rail_carrier_scac: CSXT
                        ind_rail_carrier_scac: CSXT
                        pod_rail_loaded_at: null
                        pod_rail_departed_at: null
                        ind_eta_at: null
                        ind_ata_at: null
                        ind_rail_unloaded_at: null
                        ind_facility_lfd_on: null
                        import_deadlines:
                          pickup_lfd_terminal: '2024-07-07T04:00:00Z'
                          pickup_lfd_rail: null
                          pickup_lfd_line: '2024-07-07T04:00:00Z'
                        current_status: available
                      relationships:
                        shipment:
                          data:
                            id: 02b1bd6f-407c-45bb-8645-06e7ee34e7e3
                            type: shipment
                        pickup_facility:
                          data: null
                        pod_terminal:
                          data:
                            id: b859f5c3-8515-41da-bf20-39c0a5ada887
                            type: terminal
                        transport_events:
                          data:
                            - id: 45b542cb-332b-4684-b915-42e3a0759823
                              type: transport_event
                            - id: 174ed528-a1a9-4002-aef0-f2c9369199da
                              type: transport_event
                            - id: 7a2f30a6-a756-4c14-9477-fbfc1c7fe2f8
                              type: transport_event
                            - id: e7365004-175a-46e8-96cd-dbed0f3daf21
                              type: transport_event
                            - id: 7c567bf3-7f01-4a3d-a176-eaa1f7165585
                              type: transport_event
                        raw_events:
                          data:
                            - id: 2956f71c-bfb9-4e49-b9e2-1b4d53c74cac
                              type: raw_event
                            - id: 391e0eda-65b5-4fc3-a53d-25ecd9570259
                              type: raw_event
                            - id: 74810c04-6c8a-4194-8cff-52936584a965
                              type: raw_event
                            - id: 4b1500e2-b23b-4896-87bd-c38b1d16f385
                              type: raw_event
                            - id: 8b9a7d88-720a-4304-8c1e-a3336e39f481
                              type: raw_event
                            - id: bf1f59c5-5dd8-4013-87f9-d7056bc87114
                              type: raw_event
                    links:
                      self: >-
                        https://api.terminal49.com/v2/containers/55a700e4-7005-45a9-92fd-1ff38641dbd9
components:
  schemas:
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