;; Vehicle Fleet Management Smart Contract
;; Track vehicles with operator assignments and maintenance access

;; Constants
(define-constant fleet-manager tx-sender)
(define-constant err-manager-restricted (err u100))
(define-constant err-vehicle-missing (err u101))
(define-constant err-vehicle-registered (err u102))
(define-constant err-invalid-model (err u103))
(define-constant err-invalid-mileage (err u104))
(define-constant err-no-clearance (err u105))

;; Data variables
(define-data-var vehicle-inventory uint u0)

;; Map to store vehicle information
(define-map fleet-roster
  { vehicle-id: uint }
  {
    operator: principal,
    model: (string-ascii 64),
    mileage: uint,
    added-at: uint,
    maintenance-access: { technician: principal, granted: bool }
  }
)

;; Private functions
(define-private (vehicle-tracked (vehicle-id uint))
  (is-some (map-get? fleet-roster { vehicle-id: vehicle-id }))
)

;; Public functions
(define-public (enroll-vehicle (model (string-ascii 64)) (mileage uint))
  (let
    (
      (vehicle-id (+ (var-get vehicle-inventory) u1))
    )
    (asserts! (> (len model) u0) err-invalid-model)
    (asserts! (< (len model) u65) err-invalid-model)
    (asserts! (> mileage u0) err-invalid-mileage)
    (asserts! (< mileage u1000000000) err-invalid-mileage)
    
    (map-insert fleet-roster
      { vehicle-id: vehicle-id }
      {
        operator: tx-sender,
        model: model,
        mileage: mileage,
        added-at: stacks-block-height,
        maintenance-access: { technician: tx-sender, granted: true }
      }
    )
    (var-set vehicle-inventory vehicle-id)
    (ok vehicle-id)
  )
)

(define-public (update-vehicle (vehicle-id uint) (revised-model (string-ascii 64)) (revised-mileage uint))
  (let
    (
      (vehicle (unwrap! (map-get? fleet-roster { vehicle-id: vehicle-id }) err-vehicle-missing))
    )
    (asserts! (vehicle-tracked vehicle-id) err-vehicle-missing)
    (asserts! (is-eq (get operator vehicle) tx-sender) err-no-clearance)
    (asserts! (> (len revised-model) u0) err-invalid-model)
    (asserts! (< (len revised-model) u65) err-invalid-model)
    (asserts! (> revised-mileage u0) err-invalid-mileage)
    (asserts! (< revised-mileage u1000000000) err-invalid-mileage)
    
    (map-set fleet-roster
      { vehicle-id: vehicle-id }
      (merge vehicle { model: revised-model, mileage: revised-mileage })
    )
    (ok true)
  )
)

(define-public (retire-vehicle (vehicle-id uint))
  (let
    (
      (vehicle (unwrap! (map-get? fleet-roster { vehicle-id: vehicle-id }) err-vehicle-missing))
    )
    (asserts! (vehicle-tracked vehicle-id) err-vehicle-missing)
    (asserts! (is-eq (get operator vehicle) tx-sender) err-no-clearance)
    (map-delete fleet-roster { vehicle-id: vehicle-id })
    (ok true)
  )
)

(define-public (reassign-vehicle (vehicle-id uint) (new-operator principal))
  (let
    (
      (vehicle (unwrap! (map-get? fleet-roster { vehicle-id: vehicle-id }) err-vehicle-missing))
    )
    (asserts! (vehicle-tracked vehicle-id) err-vehicle-missing)
    (asserts! (is-eq (get operator vehicle) tx-sender) err-no-clearance)
    
    (map-set fleet-roster
      { vehicle-id: vehicle-id }
      (merge vehicle { operator: new-operator })
    )
    (ok true)
  )
)

(define-public (authorize-technician (vehicle-id uint) (granted bool) (technician principal))
  (let
    (
      (vehicle (unwrap! (map-get? fleet-roster { vehicle-id: vehicle-id }) err-vehicle-missing))
    )
    (asserts! (vehicle-tracked vehicle-id) err-vehicle-missing)
    (asserts! (is-eq (get operator vehicle) tx-sender) err-no-clearance)
    
    (map-set fleet-roster
      { vehicle-id: vehicle-id }
      (merge vehicle { maintenance-access: { technician: technician, granted: granted } })
    )
    (ok true)
  )
)

(define-public (deauthorize-technician (vehicle-id uint) (granted bool) (technician principal))
  (let
    (
      (vehicle (unwrap! (map-get? fleet-roster { vehicle-id: vehicle-id }) err-vehicle-missing))
    )
    (asserts! (vehicle-tracked vehicle-id) err-vehicle-missing)
    (asserts! (is-eq (get operator vehicle) tx-sender) err-no-clearance)
    
    (map-set fleet-roster
      { vehicle-id: vehicle-id }
      (merge vehicle { maintenance-access: { technician: technician, granted: granted } })
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-fleet-count)
  (ok (var-get vehicle-inventory))
)

(define-read-only (get-vehicle-details (vehicle-id uint))
  (match (map-get? fleet-roster { vehicle-id: vehicle-id })
    vehicle-data (ok vehicle-data)
    err-vehicle-missing
  )
)

(define-private (verify-operator (vehicle-id int) (operator principal))
  (match (map-get? fleet-roster { vehicle-id: (to-uint vehicle-id) })
    vehicle-data (is-eq (get operator vehicle-data) operator)
    false
  )
)

(define-private (get-vehicle-mileage-by-operator (vehicle-id int))
  (default-to u0 
    (get mileage 
      (map-get? fleet-roster { vehicle-id: (to-uint vehicle-id) })
    )
  )
)