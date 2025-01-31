;; real-estate-token.clar
;; Core contract for Real Estate Tokenization Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-shares (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-insufficient-funds (err u104))
(define-constant err-invalid-price (err u105))
(define-constant err-invalid-name (err u106))
(define-constant err-invalid-location (err u107))
(define-constant err-invalid-recipient (err u108))

;; Data Maps
(define-map properties 
    { property-id: uint }
    {
        name: (string-ascii 64),
        location: (string-ascii 256),
        total-shares: uint,
        available-shares: uint,
        price-per-share: uint,
        total-value: uint,
        owner: principal,
        is-fractionalized: bool
    }
)

(define-map share-holdings
    { property-id: uint, holder: principal }
    { shares: uint }
)

;; Property counter for unique IDs
(define-data-var next-property-id uint u1)

;; SIP-009: NFT Interface Implementation
(define-non-fungible-token property-nft uint)

;; Read-only functions
(define-read-only (get-property-details (property-id uint))
    (map-get? properties { property-id: property-id })
)

(define-read-only (get-share-balance (property-id uint) (holder principal))
    (default-to { shares: u0 }
        (map-get? share-holdings { property-id: property-id, holder: holder })
    )
)

(define-read-only (get-owner (property-id uint))
    (nft-get-owner? property-nft property-id)
)

;; Input validation functions
(define-private (is-valid-name (name (string-ascii 64)))
    (and
        (not (is-eq name ""))
        (<= (len name) u64)
    )
)

(define-private (is-valid-location (location (string-ascii 256)))
    (and
        (not (is-eq location ""))
        (<= (len location) u256)
    )
)

(define-private (is-valid-price (price uint))
    (and
        (> price u0)
        (<= price u1000000000000) ;; Set reasonable maximum price
    )
)

;; Public functions
(define-public (register-property 
        (name (string-ascii 64))
        (location (string-ascii 256))
        (total-shares uint)
        (price-per-share uint))
    (let (
        (property-id (var-get next-property-id))
        (total-value (* total-shares price-per-share))
    )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-valid-name name) err-invalid-name)
        (asserts! (is-valid-location location) err-invalid-location)
        (asserts! (> total-shares u0) err-invalid-shares)
        (asserts! (is-valid-price price-per-share) err-invalid-price)
        (asserts! (> total-value u0) err-invalid-price) ;; Ensure total value is positive
        
        (try! (nft-mint? property-nft property-id tx-sender))
        (map-set properties
            { property-id: property-id }
            {
                name: name,
                location: location,
                total-shares: total-shares,
                available-shares: total-shares,
                price-per-share: price-per-share,
                total-value: total-value,
                owner: tx-sender,
                is-fractionalized: false
            }
        )
        (var-set next-property-id (+ property-id u1))
        (ok property-id)
    )
)

(define-public (fractionalize-property (property-id uint))
    (let (
        (property (unwrap! (get-property-details property-id) err-not-found))
        (current-owner (unwrap! (get-owner property-id) err-not-found))
    )
        (asserts! (is-eq tx-sender current-owner) err-owner-only)
        (asserts! (not (get is-fractionalized property)) err-already-exists)
        (map-set properties
            { property-id: property-id }
            (merge property { is-fractionalized: true })
        )
        (ok true)
    )
)

(define-public (purchase-shares (property-id uint) (share-amount uint))
    (let (
        (property (unwrap! (get-property-details property-id) err-not-found))
        (current-balance (get shares (get-share-balance property-id tx-sender)))
        (available-shares (get available-shares property))
    )
        (asserts! (get is-fractionalized property) err-not-found)
        (asserts! (and (> share-amount u0) (<= share-amount available-shares)) err-invalid-shares)
        (asserts! (> (* share-amount (get price-per-share property)) u0) err-invalid-price)
        
        ;; Update available shares
        (map-set properties
            { property-id: property-id }
            (merge property 
                { available-shares: (- available-shares share-amount) }
            )
        )
        
        ;; Update share holdings
        (map-set share-holdings
            { property-id: property-id, holder: tx-sender }
            { shares: (+ current-balance share-amount) }
        )
        (ok true)
    )
)

(define-public (transfer-shares (property-id uint) (amount uint) (recipient principal))
    (let (
        (sender-balance (get shares (get-share-balance property-id tx-sender)))
        (recipient-balance (get shares (get-share-balance property-id recipient)))
    )
        (asserts! (not (is-eq recipient tx-sender)) err-invalid-recipient)
        (asserts! (> amount u0) err-invalid-shares)
        (asserts! (>= sender-balance amount) err-insufficient-funds)
        (let (
            (property (unwrap! (get-property-details property-id) err-not-found))
        )
            (asserts! (<= (+ recipient-balance amount) (get total-shares property)) err-invalid-shares)
        )
        
        ;; Update sender balance
        (map-set share-holdings
            { property-id: property-id, holder: tx-sender }
            { shares: (- sender-balance amount) }
        )
        
        ;; Update recipient balance
        (map-set share-holdings
            { property-id: property-id, holder: recipient }
            { shares: (+ recipient-balance amount) }
        )
        (ok true)
    )
)

;; Administrative functions
(define-public (update-price-per-share (property-id uint) (new-price uint))
    (let (
        (property (unwrap! (get-property-details property-id) err-not-found))
        (total-shares (get total-shares property))
        (next-id (var-get next-property-id))
    )
        ;; Validate property-id is within valid range
        (asserts! (< property-id next-id) err-not-found)
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-valid-price new-price) err-invalid-price)
        (asserts! (> (* total-shares new-price) u0) err-invalid-price)
        
        ;; Only proceed if property exists and all checks pass
        (ok (map-set properties
            { property-id: property-id }
            (merge property 
                { 
                    price-per-share: new-price,
                    total-value: (* total-shares new-price)
                }
            ))
        )
    )
)