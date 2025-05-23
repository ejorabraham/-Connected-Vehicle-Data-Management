;; Data Collection Contract
;; Gathers and stores vehicle information

(define-data-var contract-owner principal tx-sender)

;; Data structure for vehicle telemetry data
(define-map vehicle-data
  {
    vehicle-id: (string-utf8 36),
    timestamp: uint
  }
  {
    location: {
      latitude: int,
      longitude: int
    },
    speed: uint,
    fuel-level: uint,
    battery-level: uint,
    engine-status: (string-utf8 20),
    diagnostic-codes: (list 10 (string-utf8 10)),
    data-provider: principal
  }
)

;; Track data entries per vehicle
(define-map vehicle-data-entries
  { vehicle-id: (string-utf8 36) }
  { entry-count: uint }
)

;; Initialize contract owner
(define-public (initialize-contract)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (ok true)
  )
)

;; Submit vehicle data
(define-public (submit-data
    (vehicle-id (string-utf8 36))
    (latitude int)
    (longitude int)
    (speed uint)
    (fuel-level uint)
    (battery-level uint)
    (engine-status (string-utf8 20))
    (diagnostic-codes (list 10 (string-utf8 10))))
  (let (
    (timestamp block-height)
    (current-entries (default-to { entry-count: u0 } (map-get? vehicle-data-entries { vehicle-id: vehicle-id })))
  )
    (begin
      ;; Store the vehicle data
      (map-set vehicle-data
        {
          vehicle-id: vehicle-id,
          timestamp: timestamp
        }
        {
          location: {
            latitude: latitude,
            longitude: longitude
          },
          speed: speed,
          fuel-level: fuel-level,
          battery-level: battery-level,
          engine-status: engine-status,
          diagnostic-codes: diagnostic-codes,
          data-provider: tx-sender
        }
      )

      ;; Update entry count
      (map-set vehicle-data-entries
        { vehicle-id: vehicle-id }
        { entry-count: (+ (get entry-count current-entries) u1) }
      )

      (ok timestamp)
    )
  )
)

;; Get vehicle data by ID and timestamp
(define-read-only (get-data (vehicle-id (string-utf8 36)) (timestamp uint))
  (map-get? vehicle-data { vehicle-id: vehicle-id, timestamp: timestamp })
)

;; Get the number of data entries for a vehicle
(define-read-only (get-entry-count (vehicle-id (string-utf8 36)))
  (default-to u0 (get entry-count (map-get? vehicle-data-entries { vehicle-id: vehicle-id })))
)

;; Check if a principal is the data provider for a specific entry
(define-read-only (is-data-provider (vehicle-id (string-utf8 36)) (timestamp uint) (provider principal))
  (let ((data (map-get? vehicle-data { vehicle-id: vehicle-id, timestamp: timestamp })))
    (if (is-some data)
      (is-eq (get data-provider (unwrap-panic data)) provider)
      false
    )
  )
)
