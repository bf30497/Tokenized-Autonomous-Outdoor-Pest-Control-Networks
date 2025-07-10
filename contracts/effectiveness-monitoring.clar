;; Effectiveness Monitoring Contract
;; Tracks pest control success and adjustment needs

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u500))
(define-constant ERR-INVALID-RATING (err u501))
(define-constant ERR-MONITORING-NOT-FOUND (err u502))
(define-constant ERR-INSUFFICIENT-DATA (err u503))
(define-constant ERR-INVALID-TIMEFRAME (err u504))

;; Data Variables
(define-data-var monitoring-counter uint u0)
(define-data-var effectiveness-threshold uint u7) ;; Minimum effectiveness for success

;; Data Maps
(define-map effectiveness-reports
  { report-id: uint }
  {
    reporter: principal,
    area-id: uint,
    treatment-type: (string-ascii 50),
    pre-treatment-level: uint,
    post-treatment-level: uint,
    effectiveness-score: uint,
    measurement-date: uint,
    follow-up-needed: bool,
    verified: bool
  }
)

(define-map area-effectiveness-trends
  { area-id: uint }
  {
    total-treatments: uint,
    successful-treatments: uint,
    average-effectiveness: uint,
    trend-direction: (string-ascii 20),
    last-updated: uint,
    recommended-adjustments: (list 3 (string-ascii 100))
  }
)

(define-map treatment-effectiveness-stats
  { treatment-type: (string-ascii 50) }
  {
    total-applications: uint,
    success-rate: uint,
    average-effectiveness: uint,
    best-conditions: (string-ascii 100),
    improvement-suggestions: (list 3 (string-ascii 100))
  }
)

(define-map monitoring-schedules
  { schedule-id: uint }
  {
    area-id: uint,
    frequency-days: uint,
    next-monitoring-date: uint,
    assigned-monitor: principal,
    active: bool,
    monitoring-type: (string-ascii 50)
  }
)

(define-map effectiveness-benchmarks
  { benchmark-name: (string-ascii 50) }
  {
    target-effectiveness: uint,
    measurement-criteria: (string-ascii 100),
    reward-amount: uint,
    penalty-amount: uint
  }
)

(define-map monitor-performance
  { monitor: principal }
  {
    reports-submitted: uint,
    accuracy-rating: uint,
    total-rewards: uint,
    specialization: (string-ascii 50)
  }
)

;; Token balances for rewards and penalties
(define-map token-balances
  { owner: principal }
  { balance: uint }
)

;; Public Functions

;; Submit effectiveness report
(define-public (submit-effectiveness-report (area-id uint) (treatment-type (string-ascii 50)) (pre-level uint) (post-level uint) (measurement-date uint))
  (let
    (
      (report-id (+ (var-get monitoring-counter) u1))
      (effectiveness-score (calculate-effectiveness pre-level post-level))
    )
    (asserts! (and (>= pre-level u1) (<= pre-level u10)) ERR-INVALID-RATING)
    (asserts! (and (>= post-level u0) (<= post-level u10)) ERR-INVALID-RATING)
    (asserts! (> measurement-date u0) ERR-INVALID-TIMEFRAME)

    ;; Create effectiveness report
    (map-set effectiveness-reports
      { report-id: report-id }
      {
        reporter: tx-sender,
        area-id: area-id,
        treatment-type: treatment-type,
        pre-treatment-level: pre-level,
        post-treatment-level: post-level,
        effectiveness-score: effectiveness-score,
        measurement-date: measurement-date,
        follow-up-needed: (< effectiveness-score (var-get effectiveness-threshold)),
        verified: false
      }
    )

    ;; Update area trends
    (unwrap-panic (update-area-effectiveness-trends area-id effectiveness-score))

    ;; Update treatment statistics
    (unwrap-panic (update-treatment-stats treatment-type effectiveness-score))

    ;; Update monitor performance
    (unwrap-panic (update-monitor-performance tx-sender))

    ;; Increment counter
    (var-set monitoring-counter report-id)

    ;; Reward for reporting
    (unwrap-panic (add-tokens tx-sender u50))

    (ok report-id)
  )
)

;; Verify effectiveness report
(define-public (verify-report (report-id uint) (is-accurate bool))
  (let
    (
      (report (unwrap! (map-get? effectiveness-reports { report-id: report-id }) ERR-MONITORING-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)

    ;; Update report verification status
    (map-set effectiveness-reports
      { report-id: report-id }
      (merge report { verified: is-accurate })
    )

    ;; Reward or penalize reporter based on accuracy
    (if is-accurate
      (add-tokens (get reporter report) u100)
      (deduct-tokens (get reporter report) u25)
    )
  )
)

;; Schedule monitoring for area
(define-public (schedule-monitoring (area-id uint) (frequency-days uint) (monitoring-type (string-ascii 50)))
  (let
    (
      (schedule-id (+ (var-get monitoring-counter) u1))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (next-monitoring (+ current-time (* frequency-days u86400)))
    )
    (asserts! (> frequency-days u0) ERR-INVALID-TIMEFRAME)

    ;; Create monitoring schedule
    (map-set monitoring-schedules
      { schedule-id: schedule-id }
      {
        area-id: area-id,
        frequency-days: frequency-days,
        next-monitoring-date: next-monitoring,
        assigned-monitor: tx-sender,
        active: true,
        monitoring-type: monitoring-type
      }
    )

    (var-set monitoring-counter schedule-id)

    (ok schedule-id)
  )
)

;; Set effectiveness benchmark
(define-public (set-benchmark (benchmark-name (string-ascii 50)) (target-effectiveness uint) (criteria (string-ascii 100)) (reward uint) (penalty uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (and (>= target-effectiveness u1) (<= target-effectiveness u10)) ERR-INVALID-RATING)

    (map-set effectiveness-benchmarks
      { benchmark-name: benchmark-name }
      {
        target-effectiveness: target-effectiveness,
        measurement-criteria: criteria,
        reward-amount: reward,
        penalty-amount: penalty
      }
    )

    (ok true)
  )
)

;; Generate effectiveness recommendations
(define-public (generate-recommendations (area-id uint))
  (let
    (
      (area-trends (map-get? area-effectiveness-trends { area-id: area-id }))
    )
    (match area-trends
      trends (begin
        (if (< (get average-effectiveness trends) (var-get effectiveness-threshold))
          (update-area-recommendations area-id)
          (ok true)
        )
      )
      ERR-INSUFFICIENT-DATA
    )
  )
)

;; Read-only Functions

(define-read-only (get-effectiveness-report (report-id uint))
  (map-get? effectiveness-reports { report-id: report-id })
)

(define-read-only (get-area-trends (area-id uint))
  (map-get? area-effectiveness-trends { area-id: area-id })
)

(define-read-only (get-treatment-stats (treatment-type (string-ascii 50)))
  (map-get? treatment-effectiveness-stats { treatment-type: treatment-type })
)

(define-read-only (get-monitoring-schedule (schedule-id uint))
  (map-get? monitoring-schedules { schedule-id: schedule-id })
)

(define-read-only (get-benchmark (benchmark-name (string-ascii 50)))
  (map-get? effectiveness-benchmarks { benchmark-name: benchmark-name })
)

(define-read-only (get-monitor-performance (monitor principal))
  (map-get? monitor-performance { monitor: monitor })
)

(define-read-only (get-monitoring-counter)
  (var-get monitoring-counter)
)

(define-read-only (get-token-balance (owner principal))
  (default-to u0 (get balance (map-get? token-balances { owner: owner })))
)

;; Calculate overall system effectiveness
(define-read-only (calculate-system-effectiveness)
  (let
    (
      ;; This would aggregate all area effectiveness in a real implementation
      (sample-effectiveness u8) ;; Placeholder
    )
    sample-effectiveness
  )
)

;; Private Functions

;; Calculate effectiveness score from pre/post treatment levels
(define-private (calculate-effectiveness (pre-level uint) (post-level uint))
  (if (>= pre-level post-level)
    (+ u1 (/ (* (- pre-level post-level) u9) pre-level)) ;; Scale to 1-10
    u1 ;; Minimum score if treatment made things worse
  )
)

;; Update area effectiveness trends
(define-private (update-area-effectiveness-trends (area-id uint) (effectiveness uint))
  (let
    (
      (current-trends (default-to
        { total-treatments: u0, successful-treatments: u0, average-effectiveness: u0, trend-direction: "stable", last-updated: u0, recommended-adjustments: (list) }
        (map-get? area-effectiveness-trends { area-id: area-id })
      ))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (new-total (+ (get total-treatments current-trends) u1))
      (new-successful (if (>= effectiveness (var-get effectiveness-threshold))
                        (+ (get successful-treatments current-trends) u1)
                        (get successful-treatments current-trends)))
      (new-average (/ (+ (* (get average-effectiveness current-trends) (get total-treatments current-trends)) effectiveness) new-total))
    )
    (map-set area-effectiveness-trends
      { area-id: area-id }
      {
        total-treatments: new-total,
        successful-treatments: new-successful,
        average-effectiveness: new-average,
        trend-direction: (determine-trend (get average-effectiveness current-trends) new-average),
        last-updated: current-time,
        recommended-adjustments: (get recommended-adjustments current-trends)
      }
    )
    (ok true)
  )
)

;; Update treatment effectiveness statistics
(define-private (update-treatment-stats (treatment-type (string-ascii 50)) (effectiveness uint))
  (let
    (
      (current-stats (default-to
        { total-applications: u0, success-rate: u0, average-effectiveness: u0, best-conditions: "", improvement-suggestions: (list) }
        (map-get? treatment-effectiveness-stats { treatment-type: treatment-type })
      ))
      (new-total (+ (get total-applications current-stats) u1))
      (new-successes (if (>= effectiveness (var-get effectiveness-threshold))
                        (+ (* (get success-rate current-stats) (get total-applications current-stats)) u100)
                        (* (get success-rate current-stats) (get total-applications current-stats))))
      (new-success-rate (/ new-successes new-total))
      (new-average (/ (+ (* (get average-effectiveness current-stats) (get total-applications current-stats)) effectiveness) new-total))
    )
    (map-set treatment-effectiveness-stats
      { treatment-type: treatment-type }
      {
        total-applications: new-total,
        success-rate: new-success-rate,
        average-effectiveness: new-average,
        best-conditions: (get best-conditions current-stats),
        improvement-suggestions: (get improvement-suggestions current-stats)
      }
    )
    (ok true)
  )
)

;; Update monitor performance statistics
(define-private (update-monitor-performance (monitor principal))
  (let
    (
      (current-performance (default-to
        { reports-submitted: u0, accuracy-rating: u10, total-rewards: u0, specialization: "general" }
        (map-get? monitor-performance { monitor: monitor })
      ))
    )
    (map-set monitor-performance
      { monitor: monitor }
      (merge current-performance
        {
          reports-submitted: (+ (get reports-submitted current-performance) u1)
        }
      )
    )
    (ok true)
  )
)

;; Determine trend direction based on effectiveness changes
(define-private (determine-trend (old-average uint) (new-average uint))
  (if (> new-average old-average)
    "improving"
    (if (< new-average old-average)
      "declining"
      "stable"
    )
  )
)

;; Update area recommendations based on poor performance
(define-private (update-area-recommendations (area-id uint))
  (let
    (
      (current-trends (unwrap-panic (map-get? area-effectiveness-trends { area-id: area-id })))
      (recommendations (list "increase-treatment-frequency" "change-treatment-method" "improve-application-timing"))
    )
    (map-set area-effectiveness-trends
      { area-id: area-id }
      (merge current-trends
        {
          recommended-adjustments: recommendations
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
    (if (>= current-balance amount)
      (begin
        (map-set token-balances
          { owner: payer }
          { balance: (- current-balance amount) }
        )
        (ok amount)
      )
      (ok u0) ;; Don't fail if insufficient funds
    )
  )
)
