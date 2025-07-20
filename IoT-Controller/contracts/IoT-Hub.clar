;; Decentralized IoT Management Smart Contract
;; A comprehensive system for managing IoT devices, data, access control, and monetization

;; CONSTANTS AND ERROR CODES

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u1001))
(define-constant ERR-DEVICE-NOT-FOUND (err u1002))
(define-constant ERR-DEVICE-ALREADY-EXISTS (err u1003))
(define-constant ERR-INVALID-PARAMETERS (err u1004))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u1005))
(define-constant ERR-DEVICE-OFFLINE (err u1006))
(define-constant ERR-ACCESS-DENIED (err u1007))
(define-constant ERR-DATA-NOT-FOUND (err u1008))
(define-constant ERR-INVALID-TIMESTAMP (err u1009))
(define-constant ERR-DEVICE-MAINTENANCE (err u1010))
(define-constant ERR-SUBSCRIPTION-EXPIRED (err u1011))
(define-constant ERR-INVALID-DEVICE-TYPE (err u1012))
(define-constant ERR-INVALID-STRING-LENGTH (err u1013))
(define-constant ERR-INVALID-PRINCIPAL (err u1014))
(define-constant ERR-INVALID-BUFFER (err u1015))

;; Device status constants
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-INACTIVE u2)
(define-constant STATUS-MAINTENANCE u3)
(define-constant STATUS-OFFLINE u4)

;; Device type constants
(define-constant TYPE-SENSOR u1)
(define-constant TYPE-ACTUATOR u2)
(define-constant TYPE-GATEWAY u3)
(define-constant TYPE-HYBRID u4)

;; Access level constants
(define-constant ACCESS-READ u1)
(define-constant ACCESS-WRITE u2)
(define-constant ACCESS-ADMIN u3)

;; Maximum values for validation
(define-constant MAX-METADATA-LENGTH u500)
(define-constant MAX-FIRMWARE-VERSION-LENGTH u20)
(define-constant MAX-DESCRIPTION-LENGTH u300)
(define-constant MAX-DATA-TYPE-LENGTH u50)
(define-constant MAX-MAINTENANCE-TYPE-LENGTH u100)
(define-constant MAX-NOTES-LENGTH u300)
(define-constant MAX-NAME-LENGTH u100)
(define-constant MAX-LOCATION-LENGTH u100)
(define-constant MAX-PRICE u1000000000) ;; 1 billion microSTX max
(define-constant HASH-LENGTH u32)
(define-constant MAX-SENSOR-VALUE 2147483647) ;; Maximum int value
(define-constant MIN-SENSOR-VALUE -2147483648) ;; Minimum int value

;; DATA STRUCTURES

;; IoT Device Structure
(define-map devices
  { device-id: (string-ascii 64) }
  {
    owner: principal,
    device-type: uint,
    status: uint,
    location: (string-ascii 100),
    metadata: (string-ascii 500),
    last-update: uint,
    firmware-version: (string-ascii 20),
    data-price: uint,
    access-price: uint,
    reputation-score: uint,
    total-earnings: uint
  }
)

;; Device Data Storage
(define-map device-data
  { device-id: (string-ascii 64), timestamp: uint }
  {
    data-hash: (buff 32),
    data-type: (string-ascii 50),
    sensor-value: (optional int),
    data-size: uint,
    verification-hash: (buff 32)
  }
)

;; Access Control Lists
(define-map device-access
  { device-id: (string-ascii 64), user: principal }
  {
    access-level: uint,
    expiry-time: uint,
    granted-by: principal,
    access-count: uint
  }
)

;; Device Networks/Groups
(define-map device-networks
  { network-id: (string-ascii 64) }
  {
    owner: principal,
    name: (string-ascii 100),
    description: (string-ascii 300),
    device-count: uint,
    is-public: bool,
    network-fee: uint
  }
)

;; Network Membership
(define-map network-members
  { network-id: (string-ascii 64), device-id: (string-ascii 64) }
  {
    joined-at: uint,
    role: uint,
    contribution-score: uint
  }
)

;; Data Subscriptions
(define-map subscriptions
  { subscriber: principal, device-id: (string-ascii 64) }
  {
    subscription-type: uint,
    start-time: uint,
    end-time: uint,
    price-paid: uint,
    data-requests: uint
  }
)

;; Device Maintenance Records
(define-map maintenance-records
  { device-id: (string-ascii 64), maintenance-id: uint }
  {
    scheduled-by: principal,
    start-time: uint,
    end-time: (optional uint),
    maintenance-type: (string-ascii 100),
    notes: (string-ascii 300),
    cost: uint
  }
)

;; DATA VARIABLES

(define-data-var total-devices uint u0)
(define-data-var total-networks uint u0)
(define-data-var platform-fee-rate uint u250) ;; 2.5% in basis points
(define-data-var maintenance-counter uint u0)
(define-data-var contract-paused bool false)

;; VALIDATION FUNCTIONS

(define-private (validate-string-length (str (string-ascii 500)) (max-len uint))
  (and (> (len str) u0) (<= (len str) max-len))
)

(define-private (validate-buffer-length (buf (buff 32)) (expected-len uint))
  (is-eq (len buf) expected-len)
)

(define-private (validate-price (price uint))
  (<= price MAX-PRICE)
)

(define-private (validate-principal (user principal))
  (not (is-eq user 'SP000000000000000000002Q6VF78))
)

(define-private (validate-metadata (metadata (string-ascii 500)))
  (validate-string-length metadata MAX-METADATA-LENGTH)
)

(define-private (validate-firmware-version (version (string-ascii 20)))
  (validate-string-length version MAX-FIRMWARE-VERSION-LENGTH)
)

(define-private (validate-description (description (string-ascii 300)))
  (validate-string-length description MAX-DESCRIPTION-LENGTH)
)

(define-private (validate-data-type (data-type (string-ascii 50)))
  (validate-string-length data-type MAX-DATA-TYPE-LENGTH)
)

(define-private (validate-maintenance-type (maint-type (string-ascii 100)))
  (validate-string-length maint-type MAX-MAINTENANCE-TYPE-LENGTH)
)

(define-private (validate-notes (notes (string-ascii 300)))
  (validate-string-length notes MAX-NOTES-LENGTH)
)

(define-private (validate-name (name (string-ascii 100)))
  (validate-string-length name MAX-NAME-LENGTH)
)

(define-private (validate-location (location (string-ascii 100)))
  (validate-string-length location MAX-LOCATION-LENGTH)
)

(define-private (validate-hash (hash (buff 32)))
  (validate-buffer-length hash HASH-LENGTH)
)

(define-private (validate-sensor-value (value (optional int)))
  (match value
    some-value (and (>= some-value MIN-SENSOR-VALUE) (<= some-value MAX-SENSOR-VALUE))
    true ;; None is always valid
  )
)

(define-private (validate-maintenance-id (maint-id uint))
  (and (> maint-id u0) (<= maint-id (var-get maintenance-counter)))
)

;; PRIVATE FUNCTIONS

(define-private (is-contract-owner (user principal))
  (is-eq user CONTRACT-OWNER)
)

(define-private (is-device-owner (device-id (string-ascii 64)) (user principal))
  (match (map-get? devices { device-id: device-id })
    device-info (is-eq (get owner device-info) user)
    false
  )
)

(define-private (device-exists (device-id (string-ascii 64)))
  (is-some (map-get? devices { device-id: device-id }))
)

(define-private (is-valid-device-type (device-type uint))
  (and (>= device-type TYPE-SENSOR) (<= device-type TYPE-HYBRID))
)

(define-private (is-valid-status (status uint))
  (and (>= status STATUS-ACTIVE) (<= status STATUS-OFFLINE))
)

(define-private (has-device-access (device-id (string-ascii 64)) (user principal) (required-level uint))
  (match (map-get? device-access { device-id: device-id, user: user })
    access-info (and 
      (>= (get access-level access-info) required-level)
      (> (get expiry-time access-info) block-height)
    )
    (is-device-owner device-id user)
  )
)

(define-private (calculate-platform-fee (amount uint))
  (/ (* amount (var-get platform-fee-rate)) u10000)
)

(define-private (update-device-earnings (device-id (string-ascii 64)) (amount uint))
  (match (map-get? devices { device-id: device-id })
    device-info 
    (begin
      (map-set devices 
        { device-id: device-id }
        (merge device-info { 
          total-earnings: (+ (get total-earnings device-info) amount)
        })
      )
      true
    )
    false
  )
)

(define-private (is-subscription-valid (subscriber principal) (device-id (string-ascii 64)))
  (match (map-get? subscriptions { subscriber: subscriber, device-id: device-id })
    sub-info (> (get end-time sub-info) block-height)
    false
  )
)

;; PUBLIC FUNCTIONS - DEVICE MANAGEMENT

;; Register a new IoT device
(define-public (register-device 
  (device-id (string-ascii 64))
  (device-type uint)
  (location (string-ascii 100))
  (metadata (string-ascii 500))
  (firmware-version (string-ascii 20))
  (data-price uint)
  (access-price uint)
)
  (begin
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (not (device-exists device-id)) ERR-DEVICE-ALREADY-EXISTS)
    (asserts! (is-valid-device-type device-type) ERR-INVALID-DEVICE-TYPE)
    (asserts! (> (len device-id) u0) ERR-INVALID-PARAMETERS)
    (asserts! (validate-location location) ERR-INVALID-STRING-LENGTH)
    (asserts! (validate-metadata metadata) ERR-INVALID-STRING-LENGTH)
    (asserts! (validate-firmware-version firmware-version) ERR-INVALID-STRING-LENGTH)
    (asserts! (validate-price data-price) ERR-INVALID-PARAMETERS)
    (asserts! (validate-price access-price) ERR-INVALID-PARAMETERS)
    
    (map-set devices
      { device-id: device-id }
      {
        owner: tx-sender,
        device-type: device-type,
        status: STATUS-ACTIVE,
        location: location,
        metadata: metadata,
        last-update: block-height,
        firmware-version: firmware-version,
        data-price: data-price,
        access-price: access-price,
        reputation-score: u100,
        total-earnings: u0
      }
    )
    
    (var-set total-devices (+ (var-get total-devices) u1))
    (ok device-id)
  )
)

;; Update device information
(define-public (update-device
  (device-id (string-ascii 64))
  (location (optional (string-ascii 100)))
  (metadata (optional (string-ascii 500)))
  (firmware-version (optional (string-ascii 20)))
  (data-price (optional uint))
  (access-price (optional uint))
)
  (begin
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (device-exists device-id) ERR-DEVICE-NOT-FOUND)
    (asserts! (is-device-owner device-id tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Validate optional parameters if provided
    (match location 
      some-location (asserts! (validate-location some-location) ERR-INVALID-STRING-LENGTH)
      true)
    (match metadata 
      some-metadata (asserts! (validate-metadata some-metadata) ERR-INVALID-STRING-LENGTH)
      true)
    (match firmware-version 
      some-version (asserts! (validate-firmware-version some-version) ERR-INVALID-STRING-LENGTH)
      true)
    (match data-price 
      some-price (asserts! (validate-price some-price) ERR-INVALID-PARAMETERS)
      true)
    (match access-price 
      some-price (asserts! (validate-price some-price) ERR-INVALID-PARAMETERS)
      true)
    
    (match (map-get? devices { device-id: device-id })
      device-info
      (begin
        (map-set devices
          { device-id: device-id }
          (merge device-info {
            location: (default-to (get location device-info) location),
            metadata: (default-to (get metadata device-info) metadata),
            firmware-version: (default-to (get firmware-version device-info) firmware-version),
            data-price: (default-to (get data-price device-info) data-price),
            access-price: (default-to (get access-price device-info) access-price),
            last-update: block-height
          })
        )
        (ok true)
      )
      ERR-DEVICE-NOT-FOUND
    )
  )
)

;; Update device status
(define-public (update-device-status (device-id (string-ascii 64)) (new-status uint))
  (begin
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (device-exists device-id) ERR-DEVICE-NOT-FOUND)
    (asserts! (is-device-owner device-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-status new-status) ERR-INVALID-PARAMETERS)
    
    (match (map-get? devices { device-id: device-id })
      device-info
      (begin
        (map-set devices
          { device-id: device-id }
          (merge device-info {
            status: new-status,
            last-update: block-height
          })
        )
        (ok true)
      )
      ERR-DEVICE-NOT-FOUND
    )
  )
)

;; PUBLIC FUNCTIONS - DATA MANAGEMENT

;; Store device data
(define-public (store-device-data
  (device-id (string-ascii 64))
  (data-hash (buff 32))
  (data-type (string-ascii 50))
  (sensor-value (optional int))
  (data-size uint)
  (verification-hash (buff 32))
)
  (begin
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (device-exists device-id) ERR-DEVICE-NOT-FOUND)
    (asserts! (has-device-access device-id tx-sender ACCESS-WRITE) ERR-ACCESS-DENIED)
    (asserts! (> data-size u0) ERR-INVALID-PARAMETERS)
    (asserts! (validate-hash data-hash) ERR-INVALID-BUFFER)
    (asserts! (validate-data-type data-type) ERR-INVALID-STRING-LENGTH)
    (asserts! (validate-sensor-value sensor-value) ERR-INVALID-PARAMETERS)
    (asserts! (validate-hash verification-hash) ERR-INVALID-BUFFER)
    
    ;; Check if device is active
    (let ((device-info (unwrap! (map-get? devices { device-id: device-id }) ERR-DEVICE-NOT-FOUND)))
      (asserts! (is-eq (get status device-info) STATUS-ACTIVE) ERR-DEVICE-OFFLINE)
      
      (map-set device-data
        { device-id: device-id, timestamp: block-height }
        {
          data-hash: data-hash,
          data-type: data-type,
          sensor-value: sensor-value,
          data-size: data-size,
          verification-hash: verification-hash
        }
      )
      
      ;; Update device last-update timestamp
      (map-set devices
        { device-id: device-id }
        (merge device-info { last-update: block-height })
      )
      
      (ok block-height)
    )
  )
)

;; Purchase access to device data
(define-public (purchase-data-access (device-id (string-ascii 64)) (duration uint))
  (begin
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (device-exists device-id) ERR-DEVICE-NOT-FOUND)
    (asserts! (> duration u0) ERR-INVALID-PARAMETERS)
    
    (match (map-get? devices { device-id: device-id })
      device-info
      (let (
        (total-cost (* (get data-price device-info) duration))
        (platform-fee (calculate-platform-fee total-cost))
        (owner-payment (- total-cost platform-fee))
      )
        (asserts! (>= (stx-get-balance tx-sender) total-cost) ERR-INSUFFICIENT-PAYMENT)
        
        ;; Transfer payment to device owner
        (try! (stx-transfer? owner-payment tx-sender (get owner device-info)))
        
        ;; Transfer platform fee to contract owner
        (try! (stx-transfer? platform-fee tx-sender CONTRACT-OWNER))
        
        ;; Grant access
        (map-set device-access
          { device-id: device-id, user: tx-sender }
          {
            access-level: ACCESS-READ,
            expiry-time: (+ block-height duration),
            granted-by: (get owner device-info),
            access-count: u0
          }
        )
        
        ;; Update device earnings
        (update-device-earnings device-id owner-payment)
        
        (ok true)
      )
      ERR-DEVICE-NOT-FOUND
    )
  )
)

;; PUBLIC FUNCTIONS - ACCESS CONTROL

;; Grant device access
(define-public (grant-device-access
  (device-id (string-ascii 64))
  (user principal)
  (access-level uint)
  (duration uint)
)
  (begin
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (device-exists device-id) ERR-DEVICE-NOT-FOUND)
    (asserts! (is-device-owner device-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= access-level ACCESS-READ) (<= access-level ACCESS-ADMIN)) ERR-INVALID-PARAMETERS)
    (asserts! (> duration u0) ERR-INVALID-PARAMETERS)
    (asserts! (validate-principal user) ERR-INVALID-PRINCIPAL)
    
    (map-set device-access
      { device-id: device-id, user: user }
      {
        access-level: access-level,
        expiry-time: (+ block-height duration),
        granted-by: tx-sender,
        access-count: u0
      }
    )
    
    (ok true)
  )
)

;; Revoke device access
(define-public (revoke-device-access (device-id (string-ascii 64)) (user principal))
  (begin
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (device-exists device-id) ERR-DEVICE-NOT-FOUND)
    (asserts! (is-device-owner device-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (validate-principal user) ERR-INVALID-PRINCIPAL)
    
    (map-delete device-access { device-id: device-id, user: user })
    (ok true)
  )
)

;; PUBLIC FUNCTIONS - NETWORK MANAGEMENT

;; Create device network
(define-public (create-network
  (network-id (string-ascii 64))
  (name (string-ascii 100))
  (description (string-ascii 300))
  (is-public bool)
  (network-fee uint)
)
  (begin
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? device-networks { network-id: network-id })) ERR-DEVICE-ALREADY-EXISTS)
    (asserts! (> (len network-id) u0) ERR-INVALID-PARAMETERS)
    (asserts! (validate-name name) ERR-INVALID-STRING-LENGTH)
    (asserts! (validate-description description) ERR-INVALID-STRING-LENGTH)
    (asserts! (validate-price network-fee) ERR-INVALID-PARAMETERS)
    
    (map-set device-networks
      { network-id: network-id }
      {
        owner: tx-sender,
        name: name,
        description: description,
        device-count: u0,
        is-public: is-public,
        network-fee: network-fee
      }
    )
    
    (var-set total-networks (+ (var-get total-networks) u1))
    (ok network-id)
  )
)

;; Join device to network
(define-public (join-network (network-id (string-ascii 64)) (device-id (string-ascii 64)))
  (begin
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (device-exists device-id) ERR-DEVICE-NOT-FOUND)
    (asserts! (is-device-owner device-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len network-id) u0) ERR-INVALID-PARAMETERS)
    
    (match (map-get? device-networks { network-id: network-id })
      network-info
      (begin
        ;; Check if network is public or user has permission
        (asserts! (or (get is-public network-info) (is-eq tx-sender (get owner network-info))) ERR-ACCESS-DENIED)
        
        ;; Pay network fee if required
        (if (> (get network-fee network-info) u0)
          (try! (stx-transfer? (get network-fee network-info) tx-sender (get owner network-info)))
          true
        )
        
        ;; Add device to network
        (map-set network-members
          { network-id: network-id, device-id: device-id }
          {
            joined-at: block-height,
            role: u1,
            contribution-score: u0
          }
        )
        
        ;; Update network device count
        (map-set device-networks
          { network-id: network-id }
          (merge network-info { device-count: (+ (get device-count network-info) u1) })
        )
        
        (ok true)
      )
      ERR-DEVICE-NOT-FOUND
    )
  )
)

;; PUBLIC FUNCTIONS - MAINTENANCE

;; Schedule device maintenance
(define-public (schedule-maintenance
  (device-id (string-ascii 64))
  (start-time uint)
  (maintenance-type (string-ascii 100))
  (notes (string-ascii 300))
  (estimated-cost uint)
)
  (begin
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (device-exists device-id) ERR-DEVICE-NOT-FOUND)
    (asserts! (is-device-owner device-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> start-time block-height) ERR-INVALID-TIMESTAMP)
    (asserts! (validate-maintenance-type maintenance-type) ERR-INVALID-STRING-LENGTH)
    (asserts! (validate-notes notes) ERR-INVALID-STRING-LENGTH)
    (asserts! (validate-price estimated-cost) ERR-INVALID-PARAMETERS)
    
    (let ((maintenance-id (+ (var-get maintenance-counter) u1)))
      (map-set maintenance-records
        { device-id: device-id, maintenance-id: maintenance-id }
        {
          scheduled-by: tx-sender,
          start-time: start-time,
          end-time: none,
          maintenance-type: maintenance-type,
          notes: notes,
          cost: estimated-cost
        }
      )
      
      (var-set maintenance-counter maintenance-id)
      (ok maintenance-id)
    )
  )
)

;; Complete maintenance
(define-public (complete-maintenance
  (device-id (string-ascii 64))
  (maintenance-id uint)
  (actual-cost uint)
)
  (begin
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (device-exists device-id) ERR-DEVICE-NOT-FOUND)
    (asserts! (is-device-owner device-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (validate-price actual-cost) ERR-INVALID-PARAMETERS)
    
    ;; Validate maintenance-id exists and is valid
    (asserts! (> maintenance-id u0) ERR-INVALID-PARAMETERS)
    
    (match (map-get? maintenance-records { device-id: device-id, maintenance-id: maintenance-id })
      maintenance-info
      (begin
        (asserts! (is-none (get end-time maintenance-info)) ERR-INVALID-PARAMETERS)
        
        (map-set maintenance-records
          { device-id: device-id, maintenance-id: maintenance-id }
          (merge maintenance-info {
            end-time: (some block-height),
            cost: actual-cost
          })
        )
        
        ;; Update device status back to active
        (try! (update-device-status device-id STATUS-ACTIVE))
        
        (ok true)
      )
      ERR-DATA-NOT-FOUND
    )
  )
)

;; READ-ONLY FUNCTIONS

;; Get device information
(define-read-only (get-device-info (device-id (string-ascii 64)))
  (map-get? devices { device-id: device-id })
)

;; Get device data
(define-read-only (get-device-data (device-id (string-ascii 64)) (timestamp uint))
  (map-get? device-data { device-id: device-id, timestamp: timestamp })
)

;; Check device access
(define-read-only (check-device-access (device-id (string-ascii 64)) (user principal))
  (map-get? device-access { device-id: device-id, user: user })
)

;; Get network information
(define-read-only (get-network-info (network-id (string-ascii 64)))
  (map-get? device-networks { network-id: network-id })
)

;; Get maintenance record
(define-read-only (get-maintenance-record (device-id (string-ascii 64)) (maintenance-id uint))
  (map-get? maintenance-records { device-id: device-id, maintenance-id: maintenance-id })
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-devices: (var-get total-devices),
    total-networks: (var-get total-networks),
    platform-fee-rate: (var-get platform-fee-rate),
    contract-paused: (var-get contract-paused)
  }
)

;; ADMIN FUNCTIONS

;; Pause/unpause contract
(define-public (toggle-contract-pause)
  (begin
    (asserts! (is-contract-owner tx-sender) ERR-NOT-AUTHORIZED)
    (var-set contract-paused (not (var-get contract-paused)))
    (ok (var-get contract-paused))
  )
)

;; Update platform fee
(define-public (update-platform-fee (new-fee-rate uint))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-fee-rate u1000) ERR-INVALID-PARAMETERS) ;; Max 10%
    (var-set platform-fee-rate new-fee-rate)
    (ok new-fee-rate)
  )
)

;; Emergency device status update (admin only)
(define-public (admin-update-device-status (device-id (string-ascii 64)) (new-status uint))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (device-exists device-id) ERR-DEVICE-NOT-FOUND)
    (asserts! (is-valid-status new-status) ERR-INVALID-PARAMETERS)
    
    (match (map-get? devices { device-id: device-id })
      device-info
      (begin
        (map-set devices
          { device-id: device-id }
          (merge device-info {
            status: new-status,
            last-update: block-height
          })
        )
        (ok true)
      )
      ERR-DEVICE-NOT-FOUND
    )
  )
)