;; Farmer Verification Contract
;; Validates legitimate agricultural producers

(define-data-var admin principal tx-sender)

;; Map to store verified farmers
(define-map verified-farmers principal
  {
    is-verified: bool,
    verification-date: uint,
    verification-expiry: uint
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u100)
(define-constant ERR_ALREADY_VERIFIED u101)
(define-constant ERR_NOT_VERIFIED u102)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Add a farmer to the verified list (admin only)
(define-public (verify-farmer (farmer principal) (expiry-blocks uint))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (asserts! (not (get is-verified (default-to {is-verified: false, verification-date: u0, verification-expiry: u0}
              (map-get? verified-farmers farmer))))
              (err ERR_ALREADY_VERIFIED))

    (map-set verified-farmers farmer
      {
        is-verified: true,
        verification-date: block-height,
        verification-expiry: (+ block-height expiry-blocks)
      }
    )
    (ok true)
  )
)

;; Revoke verification status (admin only)
(define-public (revoke-verification (farmer principal))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (asserts! (is-farmer-verified farmer) (err ERR_NOT_VERIFIED))

    (map-delete verified-farmers farmer)
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

;; Check if a farmer is verified (read-only)
(define-read-only (is-farmer-verified (farmer principal))
  (let ((farmer-data (default-to {is-verified: false, verification-date: u0, verification-expiry: u0}
                    (map-get? verified-farmers farmer))))
    (and
      (get is-verified farmer-data)
      (< block-height (get verification-expiry farmer-data))
    )
  )
)

;; Get farmer verification data (read-only)
(define-read-only (get-farmer-data (farmer principal))
  (map-get? verified-farmers farmer)
)
