;; Oracle Consumer - Example Contract
;; Demonstrates how to integrate with Stacks Oracle
;; 
;; Use cases:
;; - Lending protocol collateral valuation
;; - DEX price reference
;; - Liquidation triggers

;; ============================================
;; Constants
;; ============================================

(define-constant ERR_PRICE_UNAVAILABLE (err u100))
(define-constant ERR_STALE_PRICE (err u101))
(define-constant ERR_INVALID_AMOUNT (err u102))

;; Maximum acceptable staleness (blocks)
(define-constant MAX_PRICE_STALENESS u50)

;; ============================================
;; Oracle Integration Functions
;; ============================================

;; Get STX price in USD (6 decimals)
(define-read-only (get-stx-price)
  (contract-call? .oracle-core get-price "STX-USD")
)

;; Get BTC price in USD (6 decimals)
(define-read-only (get-btc-price)
  (contract-call? .oracle-core get-price "BTC-USD")
)

;; Get price with staleness check
(define-read-only (get-stx-price-safe)
  (contract-call? .oracle-core get-price-safe "STX-USD" MAX_PRICE_STALENESS)
)

;; ============================================
;; Example Use Cases
;; ============================================

;; Calculate USD value of STX amount
;; Input: amount in micro-STX (6 decimals)
;; Output: USD value (6 decimals)
(define-read-only (get-stx-usd-value (amount uint))
  (match (contract-call? .oracle-core get-price "STX-USD")
    price-data
    (ok (/ (* amount (get price price-data)) u1000000))
    error
    error
  )
)

;; Calculate how much STX for a given USD amount
;; Input: usd-amount (6 decimals)
;; Output: STX amount (6 decimals)
(define-read-only (get-stx-for-usd (usd-amount uint))
  (match (contract-call? .oracle-core get-price "STX-USD")
    price-data
    (let ((price (get price price-data)))
      (if (> price u0)
        (ok (/ (* usd-amount u1000000) price))
        ERR_PRICE_UNAVAILABLE
      )
    )
    error
    error
  )
)

;; ============================================
;; Lending Protocol Example
;; ============================================

;; Collateral ratio constants
(define-constant COLLATERAL_RATIO u150) ;; 150%
(define-constant LIQUIDATION_RATIO u120) ;; 120%
(define-constant RATIO_DENOMINATOR u100)

;; Calculate maximum borrowable amount based on collateral
;; collateral-stx: Amount of STX as collateral (6 decimals)
;; Returns: Maximum USD that can be borrowed (6 decimals)
(define-read-only (calculate-max-borrow (collateral-stx uint))
  (match (contract-call? .oracle-core get-price-safe "STX-USD" MAX_PRICE_STALENESS)
    price-data
    (let (
      (collateral-usd (/ (* collateral-stx (get price price-data)) u1000000))
      (max-borrow (/ (* collateral-usd RATIO_DENOMINATOR) COLLATERAL_RATIO))
    )
      (ok max-borrow)
    )
    error
    error
  )
)

;; Check if a position should be liquidated
;; collateral-stx: Current collateral (6 decimals)
;; debt-usd: Current debt (6 decimals)
;; Returns: true if should be liquidated
(define-read-only (should-liquidate (collateral-stx uint) (debt-usd uint))
  (match (contract-call? .oracle-core get-price-safe "STX-USD" MAX_PRICE_STALENESS)
    price-data
    (let (
      (collateral-usd (/ (* collateral-stx (get price price-data)) u1000000))
      (current-ratio (if (> debt-usd u0) 
                        (/ (* collateral-usd u100) debt-usd)
                        u999999))
    )
      (ok (< current-ratio LIQUIDATION_RATIO))
    )
    error
    (ok false) ;; If price unavailable, don't liquidate
  )
)

;; ============================================
;; DEX Price Reference Example
;; ============================================

;; Check if a swap price is within acceptable range of oracle price
;; swap-price: The price offered by the DEX (6 decimals)
;; max-slippage: Maximum acceptable slippage in basis points (e.g., 100 = 1%)
(define-read-only (is-price-acceptable 
  (pair (string-ascii 20))
  (swap-price uint) 
  (max-slippage uint))
  (match (contract-call? .oracle-core get-price pair)
    price-data
    (let (
      (oracle-price (get price price-data))
      (diff (if (> swap-price oracle-price)
                (- swap-price oracle-price)
                (- oracle-price swap-price)))
      (max-diff (/ (* oracle-price max-slippage) u10000))
    )
      (ok (<= diff max-diff))
    )
    error
    (ok true) ;; If no oracle price, accept any price
  )
)

;; ============================================
;; Price History (Simplified)
;; ============================================

(define-map price-snapshots
  { pair: (string-ascii 20), block: uint }
  { price: uint, timestamp: uint }
)

;; Store current price as snapshot
(define-public (snapshot-price (pair (string-ascii 20)))
  (match (contract-call? .oracle-core get-price pair)
    price-data
    (begin
      (map-set price-snapshots
        { pair: pair, block: stacks-block-height }
        { price: (get price price-data), timestamp: (get timestamp price-data) }
      )
      (ok stacks-block-height)
    )
    error
    error
  )
)

;; Get historical price at a specific block
(define-read-only (get-price-at-block (pair (string-ascii 20)) (block uint))
  (map-get? price-snapshots { pair: pair, block: block })
)

;; ============================================
;; TWAP (Time-Weighted Average Price) Helper
;; ============================================

;; Calculate simple average of two prices
(define-read-only (calculate-average-price (price1 uint) (price2 uint))
  (/ (+ price1 price2) u2)
)

;; Check price movement percentage
;; Returns the percentage change (in basis points) between two prices
(define-read-only (calculate-price-change (old-price uint) (new-price uint))
  (if (is-eq old-price u0)
    u0
    (let (
      (diff (if (> new-price old-price)
                (- new-price old-price)
                (- old-price new-price)))
    )
      (/ (* diff u10000) old-price)
    )
  )
)

