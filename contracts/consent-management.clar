;; Consent Management Contract
;; Controls data sharing permissions

(define-data-var contract-owner principal tx-sender)

;; Data structure for consent records
(define-map consent-records
  {
    vehicle-id: (string-utf8 36),
    data-requester: principal
  }
  {
    is-granted: bool,
    granted-at: uint,
    expires-at: uint,
    data-types: (list 10 (string-utf8 20)),
    purpose: (string-utf8 100),
    owner: principal
  }
)

;; Track consent history
(define-map consent-history
  {
    vehicle-id: (string-utf8 36),
    data-requester: principal,
    timestamp: uint
  }
  {
    action: (string-utf8 10), ;; "grant" or "revoke"
    data-types: (list 10 (string-utf8 20)),
    purpose: (string-utf8 100),
    owner: principal
  }
)

;; Initialize contract owner
(define-public (initialize-contract)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (ok true)
  )
)

;; Grant consent for data access
(define-public (grant-consent
    (vehicle-id (string-utf8 36))
    (data-requester principal)
    (duration uint)
    (data-types (list 10 (string-utf8 20)))
    (purpose (string-utf8 100)))
  (let (
    (current-block block-height)
    (expiry (+ block-height duration))
  )
    (begin
      ;; Set consent record
      (map-set consent-records
        {
          vehicle-id: vehicle-id,
          data-requester: data-requester
        }
        {
          is-granted: true,
          granted-at: current-block,
          expires-at: expiry,
          data-types: data-types,
          purpose: purpose,
          owner: tx-sender
        }
      )

      ;; Record in history
      (map-set consent-history
        {
          vehicle-id: vehicle-id,
          data-requester: data-requester,
          timestamp: current-block
        }
        {
          action: "grant",
          data-types: data-types,
          purpose: purpose,
          owner: tx-sender
        }
      )

      (ok true)
    )
  )
)

;; Revoke consent for data access
(define-public (revoke-consent (vehicle-id (string-utf8 36)) (data-requester principal))
  (let (
    (consent-data (map-get? consent-records { vehicle-id: vehicle-id, data-requester: data-requester }))
    (current-block block-height)
  )
    (begin
      (asserts! (is-some consent-data) (err u2))
      (asserts! (is-eq (get owner (unwrap-panic consent-data)) tx-sender) (err u3))

      ;; Update consent record
      (map-set consent-records
        {
          vehicle-id: vehicle-id,
          data-requester: data-requester
        }
        (merge (unwrap-panic consent-data)
          { is-granted: false }
        )
      )

      ;; Record in history
      (map-set consent-history
        {
          vehicle-id: vehicle-id,
          data-requester: data-requester,
          timestamp: current-block
        }
        {
          action: "revoke",
          data-types: (get data-types (unwrap-panic consent-data)),
          purpose: (get purpose (unwrap-panic consent-data)),
          owner: tx-sender
        }
      )

      (ok true)
    )
  )
)

;; Check if consent is granted
(define-read-only (check-consent (vehicle-id (string-utf8 36)) (data-requester principal))
  (let ((consent-data (map-get? consent-records { vehicle-id: vehicle-id, data-requester: data-requester })))
    (if (is-some consent-data)
      (let ((consent (unwrap-panic consent-data)))
        (and
          (get is-granted consent)
          (< block-height (get expires-at consent))
        )
      )
      false
    )
  )
)

;; Get consent details
(define-read-only (get-consent-details (vehicle-id (string-utf8 36)) (data-requester principal))
  (map-get? consent-records { vehicle-id: vehicle-id, data-requester: data-requester })
)

;; Check if a data type is included in consent
(define-read-only (is-data-type-consented
    (vehicle-id (string-utf8 36))
    (data-requester principal)
    (data-type (string-utf8 20)))
  (let ((consent-data (map-get? consent-records { vehicle-id: vehicle-id, data-requester: data-requester })))
    (if (is-some consent-data)
      (let ((consent (unwrap-panic consent-data)))
        (and
          (get is-granted consent)
          (< block-height (get expires-at consent))
          (is-some (index-of (get data-types consent) data-type))
        )
      )
      false
    )
  )
)
