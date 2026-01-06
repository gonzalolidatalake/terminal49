# Get a vessel using the imo

> Returns a vessel by the given IMO number. <Note>`show_positions` is a paid feature. Please contact sales@terminal49.com.</Note>



## OpenAPI

````yaml get /vessels/{imo}
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
  /vessels/{imo}:
    parameters:
      - schema:
          type: string
        name: imo
        in: path
        required: true
      - schema:
          type: string
          format: date-time
          example: '2025-05-20T00:00:00Z'
        name: show_positions[from_timestamp]
        in: query
        description: ISO 8601 timestamp to filter positions from. 7 days by default.
        required: false
      - schema:
          type: string
          format: date-time
          example: '2025-05-24T00:00:00Z'
        name: show_positions[to_timestamp]
        in: query
        description: ISO 8601 timestamp to filter positions up to. Current time by default.
        required: false
    get:
      tags:
        - Vessels
      summary: Get a vessel using the imo
      description: >-
        Returns a vessel by the given IMO number. <Note>`show_positions` is a
        paid feature. Please contact sales@terminal49.com.</Note>
      operationId: get-vessels-imo
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    $ref: '#/components/schemas/vessel'
        '403':
          description: Forbidden - Feature not enabled
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
                        source:
                          type: object
                          nullable: true
                        title:
                          type: string
                          example: Forbidden
                        detail:
                          type: string
                          example: Routing data feature is not enabled for this account
components:
  schemas:
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