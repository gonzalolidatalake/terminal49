# Get container map GeoJSON

> Returns a GeoJSON FeatureCollection containing all map-related data for a container, including port locations, current vessel position (if at sea), past vessel paths, and estimated future routes. The response can be directly used with most mapping libraries (Leaflet, Mapbox GL, Google Maps, etc.). <Note>This is a paid feature. Please contact sales@terminal49.com.</Note>

This endpoint returns a GeoJSON FeatureCollection containing all map-related data for a container in a single response. The response includes port locations, current vessel position (if at sea), past vessel paths, and estimated future routes.

For detailed documentation on the response structure, feature types, and their properties, see the [Container Map GeoJSON Data guide](/api-docs/in-depth-guides/routing).


## OpenAPI

````yaml get /containers/{id}/map_geojson
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
  /containers/{id}/map_geojson:
    parameters:
      - schema:
          type: string
        name: id
        in: path
        required: true
    get:
      tags:
        - Containers
        - Routing (Paid)
      summary: Get container map GeoJSON
      description: >-
        Returns a GeoJSON FeatureCollection containing all map-related data for
        a container, including port locations, current vessel position (if at
        sea), past vessel paths, and estimated future routes. The response can
        be directly used with most mapping libraries (Leaflet, Mapbox GL, Google
        Maps, etc.). <Note>This is a paid feature. Please contact
        sales@terminal49.com.</Note>
      operationId: get-containers-id-map-geojson
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                type: object
                properties:
                  type:
                    type: string
                    enum:
                      - FeatureCollection
                  features:
                    type: array
                    items:
                      type: object
                      properties:
                        type:
                          type: string
                          enum:
                            - Feature
                        geometry:
                          oneOf:
                            - title: Point
                              type: object
                              properties:
                                type:
                                  type: string
                                  enum:
                                    - Point
                                coordinates:
                                  type: array
                                  items:
                                    type: number
                                  minItems: 2
                                  maxItems: 2
                                  example:
                                    - 100.896831042
                                    - 13.065302386
                              required:
                                - type
                                - coordinates
                            - title: LineString
                              type: object
                              properties:
                                type:
                                  type: string
                                  enum:
                                    - LineString
                                coordinates:
                                  type: array
                                  items:
                                    type: array
                                    items:
                                      type: number
                                    minItems: 2
                                    maxItems: 2
                                  minItems: 2
                                  example:
                                    - - 100.868768333
                                      - 13.07306
                                    - - 100.839155
                                      - 13.079318333
                              required:
                                - type
                                - coordinates
                        properties:
                          discriminator:
                            propertyName: feature_type
                            mapping:
                              port: '#/components/schemas/portFeatureProperties'
                              current_vessel: >-
                                #/components/schemas/currentVesselFeatureProperties
                              past_vessel_locations: >-
                                #/components/schemas/pastVesselLocationsFeatureProperties
                              estimated_full_legs: >-
                                #/components/schemas/estimatedFullLegFeatureProperties
                              estimated_partial_leg: >-
                                #/components/schemas/estimatedPartialLegFeatureProperties
                          oneOf:
                            - $ref: '#/components/schemas/portFeatureProperties'
                            - $ref: >-
                                #/components/schemas/currentVesselFeatureProperties
                            - $ref: >-
                                #/components/schemas/pastVesselLocationsFeatureProperties
                            - $ref: >-
                                #/components/schemas/estimatedFullLegFeatureProperties
                            - $ref: >-
                                #/components/schemas/estimatedPartialLegFeatureProperties
                      required:
                        - type
                        - geometry
                        - properties
                required:
                  - type
                  - features
              examples:
                Example Response:
                  value:
                    type: FeatureCollection
                    features:
                      - type: Feature
                        geometry:
                          type: Point
                          coordinates:
                            - 100.896831042
                            - 13.065302386
                        properties:
                          feature_type: port
                          ports_sequence: 1
                          ports_total: 3
                          location_id: c5adae24-6fd4-4720-8813-976cf206feb1
                          location_type: Port
                          name: Laem Chabang
                          state_abbr: '20'
                          state: null
                          country_code: TH
                          country: Thailand
                          time_zone: Asia/Bangkok
                          inbound_eta_at: null
                          inbound_ata_at: null
                          outbound_etd_at: null
                          outbound_atd_at: '2025-11-08T00:44:52Z'
                          label: POL
                          updated_at: '2025-12-11T09:01:08Z'
                      - type: Feature
                        geometry:
                          type: LineString
                          coordinates:
                            - - 100.868768333
                              - 13.07306
                            - - 100.839155
                              - 13.079318333
                            - - 118.038213333
                              - 24.43842
                            - - 118.03862
                              - 24.440998333
                        properties:
                          feature_type: past_vessel_locations
                          ports_sequence: 1
                          vessel_id: 87a12f43-766c-4078-89bc-ac6595082f7b
                          start_time: '2025-11-08T00:44:52Z'
                          end_time: '2025-11-15T16:00:00Z'
                          point_count: 546
                          outbound_atd_at: '2025-11-08T00:44:52Z'
                          inbound_ata_at: '2025-11-15T16:00:00Z'
                          inbound_eta_at: null
                      - type: Feature
                        geometry:
                          type: Point
                          coordinates:
                            - 118.0293
                            - 24.50318
                        properties:
                          feature_type: port
                          ports_sequence: 2
                          ports_total: 3
                          location_id: ed64d446-9098-420c-ab08-c127e62509fe
                          location_type: Port
                          name: Xiamen
                          state_abbr: FJ
                          state: null
                          country_code: CN
                          country: China
                          time_zone: Asia/Shanghai
                          inbound_eta_at: null
                          inbound_ata_at: '2025-11-15T16:00:00Z'
                          outbound_etd_at: null
                          outbound_atd_at: '2025-11-19T16:00:00Z'
                          label: TS1
                          updated_at: '2025-12-11T09:01:08Z'
                      - type: Feature
                        geometry:
                          type: Point
                          coordinates:
                            - -131.128473333
                            - 31.023033333
                        properties:
                          feature_type: current_vessel
                          ports_sequence: 2
                          vessel_id: 93fc5dce-4c7f-4089-bd28-f20cd9202ab0
                          vessel_name: ZIM BANGKOK
                          vessel_imo: '9936525'
                          voyage_number: 13E
                          vessel_location_timestamp: '2025-12-11T11:46:03Z'
                          vessel_location_heading: 108
                          vessel_location_speed: 21
                          departure_port_id: ed64d446-9098-420c-ab08-c127e62509fe
                          departure_port_name: Xiamen
                          departure_port_state_abbr: FJ
                          departure_port_state: null
                          departure_port_country_code: CN
                          departure_port_country: China
                          departure_port_label: TS1
                          departure_port_atd: '2025-11-19T16:00:00Z'
                          departure_port_time_zone: Asia/Shanghai
                          arrival_port_id: 6129528d-846e-4571-ae16-b5328a4285ab
                          arrival_port_name: Savannah
                          arrival_port_state_abbr: GA
                          arrival_port_state: Georgia
                          arrival_port_country_code: US
                          arrival_port_country: United States
                          arrival_port_label: POD
                          arrival_port_eta: '2025-12-31T05:00:00Z'
                          arrival_port_time_zone: America/New_York
                      - type: Feature
                        geometry:
                          type: LineString
                          coordinates:
                            - - 118.045325
                              - 23.518831667
                            - - 118.076886667
                              - 23.556158333
                            - - -131.583741667
                              - 31.153668333
                            - - -131.128473333
                              - 31.023033333
                        properties:
                          feature_type: past_vessel_locations
                          ports_sequence: 2
                          vessel_id: 93fc5dce-4c7f-4089-bd28-f20cd9202ab0
                          start_time: '2025-11-19T16:00:00Z'
                          end_time: '2026-01-07T05:00:00Z'
                          point_count: 1402
                          outbound_atd_at: '2025-11-19T16:00:00Z'
                          inbound_ata_at: null
                          inbound_eta_at: '2025-12-31T05:00:00Z'
                      - type: Feature
                        geometry:
                          type: LineString
                          coordinates:
                            - - -131.128473333
                              - 31.023033333
                            - - -130.9177
                              - 30.67224
                            - - -80.70766
                              - 31.96363
                            - - -80.91232
                              - 32.03728
                        properties:
                          feature_type: estimated_partial_leg
                          ports_sequence: 2
                          current_port_id: ed64d446-9098-420c-ab08-c127e62509fe
                          next_port_id: 6129528d-846e-4571-ae16-b5328a4285ab
                          point_count: 364
                      - type: Feature
                        geometry:
                          type: Point
                          coordinates:
                            - -81.140998396
                            - 32.128923976
                        properties:
                          feature_type: port
                          ports_sequence: 3
                          ports_total: 3
                          location_id: 6129528d-846e-4571-ae16-b5328a4285ab
                          location_type: Port
                          name: Savannah
                          state_abbr: GA
                          state: Georgia
                          country_code: US
                          country: United States
                          time_zone: America/New_York
                          inbound_eta_at: '2025-12-31T05:00:00Z'
                          inbound_ata_at: null
                          outbound_etd_at: null
                          outbound_atd_at: null
                          label: POD
                          updated_at: '2025-12-11T09:01:08Z'
        '403':
          description: Forbidden - Routing data feature is not enabled for this account
          content:
            application/json:
              schema:
                type: object
                properties:
                  errors:
                    type: array
                    items:
                      type: object
                      properties:
                        status:
                          type: string
                          example: '403'
                        title:
                          type: string
                          example: Forbidden
                        detail:
                          type: string
                          example: Routing data feature is not enabled for this account
components:
  schemas:
    portFeatureProperties:
      title: Port
      type: object
      properties:
        feature_type:
          type: string
          enum:
            - port
        ports_sequence:
          type: integer
          description: The sequence number of this port in the route (1 = POL, last = POD)
        ports_total:
          type: integer
          description: Total number of ports in the route
        location_id:
          type: string
          description: Unique identifier for the port location
        location_type:
          type: string
          enum:
            - Port
        name:
          type: string
          description: Name of the port
        state_abbr:
          type: string
          nullable: true
          description: State abbreviation (if applicable)
        state:
          type: string
          nullable: true
          description: State name (if applicable)
        country_code:
          type: string
          description: ISO country code
        country:
          type: string
          description: Country name
        time_zone:
          type: string
          description: IANA timezone identifier
        label:
          type: string
          description: 'Port label: POL, POD, or TS1, TS2, etc.'
        inbound_eta_at:
          type: string
          format: date-time
          nullable: true
          description: Estimated time of arrival (ISO 8601)
        inbound_ata_at:
          type: string
          format: date-time
          nullable: true
          description: Actual time of arrival (ISO 8601)
        outbound_etd_at:
          type: string
          format: date-time
          nullable: true
          description: Estimated time of departure (ISO 8601)
        outbound_atd_at:
          type: string
          format: date-time
          nullable: true
          description: Actual time of departure (ISO 8601)
        updated_at:
          type: string
          format: date-time
          nullable: true
          description: Last update timestamp from the shipment (ISO 8601)
      required:
        - feature_type
    currentVesselFeatureProperties:
      title: Current Vessel
      type: object
      properties:
        feature_type:
          type: string
          enum:
            - current_vessel
        ports_sequence:
          type: integer
          description: Sequence number of the departure port for this leg
        vessel_id:
          type: string
          description: Unique identifier for the vessel
        vessel_name:
          type: string
          description: Name of the vessel
        vessel_imo:
          type: string
          description: IMO number of the vessel
        voyage_number:
          type: string
          nullable: true
          description: Voyage number for this leg
        vessel_location_timestamp:
          type: string
          format: date-time
          description: Timestamp of the vessel position (ISO 8601)
        vessel_location_heading:
          type: number
          nullable: true
          description: Vessel heading in degrees (0-360)
        vessel_location_speed:
          type: number
          nullable: true
          description: Vessel speed in knots
        departure_port_id:
          type: string
          description: ID of the port the vessel departed from
        departure_port_name:
          type: string
          description: Name of the departure port
        departure_port_state_abbr:
          type: string
          nullable: true
          description: State abbreviation of departure port
        departure_port_state:
          type: string
          nullable: true
          description: State name of departure port
        departure_port_country_code:
          type: string
          description: Country code of departure port
        departure_port_country:
          type: string
          description: Country name of departure port
        departure_port_label:
          type: string
          description: Label of departure port (POL, POD, TS1, etc.)
        departure_port_atd:
          type: string
          format: date-time
          nullable: true
          description: Actual time of departure from the port (ISO 8601)
        departure_port_time_zone:
          type: string
          description: Timezone of departure port
        arrival_port_id:
          type: string
          nullable: true
          description: ID of the next port the vessel is heading to
        arrival_port_name:
          type: string
          nullable: true
          description: Name of the arrival port
        arrival_port_state_abbr:
          type: string
          nullable: true
          description: State abbreviation of arrival port
        arrival_port_state:
          type: string
          nullable: true
          description: State name of arrival port
        arrival_port_country_code:
          type: string
          nullable: true
          description: Country code of arrival port
        arrival_port_country:
          type: string
          nullable: true
          description: Country name of arrival port
        arrival_port_label:
          type: string
          nullable: true
          description: Label of arrival port (POL, POD, TS1, etc.)
        arrival_port_eta:
          type: string
          format: date-time
          nullable: true
          description: Estimated time of arrival at the next port (ISO 8601)
        arrival_port_time_zone:
          type: string
          nullable: true
          description: Timezone of arrival port
      required:
        - feature_type
    pastVesselLocationsFeatureProperties:
      title: Past Vessel Locations
      type: object
      properties:
        feature_type:
          type: string
          enum:
            - past_vessel_locations
        ports_sequence:
          type: integer
          description: Sequence number of the departure port for this leg
        vessel_id:
          type: string
          description: Unique identifier for the vessel that traveled this path
        start_time:
          type: string
          format: date-time
          description: Start timestamp of the path (ISO 8601)
        end_time:
          type: string
          format: date-time
          description: End timestamp of the path (ISO 8601)
        point_count:
          type: integer
          description: Number of coordinate points in the LineString
        outbound_atd_at:
          type: string
          format: date-time
          nullable: true
          description: Actual time of departure from the origin port (ISO 8601)
        inbound_ata_at:
          type: string
          format: date-time
          nullable: true
          description: Actual time of arrival at the destination port (ISO 8601)
        inbound_eta_at:
          type: string
          format: date-time
          nullable: true
          description: Estimated time of arrival at the destination port (ISO 8601)
      required:
        - feature_type
    estimatedFullLegFeatureProperties:
      title: Estimated Full Leg
      type: object
      properties:
        feature_type:
          type: string
          enum:
            - estimated_full_legs
        ports_sequence:
          type: integer
          description: Sequence number of the departure port for this leg
        previous_port_id:
          type: string
          description: ID of the origin port
        next_port_id:
          type: string
          description: ID of the destination port
        point_count:
          type: integer
          description: Number of coordinate points in the LineString
      required:
        - feature_type
    estimatedPartialLegFeatureProperties:
      title: Estimated Partial Leg
      type: object
      properties:
        feature_type:
          type: string
          enum:
            - estimated_partial_leg
        ports_sequence:
          type: integer
          description: Sequence number of the departure port for this leg
        current_port_id:
          type: string
          description: ID of the port the vessel departed from
        next_port_id:
          type: string
          description: ID of the next port the vessel is heading to
        point_count:
          type: integer
          description: Number of coordinate points in the LineString
      required:
        - feature_type
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