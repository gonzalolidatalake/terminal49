# Get a container's raw events

> #### Deprecation warning
The `raw_events` endpoint is provided as-is.

 For past events we recommend consuming `transport_events`.

---
Get a list of past and future (estimated) milestones for a container as reported by the carrier. Some of the data is normalized even though the API is called raw_events. 

Normalized attributes: `event` and `timestamp` timestamp. Not all of the `event` values have been normalized. You can expect the the events related to container movements to be normalized but there are cases where events are not normalized. 

For past historical events we recommend consuming `transport_events`. Although there are fewer events here those events go through additional vetting and normalization to avoid false positives and get you correct data.



## OpenAPI

````yaml get /containers/{id}/raw_events
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
  /containers/{id}/raw_events:
    parameters:
      - schema:
          type: string
        name: id
        in: path
        required: true
    get:
      tags:
        - Containers
      summary: Get a container's raw events
      description: >-
        #### Deprecation warning

        The `raw_events` endpoint is provided as-is.

         For past events we recommend consuming `transport_events`.

        ---

        Get a list of past and future (estimated) milestones for a container as
        reported by the carrier. Some of the data is normalized even though the
        API is called raw_events. 


        Normalized attributes: `event` and `timestamp` timestamp. Not all of the
        `event` values have been normalized. You can expect the the events
        related to container movements to be normalized but there are cases
        where events are not normalized. 


        For past historical events we recommend consuming `transport_events`.
        Although there are fewer events here those events go through additional
        vetting and normalization to avoid false positives and get you correct
        data.
      operationId: get-containers-id-raw_events
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
                      $ref: '#/components/schemas/raw_event'
              examples:
                Example Raw Events:
                  value:
                    data:
                      - id: ca6b760f-13e9-4bf6-ab49-3cf2e40757fb
                        type: raw_event
                        attributes:
                          timestamp: '2020-03-03T00:00:00Z'
                          estimated: false
                          actual_on: '2020-03-03'
                          estimated_at: null
                          actual_at: null
                          event: empty_out
                          index: 0
                          original_event: Truck Gate out empty
                          created_at: '2020-04-18T00:18:27Z'
                          voyage_number: null
                          location_name: Oakland
                          location_locode: null
                          vessel_name: null
                          vessel_imo: null
                          timezone: null
                        relationships:
                          location:
                            data: null
                          vessel:
                            data: null
                      - id: bcdfc796-0570-4c85-9336-d6c7d0da02d2
                        type: raw_event
                        attributes:
                          timestamp: '2020-03-09T00:00:00Z'
                          estimated: false
                          actual_on: '2020-03-09'
                          estimated_at: null
                          actual_at: null
                          event: full_in
                          index: 1
                          original_event: Truck Arrival in
                          created_at: '2020-04-18T00:18:27Z'
                          voyage_number: null
                          location_name: null
                          location_locode: null
                          vessel_name: null
                          vessel_imo: null
                          timezone: null
                        relationships:
                          location:
                            data: null
                          vessel:
                            data: null
                      - id: a4ff01b0-b374-4123-ae65-3dc0c7ea41ea
                        type: raw_event
                        attributes:
                          timestamp: '2020-03-14T00:00:00Z'
                          estimated: false
                          actual_on: '2020-03-14'
                          estimated_at: null
                          actual_at: null
                          event: vessel_loaded
                          index: 2
                          original_event: Vessel Loaded
                          created_at: '2020-04-18T00:18:27Z'
                          voyage_number: FA009R
                          location_name: null
                          location_locode: null
                          vessel_name: MSC FAITH
                          vessel_imo: null
                          timezone: null
                        relationships:
                          location:
                            data: null
                          vessel:
                            data:
                              id: 4b473d0e-7073-4171-8b5b-15e71e9e13cc
                              type: vessel
                      - id: ca5862ef-6e27-4245-a281-0cec6bbe1fb7
                        type: raw_event
                        attributes:
                          timestamp: '2020-03-15T00:00:00Z'
                          estimated: false
                          actual_on: '2020-03-15'
                          estimated_at: null
                          actual_at: null
                          event: vessel_departed
                          index: 3
                          original_event: Vessel departed
                          created_at: '2020-04-18T00:18:27Z'
                          voyage_number: FA009R
                          location_name: null
                          location_locode: null
                          vessel_name: MSC FAITH
                          vessel_imo: null
                          timezone: null
                        relationships:
                          location:
                            data: null
                          vessel:
                            data:
                              id: 4b473d0e-7073-4171-8b5b-15e71e9e13cc
                              type: vessel
                      - id: f47a903e-e6d1-41c5-aec6-8401b2abf297
                        type: raw_event
                        attributes:
                          timestamp: '2020-03-25T00:00:00Z'
                          estimated: false
                          actual_on: '2020-03-25'
                          estimated_at: null
                          actual_at: null
                          event: transshipment_arrived
                          index: 4
                          original_event: Vessel arrived
                          created_at: '2020-04-18T00:18:27Z'
                          voyage_number: FA009R
                          location_name: null
                          location_locode: null
                          vessel_name: MSC FAITH
                          vessel_imo: null
                          timezone: null
                        relationships:
                          location:
                            data: null
                          vessel:
                            data:
                              id: 4b473d0e-7073-4171-8b5b-15e71e9e13cc
                              type: vessel
                      - id: 72a1a13b-a2e0-4ac0-851d-eec41e9e9087
                        type: raw_event
                        attributes:
                          timestamp: '2020-03-25T00:00:00Z'
                          estimated: false
                          actual_on: '2020-03-25'
                          estimated_at: null
                          actual_at: null
                          event: transshipment_discharged
                          index: 5
                          original_event: Vessel Discharged
                          created_at: '2020-04-18T00:18:27Z'
                          voyage_number: FA009R
                          location_name: null
                          location_locode: null
                          vessel_name: MSC FAITH
                          vessel_imo: null
                          timezone: null
                        relationships:
                          location:
                            data: null
                          vessel:
                            data:
                              id: 4b473d0e-7073-4171-8b5b-15e71e9e13cc
                              type: vessel
                      - id: cd91f0cf-ee73-4c47-b99f-63245cb5bc96
                        type: raw_event
                        attributes:
                          timestamp: '2020-04-07T00:00:00Z'
                          estimated: false
                          actual_on: '2020-04-07'
                          estimated_at: null
                          actual_at: null
                          event: transshipment_loaded
                          index: 6
                          original_event: Vessel Loaded
                          created_at: '2020-04-18T00:18:27Z'
                          voyage_number: 15W10
                          location_name: null
                          location_locode: null
                          vessel_name: SINGAPORE EXPRESS
                          vessel_imo: null
                          timezone: null
                        relationships:
                          location:
                            data: null
                          vessel:
                            data:
                              id: 345c05ab-4217-4ffe-a1a4-6c03b9ad2b36
                              type: vessel
                      - id: 561dbb7e-c3ab-4e63-b09b-957878b1425f
                        type: raw_event
                        attributes:
                          timestamp: '2020-04-07T00:00:00Z'
                          estimated: false
                          actual_on: '2020-04-07'
                          estimated_at: null
                          actual_at: null
                          event: transshipment_departed
                          index: 7
                          original_event: Vessel departed
                          created_at: '2020-04-18T00:18:27Z'
                          voyage_number: 15W10
                          location_name: null
                          location_locode: null
                          vessel_name: SINGAPORE EXPRESS
                          vessel_imo: null
                          timezone: null
                        relationships:
                          location:
                            data: null
                          vessel:
                            data:
                              id: 345c05ab-4217-4ffe-a1a4-6c03b9ad2b36
                              type: vessel
                      - id: 551711a6-62ad-4205-8da2-00e0c0cbd2db
                        type: raw_event
                        attributes:
                          timestamp: '2020-04-12T00:00:00Z'
                          estimated: false
                          actual_on: '2020-04-12'
                          estimated_at: null
                          actual_at: null
                          event: vessel_arrived
                          index: 8
                          original_event: Vessel arrived
                          created_at: '2020-04-18T00:18:27Z'
                          voyage_number: 15W10
                          location_name: null
                          location_locode: null
                          vessel_name: SINGAPORE EXPRESS
                          vessel_imo: null
                          timezone: null
                        relationships:
                          location:
                            data: null
                          vessel:
                            data:
                              id: 345c05ab-4217-4ffe-a1a4-6c03b9ad2b36
                              type: vessel
                      - id: f4027470-75ca-4e2a-b4f0-47654a25ac48
                        type: raw_event
                        attributes:
                          timestamp: '2020-04-13T00:00:00Z'
                          estimated: false
                          actual_on: '2020-04-13'
                          estimated_at: null
                          actual_at: null
                          event: vessel_discharged
                          index: 9
                          original_event: Vessel Discharged
                          created_at: '2020-04-18T00:18:27Z'
                          voyage_number: 15W10
                          location_name: null
                          location_locode: null
                          vessel_name: SINGAPORE EXPRESS
                          vessel_imo: null
                          timezone: null
                        relationships:
                          location:
                            data: null
                          vessel:
                            data:
                              id: 345c05ab-4217-4ffe-a1a4-6c03b9ad2b36
                              type: vessel
                      - id: 50f11e4f-411e-48e2-8141-64226500df9c
                        type: raw_event
                        attributes:
                          timestamp: '2020-04-14T00:00:00Z'
                          estimated: false
                          actual_on: '2020-04-14'
                          estimated_at: null
                          actual_at: null
                          event: full_out
                          index: 10
                          original_event: Truck Departure from
                          created_at: '2020-04-18T00:18:27Z'
                          voyage_number: null
                          location_name: null
                          location_locode: null
                          vessel_name: null
                          vessel_imo: null
                          timezone: null
                        relationships:
                          location:
                            data: null
                          vessel:
                            data: null
                      - id: 49aea23c-b8c5-4a97-b133-f7a9723fa1b4
                        type: raw_event
                        attributes:
                          timestamp: '2020-04-15T00:00:00Z'
                          estimated: false
                          actual_on: '2020-04-15'
                          estimated_at: null
                          actual_at: null
                          event: empty_in
                          index: 11
                          original_event: Truck Gate in empty
                          created_at: '2020-04-18T00:18:27Z'
                          voyage_number: null
                          location_name: null
                          location_locode: null
                          vessel_name: null
                          vessel_imo: null
                          timezone: null
                        relationships:
                          location:
                            data: null
                          vessel:
                            data: null
                    included:
                      - id: 4b473d0e-7073-4171-8b5b-15e71e9e13cc
                        type: vessel
                        attributes:
                          name: MSC FAITH
                          imo: null
                          mmsi: '636019213'
                          latitude: 70.22625823437389
                          longitude: 45.06279126658865
                          nautical_speed_knots: 100
                          navigational_heading_degrees: 1
                          position_timestamp: '2023-06-05T19:46:18Z'
                      - id: 345c05ab-4217-4ffe-a1a4-6c03b9ad2b36
                        type: vessel
                        attributes:
                          name: SINGAPORE EXPRESS
                          imo: null
                          mmsi: '477300500'
                          latitude: 70.22625823437389
                          longitude: 45.06279126658865
                          nautical_speed_knots: 100
                          navigational_heading_degrees: 1
                          position_timestamp: '2023-06-05T19:46:18Z'
      deprecated: true
components:
  schemas:
    raw_event:
      title: Raw Event Model
      type: object
      description: >-
        Raw Events represent the milestones from the shipping line for a given
        container.


        ### About raw_event datetimes


        The events may include estimated future events. The event is a future
        event if an `estimated_` timestamp is not null. 


        The datetime properties `timestamp` and `estimated`. 


        When the `time_zone` property is present the datetimes are UTC
        timestamps, which can be converted to the local time by parsing the
        provided `time_zone`.


        When the `time_zone` property is absent, the datetimes represent local
        times which serialized as UTC timestamps for consistency. 
      properties:
        id:
          type: string
        type:
          type: string
          description: ''
          enum:
            - raw_event
        attributes:
          type: object
          properties:
            event:
              type: string
              enum:
                - empty_out
                - full_in
                - positioned_in
                - positioned_out
                - vessel_loaded
                - vessel_departed
                - transshipment_arrived
                - transshipment_discharged
                - transshipment_loaded
                - transshipment_departed
                - feeder_arrived
                - feeder_discharged
                - feeder_loaded
                - feeder_departed
                - rail_loaded
                - rail_departed
                - rail_arrived
                - rail_unloaded
                - vessel_arrived
                - vessel_discharged
                - arrived_at_destination
                - delivered
                - full_out
                - empty_in
                - vgm_received
                - carrier_release
                - customs_release
                - available
              description: Normalized string representing the event
              nullable: true
            original_event:
              type: string
              description: The event name as returned by the carrier
            timestamp:
              type: string
              format: date-time
              description: The datetime the event either transpired or will occur in UTC
            estimated:
              type: boolean
              description: True if the timestamp is estimated, false otherwise
            actual_on:
              type: string
              format: date
              description: >-
                Deprecated: The date of the event at the event location when no
                time information is available. 
              nullable: true
            estimated_on:
              type: string
              format: date
              description: >-
                Deprecated: The estimated date of the event at the event
                location when no time information is available. 
              nullable: true
            actual_at:
              type: string
              format: date-time
              description: 'Deprecated: The datetime the event transpired in UTC'
              nullable: true
            estimated_at:
              type: string
              format: date-time
              description: 'Deprecated: The estimated datetime the event will occur in UTC'
              nullable: true
            timezone:
              type: string
              description: IANA tz where the event occured
              nullable: true
            created_at:
              type: string
              format: date-time
              description: When the raw_event was created in UTC
            location_name:
              type: string
              description: The city or facility name of the event location
            location_locode:
              type: string
              description: UNLOCODE of the event location
              nullable: true
            vessel_name:
              type: string
              description: The name of the vessel where applicable
              nullable: true
            vessel_imo:
              type: string
              description: The IMO of the vessel where applicable
              nullable: true
            index:
              type: integer
              description: >-
                The order of the event. This may be helpful when only dates
                (i.e. actual_on) are available.
            voyage_number:
              type: string
              nullable: true
        relationships:
          type: object
          properties:
            location:
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
                        - metro_area
            vessel:
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
                        - vessel
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