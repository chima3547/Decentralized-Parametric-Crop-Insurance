;; Weather Data Oracle Contract
;; Tracks environmental conditions

(define-data-var admin principal tx-sender)
(define-data-var oracle-provider principal tx-sender)

;; Weather data structure by location and date
(define-map weather-data
  { location: (string-ascii 64), date: uint }
  {
    temperature: int,
    rainfall: uint,
    humidity: uint,
    wind-speed: uint,
    data-timestamp: uint
  }
)

;; Weather events structure (extreme conditions)
(define-map weather-events uint
  {
    location: (string-ascii 64),
    event-type: (string-ascii 32),
    severity: uint,
    start-date: uint,
    end-date: uint,
    confirmed: bool
  }
)

;; Event ID counter
(define-data-var event-id-counter uint u0)

;; Error codes
(define-constant ERR_UNAUTHORIZED u100)
(define-constant ERR_EVENT_NOT_FOUND u101)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Check if caller is oracle provider
(define-private (is-oracle-provider)
  (is-eq tx-sender (var-get oracle-provider))
)

;; Submit weather data (oracle provider only)
(define-public (submit-weather-data
                (location (string-ascii 64))
                (date uint)
                (temperature int)
                (rainfall uint)
                (humidity uint)
                (wind-speed uint))
  (begin
    (asserts! (is-oracle-provider) (err ERR_UNAUTHORIZED))

    (map-set weather-data
      { location: location, date: date }
      {
        temperature: temperature,
        rainfall: rainfall,
        humidity: humidity,
        wind-speed: wind-speed,
        data-timestamp: block-height
      }
    )

    (ok true)
  )
)

;; Report weather event (oracle provider only)
(define-public (report-weather-event
                (location (string-ascii 64))
                (event-type (string-ascii 32))
                (severity uint)
                (start-date uint)
                (end-date uint))
  (let ((new-id (+ (var-get event-id-counter) u1)))
    (asserts! (is-oracle-provider) (err ERR_UNAUTHORIZED))

    (map-set weather-events new-id
      {
        location: location,
        event-type: event-type,
        severity: severity,
        start-date: start-date,
        end-date: end-date,
        confirmed: false
      }
    )

    (var-set event-id-counter new-id)
    (ok new-id)
  )
)

;; Confirm a weather event (admin only)
(define-public (confirm-weather-event (event-id uint))
  (let ((event-data (unwrap! (map-get? weather-events event-id) (err ERR_EVENT_NOT_FOUND))))
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))

    (map-set weather-events event-id
      (merge event-data { confirmed: true })
    )

    (ok true)
  )
)

;; Set new oracle provider (admin only)
(define-public (set-oracle-provider (new-provider principal))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (var-set oracle-provider new-provider)
    (ok true)
  )
)

;; Transfer admin rights to a new principal (admin only)
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (var-set admin new-admin)
    (ok true)
  )
)

;; Get weather data for a location and date (read-only)
(define-read-only (get-weather-data (location (string-ascii 64)) (date uint))
  (map-get? weather-data { location: location, date: date })
)

;; Get weather event data (read-only)
(define-read-only (get-weather-event (event-id uint))
  (map-get? weather-events event-id)
)

;; Check if a weather event is confirmed (read-only)
(define-read-only (is-event-confirmed (event-id uint))
  (default-to false (get confirmed (map-get? weather-events event-id)))
)
