;; Carbon Credit Marketplace
;; A comprehensive decentralized platform for carbon offset project registration,
;; third-party verification, credit tokenization, peer-to-peer trading, and 
;; transparent retirement tracking with immutable proof of environmental impact

;; ERROR CONSTANTS
(define-constant ERR-NOT-FOUND u404)
(define-constant ERR-UNAUTHORIZED-ACCESS u403)
(define-constant ERR-INVALID-INPUT u400)
(define-constant ERR-INSUFFICIENT-BALANCE u402)
(define-constant ERR-INVALID-PROJECT-TYPE u410)
(define-constant ERR-INVALID-DATE-RANGE u411)
(define-constant ERR-EMPTY-FIELD u412)
(define-constant ERR-PROJECT-NOT-VERIFIED u413)
(define-constant ERR-PROJECT-INACTIVE u414)
(define-constant ERR-INSUFFICIENT-CREDITS u415)
(define-constant ERR-BATCH-UNAVAILABLE u416)
(define-constant ERR-PAYMENT-FAILED u417)
(define-constant ERR-CERTIFICATE-EXISTS u418)
(define-constant ERR-SELF-AUTHORIZATION u419)
(define-constant ERR-INVALID-VINTAGE-YEAR u420)

;; PLATFORM CONSTANTS
(define-constant minimum-vintage-year u2010)
(define-constant maximum-project-types u10)
(define-constant platform-admin tx-sender)

;; SIP-010 FUNGIBLE TOKEN TRAIT
(define-trait carbon-credit-token-trait
  (
    (transfer (uint principal principal (optional (buff 256))) (response bool uint))
    (get-balance (principal) (response uint uint))
    (get-total-supply () (response uint uint))
    (get-name () (response (string-ascii 32) uint))
    (get-symbol () (response (string-ascii 32) uint))
    (get-decimals () (response uint uint))
    (get-token-uri () (response (optional (string-utf8 256)) uint))
  )
)

;; DATA VARIABLES
(define-data-var supported-project-categories (list 10 (string-ascii 64)) 
  (list 
    "renewable-energy" 
    "reforestation-afforestation" 
    "methane-capture-destruction" 
    "energy-efficiency-improvement" 
    "carbon-capture-storage"
    "sustainable-agriculture"
    "waste-management"
    "transportation-electrification"
  )
)

(define-data-var current-project-identifier uint u1)
(define-data-var current-batch-identifier uint u1)
(define-data-var current-retirement-identifier uint u1)

;; CORE DATA STRUCTURES

;; Environmental Project Registry
(define-map environmental-project-registry
  { project-identifier: uint }
  {
    project-name: (string-utf8 128),
    detailed-description: (string-utf8 1024),
    geographical-location: (string-utf8 128),
    project-owner-principal: principal,
    environmental-category: (string-ascii 64),
    implementation-start-date: uint,
    expected-completion-date: uint,
    total-verified-credits: uint,
    credits-available-for-sale: uint,
    credits-permanently-retired: uint,
    verification-status-confirmed: bool,
    verification-metadata: (optional (buff 256)),
    current-project-status: (string-ascii 32),
    registry-documentation-url: (string-utf8 256),
    registration-block-height: uint
  }
)

;; Third-Party Verification Records
(define-map third-party-verification-records
  { project-identifier: uint, verification-sequence-number: uint }
  {
    authorized-verifier-principal: principal,
    verification-timestamp: uint,
    verified-credits-quantity: uint,
    verification-report-url: (string-utf8 256),
    applied-methodology-standard: (string-ascii 64),
    monitoring-period-start: uint,
    monitoring-period-end: uint
  }
)

;; Tradeable Credit Batches
(define-map tradeable-credit-batches
  { batch-identifier: uint }
  {
    source-project-identifier: uint,
    credit-vintage-year: uint,
    total-batch-quantity: uint,
    remaining-available-quantity: uint,
    unit-price-in-ustx: uint,
    batch-creation-timestamp: uint,
    current-batch-status: (string-ascii 32)
  }
)

;; User Credit Portfolio
(define-map user-credit-portfolio
  { holder-principal: principal, credit-vintage-year: uint, source-project-identifier: uint }
  { owned-credit-balance: uint }
)

;; Permanent Credit Retirement Log
(define-map permanent-credit-retirement-log
  { retirement-transaction-id: uint }
  {
    retiring-user-principal: principal,
    retired-project-identifier: uint,
    retired-batch-identifier: uint,
    retired-credits-quantity: uint,
    retirement-justification: (string-utf8 256),
    retirement-beneficiary-principal: (optional principal),
    retirement-block-timestamp: uint,
    digital-certificate-url: (optional (string-utf8 256))
  }
)

;; Authorized Verification Entities
(define-map authorized-verification-entities
  { verifier-principal: principal }
  {
    organization-name: (string-utf8 128),
    accreditation-credentials: (string-utf8 256),
    authorization-block-height: uint,
    authorizing-admin-principal: principal,
    verifier-account-status: (string-ascii 32)
  }
)

;; Verification Sequence Tracking
(define-map project-verification-sequence-tracking
  { project-identifier: uint }
  { next-verification-sequence-number: uint }
)

;; UTILITY FUNCTIONS

;; Validate Environmental Project Category
(define-private (validate-environmental-project-category (category-name (string-ascii 64)))
  (is-some (index-of (var-get supported-project-categories) category-name))
)

;; Check Platform Administrator Privileges
(define-private (verify-platform-administrator-privileges)
  (is-eq tx-sender platform-admin)
)

;; Validate Authorized Verification Entity
(define-private (validate-authorized-verification-entity (verifier-principal principal))
  (match (map-get? authorized-verification-entities { verifier-principal: verifier-principal })
    verification-entity-data 
      (is-eq (get verifier-account-status verification-entity-data) "active")
    false
  )
)

;; Retrieve Next Verification Sequence Number
(define-private (retrieve-next-verification-sequence-number (project-identifier uint))
  (get next-verification-sequence-number
    (default-to 
      { next-verification-sequence-number: u0 }
      (map-get? project-verification-sequence-tracking { project-identifier: project-identifier })
    )
  )
)

;; CORE BUSINESS FUNCTIONS

;; Register New Environmental Project
(define-public (register-new-environmental-project
                (project-name (string-utf8 128))
                (detailed-description (string-utf8 1024))
                (geographical-location (string-utf8 128))
                (environmental-category (string-ascii 64))
                (implementation-start-date uint)
                (expected-completion-date uint)
                (registry-documentation-url (string-utf8 256)))
  (let
    ((new-project-identifier (var-get current-project-identifier)))
    
    ;; Input Validation Checks
    (asserts! (validate-environmental-project-category environmental-category) 
              (err ERR-INVALID-PROJECT-TYPE))
    (asserts! (< implementation-start-date expected-completion-date) 
              (err ERR-INVALID-DATE-RANGE))
    (asserts! (> (len project-name) u0) 
              (err ERR-EMPTY-FIELD))
    (asserts! (> (len geographical-location) u0) 
              (err ERR-EMPTY-FIELD))
    (asserts! (> (len registry-documentation-url) u0) 
              (err ERR-EMPTY-FIELD))
    
    ;; Create Project Registry Entry
    (map-set environmental-project-registry
      { project-identifier: new-project-identifier }
      {
        project-name: project-name,
        detailed-description: detailed-description,
        geographical-location: geographical-location,
        project-owner-principal: tx-sender,
        environmental-category: environmental-category,
        implementation-start-date: implementation-start-date,
        expected-completion-date: expected-completion-date,
        total-verified-credits: u0,
        credits-available-for-sale: u0,
        credits-permanently-retired: u0,
        verification-status-confirmed: false,
        verification-metadata: none,
        current-project-status: "pending-verification",
        registry-documentation-url: registry-documentation-url,
        registration-block-height: block-height
      }
    )
    
    ;; Initialize Verification Sequence Tracking
    (map-set project-verification-sequence-tracking
      { project-identifier: new-project-identifier }
      { next-verification-sequence-number: u0 }
    )
    
    ;; Increment Project Identifier Counter
    (var-set current-project-identifier (+ new-project-identifier u1))
    
    (ok new-project-identifier)
  )
)

;; Authorize Third-Party Verification Entity
(define-public (authorize-third-party-verification-entity
                (verifier-principal principal)
                (organization-name (string-utf8 128))
                (accreditation-credentials (string-utf8 256)))
  (begin
    ;; Administrative Authorization Check
    (asserts! (verify-platform-administrator-privileges) 
              (err ERR-UNAUTHORIZED-ACCESS))
    
    ;; Self-Authorization Prevention
    (asserts! (not (is-eq verifier-principal tx-sender)) 
              (err ERR-SELF-AUTHORIZATION))
    
    ;; Input Validation
    (asserts! (> (len organization-name) u0) 
              (err ERR-EMPTY-FIELD))
    (asserts! (> (len accreditation-credentials) u0) 
              (err ERR-EMPTY-FIELD))
    
    ;; Register Verification Entity
    (map-set authorized-verification-entities
      { verifier-principal: verifier-principal }
      {
        organization-name: organization-name,
        accreditation-credentials: accreditation-credentials,
        authorization-block-height: block-height,
        authorizing-admin-principal: tx-sender,
        verifier-account-status: "active"
      }
    )
    
    (ok true)
  )
)

;; Execute Third-Party Project Verification
(define-public (execute-third-party-project-verification
                (project-identifier uint)
                (verified-credits-quantity uint)
                (verification-report-url (string-utf8 256))
                (applied-methodology-standard (string-ascii 64))
                (monitoring-period-start uint)
                (monitoring-period-end uint)
                (verification-metadata (buff 256)))
  (let
    ((environmental-project-data (unwrap! (map-get? environmental-project-registry { project-identifier: project-identifier }) 
                                          (err ERR-NOT-FOUND)))
     (current-verification-sequence (retrieve-next-verification-sequence-number project-identifier)))
    
    ;; Authorization and Status Validation
    (asserts! (validate-authorized-verification-entity tx-sender) 
              (err ERR-UNAUTHORIZED-ACCESS))
    (asserts! (is-eq (get current-project-status environmental-project-data) "pending-verification") 
              (err ERR-PROJECT-INACTIVE))
    (asserts! (<= monitoring-period-start monitoring-period-end) 
              (err ERR-INVALID-DATE-RANGE))
    (asserts! (> verified-credits-quantity u0) 
              (err ERR-INVALID-INPUT))
    (asserts! (> (len applied-methodology-standard) u0) 
              (err ERR-EMPTY-FIELD))
    
    ;; Record Verification Event
    (map-set third-party-verification-records
      { project-identifier: project-identifier, verification-sequence-number: current-verification-sequence }
      {
        authorized-verifier-principal: tx-sender,
        verification-timestamp: block-height,
        verified-credits-quantity: verified-credits-quantity,
        verification-report-url: verification-report-url,
        applied-methodology-standard: applied-methodology-standard,
        monitoring-period-start: monitoring-period-start,
        monitoring-period-end: monitoring-period-end
      }
    )
    
    ;; Update Project with Verification Results
    (map-set environmental-project-registry
      { project-identifier: project-identifier }
      (merge environmental-project-data 
        { 
          verification-status-confirmed: true, 
          verification-metadata: (some verification-metadata),
          current-project-status: "verified-active",
          total-verified-credits: (+ (get total-verified-credits environmental-project-data) verified-credits-quantity),
          credits-available-for-sale: (+ (get credits-available-for-sale environmental-project-data) verified-credits-quantity)
        }
      )
    )
    
    ;; Update Verification Sequence Counter
    (map-set project-verification-sequence-tracking
      { project-identifier: project-identifier }
      { next-verification-sequence-number: (+ current-verification-sequence u1) }
    )
    
    (ok current-verification-sequence)
  )
)

;; Create Tradeable Credit Batch
(define-public (create-tradeable-credit-batch
                (source-project-identifier uint)
                (credit-vintage-year uint)
                (batch-quantity uint)
                (unit-price-in-ustx uint))
  (let
    ((environmental-project-data (unwrap! (map-get? environmental-project-registry { project-identifier: source-project-identifier }) 
                                          (err ERR-NOT-FOUND)))
     (new-batch-identifier (var-get current-batch-identifier)))
    
    ;; Ownership and Status Validation
    (asserts! (is-eq tx-sender (get project-owner-principal environmental-project-data)) 
              (err ERR-UNAUTHORIZED-ACCESS))
    (asserts! (get verification-status-confirmed environmental-project-data) 
              (err ERR-PROJECT-NOT-VERIFIED))
    (asserts! (is-eq (get current-project-status environmental-project-data) "verified-active") 
              (err ERR-PROJECT-INACTIVE))
    (asserts! (>= (get credits-available-for-sale environmental-project-data) batch-quantity) 
              (err ERR-INSUFFICIENT-CREDITS))
    (asserts! (> batch-quantity u0) 
              (err ERR-INVALID-INPUT))
    (asserts! (> unit-price-in-ustx u0) 
              (err ERR-INVALID-INPUT))
    (asserts! (>= credit-vintage-year minimum-vintage-year) 
              (err ERR-INVALID-VINTAGE-YEAR))
    
    ;; Create Credit Batch Record
    (map-set tradeable-credit-batches
      { batch-identifier: new-batch-identifier }
      {
        source-project-identifier: source-project-identifier,
        credit-vintage-year: credit-vintage-year,
        total-batch-quantity: batch-quantity,
        remaining-available-quantity: batch-quantity,
        unit-price-in-ustx: unit-price-in-ustx,
        batch-creation-timestamp: block-height,
        current-batch-status: "available-for-purchase"
      }
    )
    
    ;; Update Project Available Credits
    (map-set environmental-project-registry
      { project-identifier: source-project-identifier }
      (merge environmental-project-data 
        { credits-available-for-sale: (- (get credits-available-for-sale environmental-project-data) batch-quantity) }
      )
    )
    
    ;; Increment Batch Identifier Counter
    (var-set current-batch-identifier (+ new-batch-identifier u1))
    
    (ok new-batch-identifier)
  )
)

;; Execute Carbon Credit Purchase Transaction
(define-public (execute-carbon-credit-purchase-transaction 
                (batch-identifier uint) 
                (desired-purchase-quantity uint))
  (let
    ((credit-batch-data (unwrap! (map-get? tradeable-credit-batches { batch-identifier: batch-identifier }) 
                                 (err ERR-NOT-FOUND)))
     (environmental-project-data (unwrap! (map-get? environmental-project-registry 
                                                   { project-identifier: (get source-project-identifier credit-batch-data) }) 
                                          (err ERR-NOT-FOUND)))
     (total-transaction-cost (* desired-purchase-quantity (get unit-price-in-ustx credit-batch-data)))
     (buyer-portfolio-key { holder-principal: tx-sender, 
                           credit-vintage-year: (get credit-vintage-year credit-batch-data), 
                           source-project-identifier: (get source-project-identifier credit-batch-data) })
     (current-buyer-balance (default-to { owned-credit-balance: u0 } 
                                        (map-get? user-credit-portfolio buyer-portfolio-key))))
    
    ;; Transaction Validation
    (asserts! (is-eq (get current-batch-status credit-batch-data) "available-for-purchase") 
              (err ERR-BATCH-UNAVAILABLE))
    (asserts! (>= (get remaining-available-quantity credit-batch-data) desired-purchase-quantity) 
              (err ERR-INSUFFICIENT-BALANCE))
    (asserts! (> desired-purchase-quantity u0) 
              (err ERR-INVALID-INPUT))
    
    ;; Execute STX Payment Transaction
    (asserts! (is-ok (stx-transfer? total-transaction-cost tx-sender 
                                   (get project-owner-principal environmental-project-data))) 
              (err ERR-PAYMENT-FAILED))
    
    ;; Update Credit Batch Availability
    (map-set tradeable-credit-batches
      { batch-identifier: batch-identifier }
      (merge credit-batch-data 
        { 
          remaining-available-quantity: (- (get remaining-available-quantity credit-batch-data) desired-purchase-quantity),
          current-batch-status: (if (is-eq (- (get remaining-available-quantity credit-batch-data) desired-purchase-quantity) u0) 
                                   "completely-sold" 
                                   "available-for-purchase")
        }
      )
    )
    
    ;; Update Buyer's Credit Portfolio
    (map-set user-credit-portfolio
      buyer-portfolio-key
      { owned-credit-balance: (+ (get owned-credit-balance current-buyer-balance) desired-purchase-quantity) }
    )
    
    (ok true)
  )
)

;; Execute Permanent Credit Retirement
(define-public (execute-permanent-credit-retirement
                (source-project-identifier uint) 
                (credit-vintage-year uint) 
                (retirement-quantity uint)
                (retirement-justification (string-utf8 256))
                (retirement-beneficiary-principal (optional principal)))
  (let
    ((user-portfolio-key { holder-principal: tx-sender, 
                          credit-vintage-year: credit-vintage-year, 
                          source-project-identifier: source-project-identifier })
     (current-user-balance (unwrap! (map-get? user-credit-portfolio user-portfolio-key) 
                                   (err ERR-NOT-FOUND)))
     (environmental-project-data (unwrap! (map-get? environmental-project-registry 
                                                   { project-identifier: source-project-identifier }) 
                                          (err ERR-NOT-FOUND)))
     (new-retirement-identifier (var-get current-retirement-identifier)))
    
    ;; Retirement Validation
    (asserts! (>= (get owned-credit-balance current-user-balance) retirement-quantity) 
              (err ERR-INSUFFICIENT-BALANCE))
    (asserts! (> retirement-quantity u0) 
              (err ERR-INVALID-INPUT))
    (asserts! (> (len retirement-justification) u0) 
              (err ERR-EMPTY-FIELD))
    
    ;; Beneficiary Self-Assignment Prevention
    (asserts! (match retirement-beneficiary-principal
                beneficiary-address (not (is-eq beneficiary-address tx-sender))
                true) 
              (err ERR-INVALID-INPUT))
    
    ;; Update User's Credit Portfolio
    (map-set user-credit-portfolio
      user-portfolio-key
      { owned-credit-balance: (- (get owned-credit-balance current-user-balance) retirement-quantity) }
    )
    
    ;; Update Project Retirement Statistics
    (map-set environmental-project-registry
      { project-identifier: source-project-identifier }
      (merge environmental-project-data 
        { credits-permanently-retired: (+ (get credits-permanently-retired environmental-project-data) retirement-quantity) }
      )
    )
    
    ;; Record Permanent Retirement Transaction
    (map-set permanent-credit-retirement-log
      { retirement-transaction-id: new-retirement-identifier }
      {
        retiring-user-principal: tx-sender,
        retired-project-identifier: source-project-identifier,
        retired-batch-identifier: u0,
        retired-credits-quantity: retirement-quantity,
        retirement-justification: retirement-justification,
        retirement-beneficiary-principal: retirement-beneficiary-principal,
        retirement-block-timestamp: block-height,
        digital-certificate-url: none
      }
    )
    
    ;; Increment Retirement Identifier Counter
    (var-set current-retirement-identifier (+ new-retirement-identifier u1))
    
    (ok new-retirement-identifier)
  )
)

;; Execute Peer-to-Peer Credit Transfer
(define-public (execute-peer-to-peer-credit-transfer
                (source-project-identifier uint)
                (credit-vintage-year uint)
                (recipient-principal principal)
                (transfer-quantity uint))
  (let
    ((sender-portfolio-key { holder-principal: tx-sender, 
                            credit-vintage-year: credit-vintage-year, 
                            source-project-identifier: source-project-identifier })
     (recipient-portfolio-key { holder-principal: recipient-principal, 
                               credit-vintage-year: credit-vintage-year, 
                               source-project-identifier: source-project-identifier })
     (sender-current-balance (unwrap! (map-get? user-credit-portfolio sender-portfolio-key) 
                                     (err ERR-NOT-FOUND)))
     (recipient-current-balance (default-to { owned-credit-balance: u0 } 
                                           (map-get? user-credit-portfolio recipient-portfolio-key))))
    
    ;; Transfer Validation
    (asserts! (>= (get owned-credit-balance sender-current-balance) transfer-quantity) 
              (err ERR-INSUFFICIENT-BALANCE))
    (asserts! (> transfer-quantity u0) 
              (err ERR-INVALID-INPUT))
    (asserts! (not (is-eq tx-sender recipient-principal))
              (err ERR-INVALID-INPUT))
    
    ;; Update Sender's Portfolio
    (map-set user-credit-portfolio
      sender-portfolio-key
      { owned-credit-balance: (- (get owned-credit-balance sender-current-balance) transfer-quantity) }
    )
    
    ;; Update Recipient's Portfolio
    (map-set user-credit-portfolio
      recipient-portfolio-key
      { owned-credit-balance: (+ (get owned-credit-balance recipient-current-balance) transfer-quantity) }
    )
    
    (ok true)
  )
)

;; Generate Digital Retirement Certificate
(define-public (generate-digital-retirement-certificate
                (retirement-transaction-id uint)
                (digital-certificate-url (string-utf8 256)))
  (let
    ((retirement-record (unwrap! (map-get? permanent-credit-retirement-log 
                                          { retirement-transaction-id: retirement-transaction-id }) 
                                 (err ERR-NOT-FOUND))))
    
    ;; Administrative Authorization Check
    (asserts! (verify-platform-administrator-privileges) 
              (err ERR-UNAUTHORIZED-ACCESS))
    (asserts! (is-none (get digital-certificate-url retirement-record)) 
              (err ERR-CERTIFICATE-EXISTS))
    (asserts! (> (len digital-certificate-url) u0) 
              (err ERR-EMPTY-FIELD))
    
    ;; Update Retirement Record with Certificate
    (map-set permanent-credit-retirement-log
      { retirement-transaction-id: retirement-transaction-id }
      (merge retirement-record { digital-certificate-url: (some digital-certificate-url) })
    )
    
    (ok true)
  )
)

;; READ-ONLY QUERY FUNCTIONS

;; Query Environmental Project Details
(define-read-only (query-environmental-project-details (project-identifier uint))
  (map-get? environmental-project-registry { project-identifier: project-identifier })
)

;; Query Tradeable Credit Batch Details
(define-read-only (query-tradeable-credit-batch-details (batch-identifier uint))
  (map-get? tradeable-credit-batches { batch-identifier: batch-identifier })
)

;; Query User Credit Portfolio Balance
(define-read-only (query-user-credit-portfolio-balance 
                   (holder-principal principal) 
                   (source-project-identifier uint) 
                   (credit-vintage-year uint))
  (default-to 
    { owned-credit-balance: u0 } 
    (map-get? user-credit-portfolio 
              { holder-principal: holder-principal, 
                credit-vintage-year: credit-vintage-year, 
                source-project-identifier: source-project-identifier })
  )
)

;; Query Retirement Transaction Details
(define-read-only (query-retirement-transaction-details (retirement-transaction-id uint))
  (map-get? permanent-credit-retirement-log { retirement-transaction-id: retirement-transaction-id })
)

;; Query Verification Entity Authorization Status
(define-read-only (query-verification-entity-authorization-status (verifier-principal principal))
  (map-get? authorized-verification-entities { verifier-principal: verifier-principal })
)

;; Query Project Verification History
(define-read-only (query-project-verification-history 
                   (project-identifier uint) 
                   (verification-sequence-number uint))
  (map-get? third-party-verification-records 
            { project-identifier: project-identifier, 
              verification-sequence-number: verification-sequence-number })
)

;; Query Supported Environmental Categories
(define-read-only (query-supported-environmental-categories)
  (var-get supported-project-categories)
)

;; Query Platform Statistics
(define-read-only (query-platform-statistics)
  {
    total-registered-projects: (- (var-get current-project-identifier) u1),
    total-credit-batches-created: (- (var-get current-batch-identifier) u1),
    total-retirement-transactions: (- (var-get current-retirement-identifier) u1),
    minimum-supported-vintage-year: minimum-vintage-year
  }
)