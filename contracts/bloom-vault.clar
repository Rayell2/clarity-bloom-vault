;; BloomVault Contract

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-VAULT-NOT-FOUND (err u102))
(define-constant ERR-INVALID-PARAMS (err u103))
(define-constant ERR-INVALID-TIMESTAMP (err u104))

;; Data structures
(define-map vaults
  { vault-id: uint }
  {
    owner: principal,
    title: (string-utf8 100),
    description: (string-utf8 500),
    created-at: uint,
    updated-at: uint,
    is-public: bool,
    is-active: bool
  }
)

(define-map memories
  { vault-id: uint, memory-id: uint }
  {
    content: (string-utf8 1000),
    timestamp: uint,
    media-url: (optional (string-utf8 200)),
    created-at: uint,
    updated-at: uint
  }
)

(define-map vault-permissions
  { vault-id: uint, user: principal }
  { can-view: bool }
)

;; Data vars
(define-data-var last-vault-id uint u0)
(define-data-var last-memory-id uint u0)

;; Events
(define-data-var last-event-id uint u0)

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
        updated-at: block-height,
        is-public: is-public,
        is-active: true
      }
    )
    (var-set last-vault-id new-vault-id)
    (print { event: "vault-created", vault-id: new-vault-id, owner: tx-sender })
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
    (asserts! (< timestamp block-height) ERR-INVALID-TIMESTAMP)
    (map-set memories
      { vault-id: vault-id, memory-id: new-memory-id }
      {
        content: content,
        timestamp: timestamp,
        media-url: media-url,
        created-at: block-height,
        updated-at: block-height
      }
    )
    (var-set last-memory-id new-memory-id)
    (print { event: "memory-added", vault-id: vault-id, memory-id: new-memory-id })
    (ok new-memory-id))
)

(define-public (edit-memory
  (vault-id uint)
  (memory-id uint)
  (content (string-utf8 1000))
  (media-url (optional (string-utf8 200)))
)
  (let
    ((memory (unwrap! (get-memory vault-id memory-id) ERR-VAULT-NOT-FOUND)))
    (asserts! (is-vault-owner vault-id) ERR-NOT-AUTHORIZED)
    (map-set memories
      { vault-id: vault-id, memory-id: memory-id }
      {
        content: content,
        timestamp: (get timestamp memory),
        media-url: media-url,
        created-at: (get created-at memory),
        updated-at: block-height
      }
    )
    (print { event: "memory-edited", vault-id: vault-id, memory-id: memory-id })
    (ok true))
)

(define-public (delete-vault (vault-id uint))
  (let
    ((vault (unwrap! (get-vault vault-id) ERR-VAULT-NOT-FOUND)))
    (asserts! (is-vault-owner vault-id) ERR-NOT-AUTHORIZED)
    (map-set vaults
      { vault-id: vault-id }
      (merge vault { is-active: false, updated-at: block-height })
    )
    (print { event: "vault-deleted", vault-id: vault-id })
    (ok true))
)

(define-public (share-vault (vault-id uint) (with-user principal))
  (let
    ((vault (unwrap! (get-vault vault-id) ERR-VAULT-NOT-FOUND)))
    (asserts! (is-vault-owner vault-id) ERR-NOT-AUTHORIZED)
    (map-set vault-permissions
      { vault-id: vault-id, user: with-user }
      { can-view: true }
    )
    (print { event: "vault-shared", vault-id: vault-id, with: with-user })
    (ok true))
)

(define-public (revoke-access (vault-id uint) (from-user principal))
  (let
    ((vault (unwrap! (get-vault vault-id) ERR-VAULT-NOT-FOUND)))
    (asserts! (is-vault-owner vault-id) ERR-NOT-AUTHORIZED)
    (map-delete vault-permissions { vault-id: vault-id, user: from-user })
    (print { event: "access-revoked", vault-id: vault-id, from: from-user })
    (ok true))
)

;; Read only functions
(define-read-only (get-vault (vault-id uint))
  (map-get? vaults { vault-id: vault-id })
)

(define-read-only (get-memory (vault-id uint) (memory-id uint))
  (let
    ((vault (unwrap! (get-vault vault-id) ERR-VAULT-NOT-FOUND)))
    (asserts! (or (get is-public vault) 
                 (is-vault-owner vault-id)
                 (has-view-permission vault-id tx-sender)) 
             ERR-NOT-AUTHORIZED)
    (map-get? memories { vault-id: vault-id, memory-id: memory-id }))
)

(define-read-only (has-view-permission (vault-id uint) (user principal))
  (default-to
    false
    (get can-view (map-get? vault-permissions { vault-id: vault-id, user: user })))
)

;; Private functions
(define-private (is-vault-owner (vault-id uint))
  (let
    ((vault (unwrap! (get-vault vault-id) false)))
    (is-eq (get owner vault) tx-sender))
)
