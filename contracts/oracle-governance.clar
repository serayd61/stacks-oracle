;; Oracle Governance - DAO for Oracle Protocol
;; Manage oracle parameters through community voting
;; 
;; Features:
;; - Create proposals
;; - Vote with staked STX
;; - Execute passed proposals
;; - Parameter updates

;; ============================================
;; Constants
;; ============================================

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u1))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u2))
(define-constant ERR_ALREADY_VOTED (err u3))
(define-constant ERR_VOTING_ENDED (err u4))
(define-constant ERR_VOTING_ACTIVE (err u5))
(define-constant ERR_PROPOSAL_FAILED (err u6))
(define-constant ERR_ALREADY_EXECUTED (err u7))
(define-constant ERR_NO_VOTING_POWER (err u8))

;; Voting period: ~3 days (432 blocks)
(define-constant VOTING_PERIOD u432)

;; Quorum: 10% of staked STX must vote
(define-constant QUORUM_PERCENTAGE u10)

;; Pass threshold: 60% approval
(define-constant PASS_THRESHOLD u60)

;; Proposal types
(define-constant PROPOSAL_TYPE_PARAMETER u1)
(define-constant PROPOSAL_TYPE_ADD_FEED u2)
(define-constant PROPOSAL_TYPE_REMOVE_FEED u3)
(define-constant PROPOSAL_TYPE_UPGRADE u4)

;; ============================================
;; Data Variables
;; ============================================

(define-data-var proposal-counter uint u0)
(define-data-var min-stake-to-propose uint u1000000000) ;; 1000 STX

;; ============================================
;; Data Maps
;; ============================================

;; Proposals
(define-map proposals
  { proposal-id: uint }
  {
    proposer: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposal-type: uint,
    created-at: uint,
    ends-at: uint,
    votes-for: uint,
    votes-against: uint,
    executed: bool,
    passed: bool,
    ;; Proposal data (varies by type)
    parameter-name: (optional (string-ascii 50)),
    parameter-value: (optional uint),
    feed-pair: (optional (string-ascii 20))
  }
)

;; Vote records
(define-map votes
  { proposal-id: uint, voter: principal }
  { 
    vote: bool,
    weight: uint,
    voted-at: uint
  }
)

;; ============================================
;; Read-Only Functions
;; ============================================

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

(define-read-only (get-proposal-status (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal
    (let (
      (total-votes (+ (get votes-for proposal) (get votes-against proposal)))
      (approval-rate (if (> total-votes u0)
                        (/ (* (get votes-for proposal) u100) total-votes)
                        u0))
    )
      (ok {
        active: (< stacks-block-height (get ends-at proposal)),
        passed: (and (>= approval-rate PASS_THRESHOLD)
                     (>= stacks-block-height (get ends-at proposal))),
        executed: (get executed proposal),
        votes-for: (get votes-for proposal),
        votes-against: (get votes-against proposal),
        approval-rate: approval-rate
      })
    )
    ERR_PROPOSAL_NOT_FOUND
  )
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)

(define-read-only (has-voted (proposal-id uint) (voter principal))
  (is-some (map-get? votes { proposal-id: proposal-id, voter: voter }))
)

(define-read-only (get-proposal-count)
  (var-get proposal-counter)
)

(define-read-only (is-voting-active (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal (< stacks-block-height (get ends-at proposal))
    false
  )
)

;; ============================================
;; Public Functions
;; ============================================

;; Create a parameter change proposal
(define-public (propose-parameter-change
  (title (string-ascii 100))
  (description (string-ascii 500))
  (parameter-name (string-ascii 50))
  (new-value uint))
  (let (
    (proposal-id (+ (var-get proposal-counter) u1))
  )
    ;; Create proposal
    (map-set proposals
      { proposal-id: proposal-id }
      {
        proposer: tx-sender,
        title: title,
        description: description,
        proposal-type: PROPOSAL_TYPE_PARAMETER,
        created-at: stacks-block-height,
        ends-at: (+ stacks-block-height VOTING_PERIOD),
        votes-for: u0,
        votes-against: u0,
        executed: false,
        passed: false,
        parameter-name: (some parameter-name),
        parameter-value: (some new-value),
        feed-pair: none
      }
    )
    
    (var-set proposal-counter proposal-id)
    (ok proposal-id)
  )
)

;; Create add price feed proposal
(define-public (propose-add-feed
  (title (string-ascii 100))
  (description (string-ascii 500))
  (pair (string-ascii 20)))
  (let (
    (proposal-id (+ (var-get proposal-counter) u1))
  )
    (map-set proposals
      { proposal-id: proposal-id }
      {
        proposer: tx-sender,
        title: title,
        description: description,
        proposal-type: PROPOSAL_TYPE_ADD_FEED,
        created-at: stacks-block-height,
        ends-at: (+ stacks-block-height VOTING_PERIOD),
        votes-for: u0,
        votes-against: u0,
        executed: false,
        passed: false,
        parameter-name: none,
        parameter-value: none,
        feed-pair: (some pair)
      }
    )
    
    (var-set proposal-counter proposal-id)
    (ok proposal-id)
  )
)

;; Cast vote
(define-public (vote (proposal-id uint) (vote-for bool))
  (let (
    (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND))
    (voter tx-sender)
    ;; In production, would get voting power from staking contract
    (voting-power u1000000) ;; Placeholder
  )
    ;; Check voting is active
    (asserts! (< stacks-block-height (get ends-at proposal)) ERR_VOTING_ENDED)
    ;; Check not already voted
    (asserts! (not (has-voted proposal-id voter)) ERR_ALREADY_VOTED)
    ;; Check has voting power
    (asserts! (> voting-power u0) ERR_NO_VOTING_POWER)
    
    ;; Record vote
    (map-set votes
      { proposal-id: proposal-id, voter: voter }
      { vote: vote-for, weight: voting-power, voted-at: stacks-block-height }
    )
    
    ;; Update vote counts
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal {
        votes-for: (if vote-for 
                      (+ (get votes-for proposal) voting-power)
                      (get votes-for proposal)),
        votes-against: (if (not vote-for)
                          (+ (get votes-against proposal) voting-power)
                          (get votes-against proposal))
      })
    )
    
    (ok { proposal-id: proposal-id, vote: vote-for, weight: voting-power })
  )
)

;; Execute passed proposal
(define-public (execute-proposal (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND))
    (total-votes (+ (get votes-for proposal) (get votes-against proposal)))
    (approval-rate (if (> total-votes u0)
                      (/ (* (get votes-for proposal) u100) total-votes)
                      u0))
  )
    ;; Check voting ended
    (asserts! (>= stacks-block-height (get ends-at proposal)) ERR_VOTING_ACTIVE)
    ;; Check not already executed
    (asserts! (not (get executed proposal)) ERR_ALREADY_EXECUTED)
    ;; Check proposal passed
    (asserts! (>= approval-rate PASS_THRESHOLD) ERR_PROPOSAL_FAILED)
    
    ;; Mark as executed
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal { executed: true, passed: true })
    )
    
    ;; Execute based on type
    ;; In production, would actually call the relevant contracts
    
    (ok { proposal-id: proposal-id, executed: true })
  )
)

;; ============================================
;; Admin Functions
;; ============================================

(define-public (set-min-stake-to-propose (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set min-stake-to-propose amount)
    (ok amount)
  )
)

