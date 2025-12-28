;; Oracle Staking - Reporter Staking Contract
;; Stake STX to become an oracle reporter
;; 
;; Features:
;; - Stake to register as reporter
;; - Slash for malicious behavior
;; - Rewards distribution
;; - Unstaking with cooldown

;; ============================================
;; Constants
;; ============================================

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u1))
(define-constant ERR_INSUFFICIENT_STAKE (err u2))
(define-constant ERR_ALREADY_STAKED (err u3))
(define-constant ERR_NOT_STAKED (err u4))
(define-constant ERR_COOLDOWN_ACTIVE (err u5))
(define-constant ERR_TRANSFER_FAILED (err u6))
(define-constant ERR_SLASHED (err u7))

;; Minimum stake: 10,000 STX
(define-constant MIN_STAKE_AMOUNT u10000000000)

;; Unstaking cooldown: ~7 days (1008 blocks)
(define-constant UNSTAKE_COOLDOWN u1008)

;; Slash percentage: 10% = 1000 basis points
(define-constant SLASH_BASIS_POINTS u1000)
(define-constant BASIS_DENOMINATOR u10000)

;; ============================================
;; Data Variables
;; ============================================

(define-data-var total-staked uint u0)
(define-data-var total-reporters uint u0)
(define-data-var reward-pool uint u0)
(define-data-var treasury principal CONTRACT_OWNER)

;; ============================================
;; Data Maps
;; ============================================

;; Reporter stakes
(define-map stakes
  { reporter: principal }
  {
    amount: uint,
    staked-at: uint,
    rewards-earned: uint,
    is-active: bool,
    slashed: bool,
    submissions-count: uint,
    accuracy-score: uint
  }
)

;; Unstaking requests
(define-map unstake-requests
  { reporter: principal }
  {
    amount: uint,
    requested-at: uint,
    available-at: uint
  }
)

;; ============================================
;; Read-Only Functions
;; ============================================

(define-read-only (get-stake (reporter principal))
  (map-get? stakes { reporter: reporter })
)

(define-read-only (get-staked-amount (reporter principal))
  (match (map-get? stakes { reporter: reporter })
    stake (get amount stake)
    u0
  )
)

(define-read-only (is-active-reporter (reporter principal))
  (match (map-get? stakes { reporter: reporter })
    stake (and (get is-active stake) (not (get slashed stake)))
    false
  )
)

(define-read-only (get-total-staked)
  (var-get total-staked)
)

(define-read-only (get-total-reporters)
  (var-get total-reporters)
)

(define-read-only (get-unstake-request (reporter principal))
  (map-get? unstake-requests { reporter: reporter })
)

(define-read-only (can-unstake (reporter principal))
  (match (map-get? unstake-requests { reporter: reporter })
    request (>= stacks-block-height (get available-at request))
    false
  )
)

(define-read-only (get-min-stake)
  MIN_STAKE_AMOUNT
)

;; ============================================
;; Public Functions
;; ============================================

;; Stake STX to become a reporter
(define-public (stake (amount uint))
  (let (
    (reporter tx-sender)
    (existing-stake (default-to u0 (get-staked-amount reporter)))
    (new-total (+ existing-stake amount))
  )
    ;; Validate minimum stake
    (asserts! (>= new-total MIN_STAKE_AMOUNT) ERR_INSUFFICIENT_STAKE)
    
    ;; Transfer STX to contract
    (try! (stx-transfer? amount reporter (as-contract tx-sender)))
    
    ;; Update or create stake
    (match (map-get? stakes { reporter: reporter })
      existing
      ;; Add to existing stake
      (map-set stakes
        { reporter: reporter }
        (merge existing { amount: new-total })
      )
      ;; Create new stake
      (begin
        (map-set stakes
          { reporter: reporter }
          {
            amount: new-total,
            staked-at: stacks-block-height,
            rewards-earned: u0,
            is-active: true,
            slashed: false,
            submissions-count: u0,
            accuracy-score: u100
          }
        )
        (var-set total-reporters (+ (var-get total-reporters) u1))
      )
    )
    
    ;; Update total staked
    (var-set total-staked (+ (var-get total-staked) amount))
    
    (ok { reporter: reporter, staked: new-total })
  )
)

;; Request unstaking (starts cooldown)
(define-public (request-unstake (amount uint))
  (let (
    (reporter tx-sender)
    (stake-data (unwrap! (map-get? stakes { reporter: reporter }) ERR_NOT_STAKED))
    (current-stake (get amount stake-data))
  )
    ;; Check has enough staked
    (asserts! (>= current-stake amount) ERR_INSUFFICIENT_STAKE)
    ;; Check not slashed
    (asserts! (not (get slashed stake-data)) ERR_SLASHED)
    
    ;; Create unstake request
    (map-set unstake-requests
      { reporter: reporter }
      {
        amount: amount,
        requested-at: stacks-block-height,
        available-at: (+ stacks-block-height UNSTAKE_COOLDOWN)
      }
    )
    
    ;; Deactivate if unstaking all
    (if (is-eq amount current-stake)
      (map-set stakes
        { reporter: reporter }
        (merge stake-data { is-active: false })
      )
      true
    )
    
    (ok { amount: amount, available-at: (+ stacks-block-height UNSTAKE_COOLDOWN) })
  )
)

;; Complete unstaking after cooldown
(define-public (complete-unstake)
  (let (
    (reporter tx-sender)
    (request (unwrap! (map-get? unstake-requests { reporter: reporter }) ERR_NOT_STAKED))
    (stake-data (unwrap! (map-get? stakes { reporter: reporter }) ERR_NOT_STAKED))
    (amount (get amount request))
  )
    ;; Check cooldown passed
    (asserts! (>= stacks-block-height (get available-at request)) ERR_COOLDOWN_ACTIVE)
    
    ;; Transfer STX back to reporter
    (try! (as-contract (stx-transfer? amount tx-sender reporter)))
    
    ;; Update stake
    (map-set stakes
      { reporter: reporter }
      (merge stake-data { amount: (- (get amount stake-data) amount) })
    )
    
    ;; Remove unstake request
    (map-delete unstake-requests { reporter: reporter })
    
    ;; Update totals
    (var-set total-staked (- (var-get total-staked) amount))
    (if (is-eq (- (get amount stake-data) amount) u0)
      (var-set total-reporters (- (var-get total-reporters) u1))
      true
    )
    
    (ok { unstaked: amount, reporter: reporter })
  )
)

;; Record submission (called by oracle-core)
(define-public (record-submission (reporter principal))
  (match (map-get? stakes { reporter: reporter })
    stake-data
    (begin
      (map-set stakes
        { reporter: reporter }
        (merge stake-data {
          submissions-count: (+ (get submissions-count stake-data) u1)
        })
      )
      (ok true)
    )
    ERR_NOT_STAKED
  )
)

;; ============================================
;; Admin Functions
;; ============================================

;; Slash a reporter for malicious behavior
(define-public (slash-reporter (reporter principal) (reason (string-ascii 100)))
  (let (
    (stake-data (unwrap! (map-get? stakes { reporter: reporter }) ERR_NOT_STAKED))
    (slash-amount (/ (* (get amount stake-data) SLASH_BASIS_POINTS) BASIS_DENOMINATOR))
  )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    
    ;; Mark as slashed
    (map-set stakes
      { reporter: reporter }
      (merge stake-data {
        slashed: true,
        is-active: false,
        amount: (- (get amount stake-data) slash-amount)
      })
    )
    
    ;; Add slashed amount to reward pool
    (var-set reward-pool (+ (var-get reward-pool) slash-amount))
    (var-set total-staked (- (var-get total-staked) slash-amount))
    
    (ok { slashed: slash-amount, reporter: reporter })
  )
)

;; Distribute rewards from pool
(define-public (distribute-reward (reporter principal) (amount uint))
  (let (
    (stake-data (unwrap! (map-get? stakes { reporter: reporter }) ERR_NOT_STAKED))
  )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (<= amount (var-get reward-pool)) ERR_INSUFFICIENT_STAKE)
    
    ;; Transfer reward
    (try! (as-contract (stx-transfer? amount tx-sender reporter)))
    
    ;; Update state
    (var-set reward-pool (- (var-get reward-pool) amount))
    (map-set stakes
      { reporter: reporter }
      (merge stake-data {
        rewards-earned: (+ (get rewards-earned stake-data) amount)
      })
    )
    
    (ok amount)
  )
)

;; Add to reward pool
(define-public (fund-reward-pool (amount uint))
  (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set reward-pool (+ (var-get reward-pool) amount))
    (ok (var-get reward-pool))
  )
)

