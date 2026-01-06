# Get a container's transport events

> Get a list of past transport events (canonical) for a container. All data has been normalized across all carriers. These are a verified subset of the raw events may also be sent as Webhook Notifications to a webhook endpoint.

This does not provide any estimated future events. See `container/:id/raw_events` endpoint for that.  



## OpenAPI

````yaml get /containers/{id}/transport_events
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
  /containers/{id}/transport_events:
    parameters:
      - schema:
          type: string
        name: id
        in: path
        required: true
    get:
      tags:
        - Containers
      summary: Get a container's transport events
      description: >-
        Get a list of past transport events (canonical) for a container. All
        data has been normalized across all carriers. These are a verified
        subset of the raw events may also be sent as Webhook Notifications to a
        webhook endpoint.


        This does not provide any estimated future events. See
        `container/:id/raw_events` endpoint for that.  
      operationId: get-containers-id-transport_events
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
                    type: array
                    items:
                      $ref: '#/components/schemas/transport_event'
                  included:
                    type: array
                    items:
                      anyOf:
                        - $ref: '#/components/schemas/shipment'
                        - $ref: '#/components/schemas/container'
                        - $ref: '#/components/schemas/port'
                        - $ref: '#/components/schemas/metro_area'
                        - $ref: '#/components/schemas/terminal'
                        - $ref: '#/components/schemas/rail_terminal'
                        - $ref: '#/components/schemas/vessel'
                  links:
                    $ref: '#/components/schemas/links'
                  meta:
                    $ref: '#/components/schemas/meta'
              examples:
                Example transport events:
                  value:
                    data:
                      - id: efc3f3c1-cdc2-4a7d-a176-762ddec107b8
                        type: transport_event
                        attributes:
                          event: container.transport.vessel_loaded
                          created_at: '2021-01-05T08:41:12Z'
                          voyage_number: 15W10
                          timestamp: null
                          location_locode: CLSAI
                          timezone: America/Santiago
                        relationships:
                          shipment:
                            data:
                              id: 06264731-503e-498e-bc76-f90b87b31562
                              type: shipment
                          container:
                            data:
                              id: eeafd337-72b5-4e5c-87cb-9ef83fa99cf4
                              type: container
                          vessel:
                            data:
                              id: 345c05ab-4217-4ffe-a1a4-6c03b9ad2b36
                              type: vessel
                          location:
                            data:
                              id: 0ad2cf2b-e694-4ccc-9cd2-40af0d1fa1b5
                              type: port
                          terminal:
                            data: null
                      - id: 951058bd-2c3b-4bcc-94e1-9be2526b9687
                        type: transport_event
                        attributes:
                          event: container.transport.vessel_departed
                          created_at: '2021-01-05T08:41:11Z'
                          voyage_number: 15W10
                          timestamp: null
                          location_locode: CLSAI
                          timezone: America/Santiago
                        relationships:
                          shipment:
                            data:
                              id: 06264731-503e-498e-bc76-f90b87b31562
                              type: shipment
                          container:
                            data:
                              id: eeafd337-72b5-4e5c-87cb-9ef83fa99cf4
                              type: container
                          vessel:
                            data:
                              id: 345c05ab-4217-4ffe-a1a4-6c03b9ad2b36
                              type: vessel
                          location:
                            data:
                              id: 0ad2cf2b-e694-4ccc-9cd2-40af0d1fa1b5
                              type: port
                          terminal:
                            data: null
                      - id: 69af6795-56c2-4157-9a87-afd761cc85a0
                        type: transport_event
                        attributes:
                          event: container.transport.full_out
                          created_at: '2020-05-14T00:05:41Z'
                          voyage_number: null
                          timestamp: '2020-04-14T00:00:00Z'
                          location_locode: USOAK
                          timezone: America/Los_Angeles
                        relationships:
                          shipment:
                            data:
                              id: 06264731-503e-498e-bc76-f90b87b31562
                              type: shipment
                          container:
                            data:
                              id: eeafd337-72b5-4e5c-87cb-9ef83fa99cf4
                              type: container
                          vessel:
                            data: null
                          location:
                            data:
                              id: 42d1ba3a-f4b8-431d-a6fe-49fd748a59e7
                              type: port
                          terminal:
                            data: null
                      - id: 68c3c29a-504a-4dbb-ad27-7194ef42d484
                        type: transport_event
                        attributes:
                          event: container.transport.vessel_discharged
                          created_at: '2020-05-14T00:05:41Z'
                          voyage_number: 15W10
                          timestamp: '2020-04-13T00:00:00Z'
                          location_locode: USOAK
                          timezone: America/Los_Angeles
                        relationships:
                          shipment:
                            data:
                              id: 06264731-503e-498e-bc76-f90b87b31562
                              type: shipment
                          container:
                            data:
                              id: eeafd337-72b5-4e5c-87cb-9ef83fa99cf4
                              type: container
                          vessel:
                            data:
                              id: 345c05ab-4217-4ffe-a1a4-6c03b9ad2b36
                              type: vessel
                          location:
                            data:
                              id: 42d1ba3a-f4b8-431d-a6fe-49fd748a59e7
                              type: port
                          terminal:
                            data:
                              id: 3e550f0e-ac2a-48fb-b242-5be45ecf2c78
                              type: terminal
                      - id: 03349405-a9be-4f3e-abde-28f2cb3922bd
                        type: transport_event
                        attributes:
                          event: container.transport.vessel_arrived
                          created_at: '2020-05-14T00:05:41Z'
                          voyage_number: 15W10
                          timestamp: '2020-04-13T01:24:00Z'
                          location_locode: USOAK
                          timezone: America/Los_Angeles
                        relationships:
                          shipment:
                            data:
                              id: 06264731-503e-498e-bc76-f90b87b31562
                              type: shipment
                          container:
                            data:
                              id: eeafd337-72b5-4e5c-87cb-9ef83fa99cf4
                              type: container
                          vessel:
                            data:
                              id: 345c05ab-4217-4ffe-a1a4-6c03b9ad2b36
                              type: vessel
                          location:
                            data:
                              id: 42d1ba3a-f4b8-431d-a6fe-49fd748a59e7
                              type: port
                          terminal:
                            data:
                              id: 3e550f0e-ac2a-48fb-b242-5be45ecf2c78
                              type: terminal
                      - id: ba9f85b4-658d-4f23-9308-635964df8037
                        type: transport_event
                        attributes:
                          event: container.transport.empty_in
                          created_at: '2020-05-14T00:05:42Z'
                          voyage_number: null
                          timestamp: '2020-04-15T00:00:00Z'
                          location_locode: null
                          timezone: null
                        relationships:
                          shipment:
                            data:
                              id: 06264731-503e-498e-bc76-f90b87b31562
                              type: shipment
                          container:
                            data:
                              id: eeafd337-72b5-4e5c-87cb-9ef83fa99cf4
                              type: container
                          vessel:
                            data: null
                          location:
                            data: null
                          terminal:
                            data: null
                    links:
                      self: >-
                        https://api.terminal49.com/v2/containers/eeafd337-72b5-4e5c-87cb-9ef83fa99cf4/transport_events
                      current: >-
                        https://api.terminal49.com/v2/containers/eeafd337-72b5-4e5c-87cb-9ef83fa99cf4/transport_events?page[number]=1
components:
  schemas:
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
    metro_area:
      title: Metro area model
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
                id: j9yuwej2ym7yq
              nullable: true
            country_code:
              type: string
              x-stoplight:
                id: hfupdk750wcrj
            time_zone:
              type: string
              description: IANA tz
              x-stoplight:
                id: izvtty345nfsz
            latitude:
              type: number
              x-stoplight:
                id: 9l62t4cwsp53w
              nullable: true
            longitude:
              type: number
              x-stoplight:
                id: 3tzibc0li8xvg
              nullable: true
        type:
          type: string
          enum:
            - metro_area
        '':
          type: string
          x-stoplight:
            id: kwcjunrtu3r5o
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
    rail_terminal:
      title: Rail Terminal model
      type: object
      properties:
        id:
          type: string
          format: uuid
        relationships:
          type: object
          properties:
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
            metro_area:
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
                        - metro_area
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
        type:
          type: string
          enum:
            - rail_terminal
      required:
        - attributes
    vessel:
      title: vessel
      type: object
      properties:
        id:
          type: string
          format: uuid
        type:
          type: string
          enum:
            - vessel
        attributes:
          type: object
          properties:
            name:
              type: string
              description: The name of the ship or vessel
              example: Ever Given
            imo:
              type: string
              description: International Maritime Organization (IMO) number
              nullable: true
              example: '9811000'
            mmsi:
              type: string
              description: Maritime Mobile Service Identity (MMSI)
              nullable: true
              example: '353136000'
            latitude:
              type: number
              description: The current latitude position of the vessel
              nullable: true
              example: 25.29845
            longitude:
              type: number
              description: The current longitude position of the vessel
              nullable: true
              example: 121.217
            nautical_speed_knots:
              type: number
              description: The current speed of the ship in knots (nautical miles per hour)
              nullable: true
              example: 90
            navigational_heading_degrees:
              type: number
              description: >-
                The current heading of the ship in degrees, where 0 is North, 90
                is East, 180 is South, and 270 is West
              nullable: true
              example: 194
            position_timestamp:
              type: string
              description: >-
                The timestamp of when the ship's position was last recorded, in
                ISO 8601 date and time format
              nullable: true
              example: '2023-07-28T14:01:37Z'
            positions:
              type: array
              description: >-
                An array of historical position data for the vessel. Only
                included if `show_positions` is true.
              nullable: true
              items:
                type: object
                properties:
                  latitude:
                    type: number
                    example: 1.477285
                  longitude:
                    type: number
                    example: 104.535533333
                  heading:
                    type: number
                    nullable: true
                    example: 51
                  timestamp:
                    type: string
                    format: date-time
                    example: '2025-05-23T19:14:22Z'
                  estimated:
                    type: boolean
                    example: false
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