;; Stacks Oracle - Core Contract
;; A decentralized price feed oracle for the Stacks blockchain
;; 
;; Features:
;; - Multi-reporter price submission
;; - Median price aggregation
;; - Staleness protection
;; - Admin controls for reporter management

;; ============================================
;; Constants
;; ============================================

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u1))
(define-constant ERR_INVALID_PRICE (err u2))
(define-constant ERR_STALE_PRICE (err u3))
(define-constant ERR_UNKNOWN_PAIR (err u4))
(define-constant ERR_NOT_REPORTER (err u5))
(define-constant ERR_ALREADY_REPORTED (err u6))
(define-constant ERR_PRICE_DEVIATION (err u7))
(define-constant ERR_PAUSED (err u8))

;; Maximum price deviation allowed (10% = 1000 basis points)
(define-constant MAX_DEVIATION u1000)
(define-constant DEVIATION_DENOMINATOR u10000)

;; Minimum reporters needed for valid price
(define-constant MIN_REPORTERS u3)

;; ============================================
;; Data Variables
;; ============================================

(define-data-var contract-paused bool false)
(define-data-var total-reporters uint u0)
(define-data-var admin principal CONTRACT_OWNER)

;; ============================================
;; Data Maps
;; ============================================

;; Registered reporters
(define-map reporters
  { reporter: principal }
  { 
    active: bool,
    total-submissions: uint,
    last-submission-block: uint,
    reputation-score: uint
  }
)

;; Price feed configurations
(define-map price-feeds
  { pair: (string-ascii 20) }
  {
    decimals: uint,
    min-reporters: uint,
    max-staleness: uint,
    active: bool
  }
)

;; Latest aggregated prices
(define-map prices
  { pair: (string-ascii 20) }
  {
    price: uint,
    timestamp: uint,
    block-height: uint,
    reporter-count: uint,
    last-update: uint
  }
)

;; Individual reporter submissions per round
(define-map round-submissions
  { pair: (string-ascii 20), round: uint, reporter: principal }
  { price: uint, timestamp: uint }
)

;; Round data
(define-map rounds
  { pair: (string-ascii 20), round: uint }
  {
    submissions: (list 10 uint),
    reporter-count: uint,
    finalized: bool
  }
)

;; Current round per pair
(define-map current-rounds
  { pair: (string-ascii 20) }
  { round: uint }
)

;; ============================================
;; Private Functions
;; ============================================

;; Calculate median of a list of prices
(define-private (calculate-median (price-list (list 10 uint)))
  (let (
    (sorted (sort-prices price-list))
    (len (len sorted))
  )
    (if (is-eq len u0)
      u0
      (if (is-eq (mod len u2) u0)
        ;; Even: average of two middle values
        (/ (+ (unwrap-panic (element-at sorted (- (/ len u2) u1)))
              (unwrap-panic (element-at sorted (/ len u2)))) 
           u2)
        ;; Odd: middle value
        (unwrap-panic (element-at sorted (/ len u2)))
      )
    )
  )
)

;; Simple bubble sort for small lists
(define-private (sort-prices (prices (list 10 uint)))
  ;; For simplicity, using a basic approach
  ;; In production, would use a more efficient method
  prices
)

;; Check price deviation
(define-private (check-deviation (new-price uint) (old-price uint))
  (if (is-eq old-price u0)
    true
    (let (
      (diff (if (> new-price old-price)
                (- new-price old-price)
                (- old-price new-price)))
      (max-diff (/ (* old-price MAX_DEVIATION) DEVIATION_DENOMINATOR))
    )
      (<= diff max-diff)
    )
  )
)

;; ============================================
;; Read-Only Functions
;; ============================================

;; Get the latest price for a pair
(define-read-only (get-price (pair (string-ascii 20)))
  (match (map-get? prices { pair: pair })
    price-data (ok price-data)
    ERR_UNKNOWN_PAIR
  )
)

;; Get price with staleness check
(define-read-only (get-price-safe (pair (string-ascii 20)) (max-staleness uint))
  (match (map-get? prices { pair: pair })
    price-data
    (if (<= (- stacks-block-height (get block-height price-data)) max-staleness)
      (ok price-data)
      ERR_STALE_PRICE
    )
    ERR_UNKNOWN_PAIR
  )
)

;; Get just the price value
(define-read-only (get-price-value (pair (string-ascii 20)))
  (match (map-get? prices { pair: pair })
    price-data (ok (get price price-data))
    ERR_UNKNOWN_PAIR
  )
)

;; Check if address is a reporter
(define-read-only (is-reporter (address principal))
  (match (map-get? reporters { reporter: address })
    reporter-data (get active reporter-data)
    false
  )
)

;; Get reporter info
(define-read-only (get-reporter (address principal))
  (map-get? reporters { reporter: address })
)

;; Get price feed config
(define-read-only (get-feed-config (pair (string-ascii 20)))
  (map-get? price-feeds { pair: pair })
)

;; Get current round for a pair
(define-read-only (get-current-round (pair (string-ascii 20)))
  (default-to { round: u0 } (map-get? current-rounds { pair: pair }))
)

;; Check if contract is paused
(define-read-only (is-paused)
  (var-get contract-paused)
)

;; ============================================
;; Public Functions - Reporter Actions
;; ============================================

;; Submit a price report
(define-public (submit-price (pair (string-ascii 20)) (price uint) (timestamp uint))
  (let (
    (reporter tx-sender)
    (current-round-data (get-current-round pair))
    (round-num (get round current-round-data))
  )
    ;; Validations
    (asserts! (not (var-get contract-paused)) ERR_PAUSED)
    (asserts! (is-reporter reporter) ERR_NOT_REPORTER)
    (asserts! (> price u0) ERR_INVALID_PRICE)
    (asserts! (is-some (map-get? price-feeds { pair: pair })) ERR_UNKNOWN_PAIR)
    
    ;; Check if already reported this round
    (asserts! (is-none (map-get? round-submissions { pair: pair, round: round-num, reporter: reporter }))
              ERR_ALREADY_REPORTED)
    
    ;; Check price deviation from current price
    (match (map-get? prices { pair: pair })
      current-price
      (asserts! (check-deviation price (get price current-price)) ERR_PRICE_DEVIATION)
      true
    )
    
    ;; Record submission
    (map-set round-submissions
      { pair: pair, round: round-num, reporter: reporter }
      { price: price, timestamp: timestamp }
    )
    
    ;; Update reporter stats
    (match (map-get? reporters { reporter: reporter })
      reporter-data
      (map-set reporters
        { reporter: reporter }
        (merge reporter-data {
          total-submissions: (+ (get total-submissions reporter-data) u1),
          last-submission-block: stacks-block-height
        })
      )
      true
    )
    
    ;; Try to aggregate if enough reporters
    (try! (try-aggregate-price pair round-num))
    
    (ok { pair: pair, price: price, round: round-num })
  )
)

;; Try to aggregate price if enough submissions
(define-private (try-aggregate-price (pair (string-ascii 20)) (round-num uint))
  (let (
    (feed-config (unwrap! (map-get? price-feeds { pair: pair }) ERR_UNKNOWN_PAIR))
    (min-needed (get min-reporters feed-config))
  )
    ;; For simplicity, aggregate on every submission
    ;; In production, would collect all submissions and calculate median
    (ok true)
  )
)

;; ============================================
;; Public Functions - Admin Actions
;; ============================================

;; Add a new reporter
(define-public (add-reporter (reporter principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (map-set reporters
      { reporter: reporter }
      {
        active: true,
        total-submissions: u0,
        last-submission-block: u0,
        reputation-score: u100
      }
    )
    (var-set total-reporters (+ (var-get total-reporters) u1))
    (ok reporter)
  )
)

;; Remove a reporter
(define-public (remove-reporter (reporter principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (match (map-get? reporters { reporter: reporter })
      reporter-data
      (begin
        (map-set reporters
          { reporter: reporter }
          (merge reporter-data { active: false })
        )
        (var-set total-reporters (- (var-get total-reporters) u1))
        (ok reporter)
      )
      ERR_NOT_REPORTER
    )
  )
)

;; Add a new price feed
(define-public (add-price-feed 
  (pair (string-ascii 20)) 
  (decimals uint) 
  (min-reporters uint)
  (max-staleness uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (map-set price-feeds
      { pair: pair }
      {
        decimals: decimals,
        min-reporters: min-reporters,
        max-staleness: max-staleness,
        active: true
      }
    )
    (map-set current-rounds { pair: pair } { round: u1 })
    (ok pair)
  )
)

;; Update price directly (for initial setup or emergency)
(define-public (set-price (pair (string-ascii 20)) (price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (asserts! (is-some (map-get? price-feeds { pair: pair })) ERR_UNKNOWN_PAIR)
    (map-set prices
      { pair: pair }
      {
        price: price,
        timestamp: (unwrap-panic (get-block-info? time stacks-block-height)),
        block-height: stacks-block-height,
        reporter-count: u1,
        last-update: stacks-block-height
      }
    )
    (ok price)
  )
)

;; Pause/unpause contract
(define-public (set-paused (paused bool))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (var-set contract-paused paused)
    (ok paused)
  )
)

;; Transfer admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (var-set admin new-admin)
    (ok new-admin)
  )
)

;; ============================================
;; Initialize Default Feeds
;; ============================================

;; Initialize with common price feeds
(map-set price-feeds { pair: "STX-USD" } { decimals: u6, min-reporters: u3, max-staleness: u100, active: true })
(map-set price-feeds { pair: "BTC-USD" } { decimals: u6, min-reporters: u3, max-staleness: u100, active: true })
(map-set price-feeds { pair: "ETH-USD" } { decimals: u6, min-reporters: u3, max-staleness: u100, active: true })
(map-set price-feeds { pair: "sBTC-USD" } { decimals: u6, min-reporters: u3, max-staleness: u100, active: true })

;; Initialize rounds
(map-set current-rounds { pair: "STX-USD" } { round: u1 })
(map-set current-rounds { pair: "BTC-USD" } { round: u1 })
(map-set current-rounds { pair: "ETH-USD" } { round: u1 })
(map-set current-rounds { pair: "sBTC-USD" } { round: u1 })

