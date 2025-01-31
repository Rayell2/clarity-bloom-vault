;; BloomVault Contract

;; Data structures
(define-map vaults
  { vault-id: uint }
  {
    owner: principal,
    title: (string-utf8 100),
    description: (string-utf8 500),
    created-at: uint,
    is-public: bool
  }
)

(define-map memories
  { vault-id: uint, memory-id: uint }
  {
    content: (string-utf8 1000),
    timestamp: uint,
    media-url: (optional (string-utf8 200))
  }
)

(define-map vault-permissions
  { vault-id: uint, user: principal }
  { can-view: bool }
)

;; Data vars
(define-data-var last-vault-id uint u0)
(define-data-var last-memory-id uint u0)

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-VAULT-NOT-FOUND (err u102))
(define-constant ERR-INVALID-PARAMS (err u103))

;; Public functions
(define-public (create-vault (title (string-utf8 100)) (description (string-utf8 500)) (is-public bool))
  (let
    ((new-vault-id (+ (var-get last-vault-id) u1)))
    (map-set vaults
      { vault-id: new-vault-id }
      {
        owner: tx-sender,
        title: title,
        description: description,
        created-at: block-height,
        is-public: is-public
      }
    )
    (var-set last-vault-id new-vault-id)
    (ok new-vault-id))
)

(define-public (add-memory 
  (vault-id uint)
  (content (string-utf8 1000))
  (timestamp uint)
  (media-url (optional (string-utf8 200)))
)
  (let
    ((vault (unwrap! (get-vault vault-id) ERR-VAULT-NOT-FOUND))
     (new-memory-id (+ (var-get last-memory-id) u1)))
    (asserts! (is-vault-owner vault-id) ERR-NOT-AUTHORIZED)
    (map-set memories
      { vault-id: vault-id, memory-id: new-memory-id }
      {
        content: content,
        timestamp: timestamp,
        media-url: media-url
      }
    )
    (var-set last-memory-id new-memory-id)
    (ok new-memory-id))
)

(define-public (share-vault (vault-id uint) (with-user principal))
  (let
    ((vault (unwrap! (get-vault vault-id) ERR-VAULT-NOT-FOUND)))
    (asserts! (is-vault-owner vault-id) ERR-NOT-AUTHORIZED)
    (map-set vault-permissions
      { vault-id: vault-id, user: with-user }
      { can-view: true }
    )
    (ok true))
)

;; Read only functions
(define-read-only (get-vault (vault-id uint))
  (map-get? vaults { vault-id: vault-id })
)

(define-read-only (get-memory (vault-id uint) (memory-id uint))
  (map-get? memories { vault-id: vault-id, memory-id: memory-id })
)

;; Private functions
(define-private (is-vault-owner (vault-id uint))
  (let
    ((vault (unwrap! (get-vault vault-id) false)))
    (is-eq (get owner vault) tx-sender))
)
