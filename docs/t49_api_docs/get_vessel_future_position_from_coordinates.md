# Get vessel future positions from coordinates

> Returns the estimated route between two ports for a given vessel from a set of coordinates. <Warning> The timestamp of the positions has fixed spacing of one minute.</Warning> <Note>This is a paid feature. Please contact sales@terminal49.com.</Note>



## OpenAPI

````yaml get /vessels/{id}/future_positions_with_coordinates
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
  /vessels/{id}/future_positions_with_coordinates:
    parameters:
      - schema:
          type: string
        name: id
        in: path
        required: true
    get:
      tags:
        - Routing (Paid)
        - Vessels
      summary: Get vessel future positions from coordinates
      description: >-
        Returns the estimated route between two ports for a given vessel from a
        set of coordinates. <Warning> The timestamp of the positions has fixed
        spacing of one minute.</Warning> <Note>This is a paid feature. Please
        contact sales@terminal49.com.</Note>
      operationId: get-vessels-id-future-positions-with-coordinates
      parameters:
        - schema:
            type: string
            format: uuid
          in: query
          name: port_id
          description: The destination port id
          required: true
        - schema:
            type: string
            format: uuid
          in: query
          name: previous_port_id
          description: The previous port id
          required: true
        - schema:
            type: number
          in: query
          name: latitude
          description: Starting latitude coordinate
          required: true
        - schema:
            type: number
          in: query
          name: longitude
          description: Starting longitude coordinate
          required: true
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    $ref: '#/components/schemas/vessel_with_positions'
                  links:
                    type: object
                    properties:
                      self:
                        type: string
                        format: uri
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
    vessel_with_positions:
      title: Vessel with positions model
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
            imo:
              type: string
              description: International Maritime Organization (IMO) number
              nullable: true
            mmsi:
              type: string
              description: Maritime Mobile Service Identity (MMSI)
              nullable: true
            latitude:
              type: number
              description: The current latitude position of the vessel
              nullable: true
            longitude:
              type: number
              description: The current longitude position of the vessel
              nullable: true
            nautical_speed_knots:
              type: number
              description: The current speed of the ship in knots (nautical miles per hour)
              nullable: true
            navigational_heading_degrees:
              type: number
              description: >-
                The current heading of the ship in degrees, where 0 is North, 90
                is East, 180 is South, and 270 is West
              nullable: true
            position_timestamp:
              type: string
              format: date-time
              description: >-
                The timestamp of when the ship's position was last recorded, in
                ISO 8601 date and time format
              nullable: true
            positions:
              type: array
              description: Array of estimated future positions
              items:
                type: object
                properties:
                  latitude:
                    type: number
                  longitude:
                    type: number
                  heading:
                    type: number
                    nullable: true
                  timestamp:
                    type: string
                    format: date-time
                  estimated:
                    type: boolean
                required:
                  - latitude
                  - longitude
                  - timestamp
                  - estimated
      required:
        - id
        - type
        - attributes
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