;; Prevention Planning Contract
;; Implements proactive pest deterrent strategies

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u300))
(define-constant ERR-INVALID-STRATEGY (err u301))
(define-constant ERR-INSUFFICIENT-FUNDS (err u302))
(define-constant ERR-PLAN-NOT-FOUND (err u303))
(define-constant ERR-PLAN-ACTIVE (err u304))

;; Data Variables
(define-data-var plan-counter uint u0)
(define-data-var seasonal-multiplier uint u100) ;; Base 100%

;; Data Maps
(define-map prevention-plans
  { plan-id: uint }
  {
    owner: principal,
    area-id: uint,
    strategy-type: (string-ascii 50),
    implementation-date: uint,
    duration-days: uint,
    cost: uint,
    status: (string-ascii 20),
    effectiveness-score: uint,
    renewal-count: uint
  }
)

(define-map prevention-strategies
  { strategy-name: (string-ascii 50) }
  {
    category: (string-ascii 30),
    effectiveness-rating: uint,
    cost-per-day: uint,
    seasonal-bonus: uint,
    eco-friendly: bool,
    approved: bool
  }
)

(define-map area-prevention-status
  { area-id: uint }
  {
    active-plans: uint,
    total-investment: uint,
    prevention-score: uint,
    last-updated: uint,
    recommended-strategies: (list 3 (string-ascii 50))
  }
)

(define-map seasonal-recommendations
  { season: (string-ascii 20) }
  {
    priority-strategies: (list 5 (string-ascii 50)),
    effectiveness-multiplier: uint,
    recommended-duration: uint
  }
)

(define-map user-prevention-history
  { user: principal }
  {
    total-plans: uint,
    successful-plans: uint,
    total-investment: uint,
    prevention-expertise: uint
  }
)

;; Token balances
(define-map token-balances
  { owner: principal }
  { balance: uint }
)

;; Public Functions

;; Create prevention plan
(define-public (create-prevention-plan (area-id uint) (strategy-type (string-ascii 50)) (duration-days uint))
  (let
    (
      (plan-id (+ (var-get plan-counter) u1))
      (strategy-info (unwrap! (map-get? prevention-strategies { strategy-name: strategy-type }) ERR-INVALID-STRATEGY))
      (total-cost (* (get cost-per-day strategy-info) duration-days))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (user-balance (get-token-balance tx-sender))
    )
    (asserts! (get approved strategy-info) ERR-INVALID-STRATEGY)
    (asserts! (>= user-balance total-cost) ERR-INSUFFICIENT-FUNDS)
    (asserts! (> duration-days u0) ERR-INVALID-STRATEGY)

    ;; Create prevention plan
    (map-set prevention-plans
      { plan-id: plan-id }
      {
        owner: tx-sender,
        area-id: area-id,
        strategy-type: strategy-type,
        implementation-date: current-time,
        duration-days: duration-days,
        cost: total-cost,
        status: "active",
        effectiveness-score: u0,
        renewal-count: u0
      }
    )

    ;; Deduct payment
    (unwrap-panic (deduct-tokens tx-sender total-cost))

    ;; Update area prevention status
    (unwrap-panic (update-area-prevention-status area-id total-cost))

    ;; Update user history
    (unwrap-panic (update-user-prevention-history tx-sender total-cost))

    ;; Increment counter
    (var-set plan-counter plan-id)

    (ok plan-id)
  )
)

;; Renew prevention plan
(define-public (renew-prevention-plan (plan-id uint) (additional-days uint))
  (let
    (
      (plan (unwrap! (map-get? prevention-plans { plan-id: plan-id }) ERR-PLAN-NOT-FOUND))
      (strategy-info (unwrap-panic (map-get? prevention-strategies { strategy-name: (get strategy-type plan) })))
      (additional-cost (* (get cost-per-day strategy-info) additional-days))
      (user-balance (get-token-balance tx-sender))
    )
    (asserts! (is-eq tx-sender (get owner plan)) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status plan) "active") ERR-PLAN-ACTIVE)
    (asserts! (>= user-balance additional-cost) ERR-INSUFFICIENT-FUNDS)

    ;; Update plan with renewal
    (map-set prevention-plans
      { plan-id: plan-id }
      (merge plan
        {
          duration-days: (+ (get duration-days plan) additional-days),
          cost: (+ (get cost plan) additional-cost),
          renewal-count: (+ (get renewal-count plan) u1)
        }
      )
    )

    ;; Deduct payment
    (unwrap-panic (deduct-tokens tx-sender additional-cost))

    (ok true)
  )
)

;; Complete prevention plan and rate effectiveness
(define-public (complete-prevention-plan (plan-id uint) (effectiveness-score uint))
  (let
    (
      (plan (unwrap! (map-get? prevention-plans { plan-id: plan-id }) ERR-PLAN-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get owner plan)) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status plan) "active") ERR-PLAN-ACTIVE)
    (asserts! (and (>= effectiveness-score u1) (<= effectiveness-score u10)) ERR-INVALID-STRATEGY)

    ;; Update plan status
    (map-set prevention-plans
      { plan-id: plan-id }
      (merge plan
        {
          status: "completed",
          effectiveness-score: effectiveness-score
        }
      )
    )

    ;; Update user expertise based on effectiveness
    (unwrap-panic (update-user-expertise tx-sender effectiveness-score))

    ;; Calculate and distribute effectiveness bonus
    (if (>= effectiveness-score u8)
      (add-tokens tx-sender (/ (get cost plan) u10))
      (ok u0)
    )
  )
)

;; Add new prevention strategy
(define-public (add-prevention-strategy (strategy-name (string-ascii 50)) (category (string-ascii 30)) (effectiveness-rating uint) (cost-per-day uint) (eco-friendly bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (and (>= effectiveness-rating u1) (<= effectiveness-rating u10)) ERR-INVALID-STRATEGY)

    (map-set prevention-strategies
      { strategy-name: strategy-name }
      {
        category: category,
        effectiveness-rating: effectiveness-rating,
        cost-per-day: cost-per-day,
        seasonal-bonus: u0,
        eco-friendly: eco-friendly,
        approved: true
      }
    )

    (ok true)
  )
)

;; Set seasonal recommendations
(define-public (set-seasonal-recommendations (season (string-ascii 20)) (strategies (list 5 (string-ascii 50))) (multiplier uint) (duration uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)

    (map-set seasonal-recommendations
      { season: season }
      {
        priority-strategies: strategies,
        effectiveness-multiplier: multiplier,
        recommended-duration: duration
      }
    )

    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-prevention-plan (plan-id uint))
  (map-get? prevention-plans { plan-id: plan-id })
)

(define-read-only (get-prevention-strategy (strategy-name (string-ascii 50)))
  (map-get? prevention-strategies { strategy-name: strategy-name })
)

(define-read-only (get-area-prevention-status (area-id uint))
  (map-get? area-prevention-status { area-id: area-id })
)

(define-read-only (get-seasonal-recommendations (season (string-ascii 20)))
  (map-get? seasonal-recommendations { season: season })
)

(define-read-only (get-user-prevention-history (user principal))
  (map-get? user-prevention-history { user: user })
)

(define-read-only (get-plan-counter)
  (var-get plan-counter)
)

(define-read-only (get-token-balance (owner principal))
  (default-to u0 (get balance (map-get? token-balances { owner: owner })))
)

;; Calculate prevention effectiveness for area
(define-read-only (calculate-area-prevention-score (area-id uint))
  (let
    (
      (area-status (map-get? area-prevention-status { area-id: area-id }))
    )
    (match area-status
      status (get prevention-score status)
      u0
    )
  )
)

;; Private Functions

;; Update area prevention status
(define-private (update-area-prevention-status (area-id uint) (investment uint))
  (let
    (
      (current-status (default-to
        { active-plans: u0, total-investment: u0, prevention-score: u0, last-updated: u0, recommended-strategies: (list) }
        (map-get? area-prevention-status { area-id: area-id })
      ))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (new-score (+ (get prevention-score current-status) (/ investment u100)))
    )
    (map-set area-prevention-status
      { area-id: area-id }
      {
        active-plans: (+ (get active-plans current-status) u1),
        total-investment: (+ (get total-investment current-status) investment),
        prevention-score: new-score,
        last-updated: current-time,
        recommended-strategies: (get recommended-strategies current-status)
      }
    )
    (ok true)
  )
)

;; Update user prevention history
(define-private (update-user-prevention-history (user principal) (investment uint))
  (let
    (
      (current-history (default-to
        { total-plans: u0, successful-plans: u0, total-investment: u0, prevention-expertise: u0 }
        (map-get? user-prevention-history { user: user })
      ))
    )
    (map-set user-prevention-history
      { user: user }
      (merge current-history
        {
          total-plans: (+ (get total-plans current-history) u1),
          total-investment: (+ (get total-investment current-history) investment)
        }
      )
    )
    (ok true)
  )
)

;; Update user expertise based on plan effectiveness
(define-private (update-user-expertise (user principal) (effectiveness uint))
  (let
    (
      (current-history (unwrap-panic (map-get? user-prevention-history { user: user })))
      (expertise-gain (if (>= effectiveness u7) u10 u5))
    )
    (map-set user-prevention-history
      { user: user }
      (merge current-history
        {
          successful-plans: (+ (get successful-plans current-history) u1),
          prevention-expertise: (+ (get prevention-expertise current-history) expertise-gain)
        }
      )
    )
    (ok true)
  )
)

;; Token management functions
(define-private (add-tokens (recipient principal) (amount uint))
  (let
    (
      (current-balance (get-token-balance recipient))
    )
    (map-set token-balances
      { owner: recipient }
      { balance: (+ current-balance amount) }
    )
    (ok amount)
  )
)

(define-private (deduct-tokens (payer principal) (amount uint))
  (let
    (
      (current-balance (get-token-balance payer))
    )
    (asserts! (>= current-balance amount) ERR-INSUFFICIENT-FUNDS)
    (map-set token-balances
      { owner: payer }
      { balance: (- current-balance amount) }
    )
    (ok amount)
  )
)
