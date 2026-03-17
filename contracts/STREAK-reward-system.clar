;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DAILY LOGIN REWARD TRACKER
;;
;; DESCRIPTION
;; ----------------------------------------------------------------------------
;; This contract tracks daily user logins and distributes rewards.
;;
;; Users call `check-in` once per day to receive a reward and extend
;; their login streak.
;;
;; The contract stores:
;; - last login block height
;; - current login streak
;; - total rewards earned
;;
;; The system enforces:
;; - one reward per day
;; - streak reset if user misses a day
;; - configurable reward amount
;; - emergency pause control
;;
;; Example Use Cases
;; ----------------------------------------------------------------------------
;; - Game reward systems
;; - Daily platform engagement incentives
;; - NFT or token reward programs
;; - DeFi participation tracking
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;; ============================================================================
;; SECTION 1 - CONTRACT OWNERSHIP
;; ============================================================================

(define-data-var contract-owner principal tx-sender)



;; ============================================================================
;; SECTION 2 - ADMIN MANAGEMENT
;; ============================================================================

(define-map admins
  { admin: principal }
  { enabled: bool }
)



;; ============================================================================
;; SECTION 3 - GLOBAL PAUSE
;; ============================================================================

(define-data-var paused bool false)



;; ============================================================================
;; SECTION 4 - REWARD SETTINGS
;; ============================================================================

;; Reward amount given for each login
(define-data-var reward-amount uint u1000000)

;; Number of blocks that represent one day
(define-data-var blocks-per-day uint u144)



;; ============================================================================
;; SECTION 5 - USER LOGIN REGISTRY
;; ============================================================================

(define-map login-registry
  { user: principal }
  {
    last-login: uint,
    streak: uint,
    total-rewards: uint
  }
)



;; ============================================================================
;; SECTION 6 - ERROR CONSTANTS
;; ============================================================================

(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-PAUSED (err u101))
(define-constant ERR-TOO-SOON (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))



;; ============================================================================
;; SECTION 7 - INTERNAL HELPERS
;; ============================================================================

(define-private (is-owner (who principal))
  (is-eq who (var-get contract-owner))
)

(define-private (is-admin (who principal))
  (or
    (is-owner who)
    (default-to false
      (get enabled
        (map-get? admins { admin: who })
      )
    )
  )
)

(define-private (not-paused)
  (not (var-get paused))
)

(define-private (get-login (user principal))
  (map-get? login-registry { user: user })
)



;; ============================================================================
;; SECTION 8 - READ ONLY FUNCTIONS
;; ============================================================================

(define-read-only (get-login-info (user principal))
  (get-login user)
)

(define-read-only (get-streak (user principal))
  (match (get-login user)
    data (get streak data)
    u0
  )
)

(define-read-only (get-total-rewards (user principal))
  (match (get-login user)
    data (get total-rewards data)
    u0
  )
)

(define-read-only (can-check-in (user principal))
  (match (get-login user)
    data
      (>=
        burn-block-height
        (+ (get last-login data)
           (var-get blocks-per-day))
      )
    true
  )
)



;; ============================================================================
;; SECTION 9 - USER CHECK-IN
;; ============================================================================

(define-public (check-in)

  (begin

    (asserts! (not-paused) ERR-PAUSED)

    (let
      (
        (entry (get-login tx-sender))
        (day (var-get blocks-per-day))
        (reward (var-get reward-amount))
      )

      (if (is-none entry)

          ;; FIRST LOGIN
          (begin

            (map-set login-registry
              { user: tx-sender }
              {
                last-login: burn-block-height,
                streak: u1,
                total-rewards: reward
              }
            )

            (ok reward)
          )

          ;; EXISTING USER
          (let
            (
              (data (unwrap-panic entry))
              (last (get last-login data))
              (streak (get streak data))
              (total (get total-rewards data))
            )

            (asserts!
              (>= burn-block-height (+ last day))
              ERR-TOO-SOON
            )

            (let
              (
                (new-streak
                  (if (<= burn-block-height (+ last (* day u2)))
                      (+ streak u1)
                      u1
                  )
                )
              )

              (map-set login-registry
                { user: tx-sender }
                {
                  last-login: burn-block-height,
                  streak: new-streak,
                  total-rewards: (+ total reward)
                }
              )

              (ok reward)
            )
          )
      )
    )
  )
)



;; ============================================================================
;; SECTION 10 - ADMIN CONFIGURATION
;; ============================================================================

(define-public (set-reward-amount (amount uint))

  (begin

    (asserts! (is-admin tx-sender) ERR-UNAUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)

    (var-set reward-amount amount)

    (ok amount)
  )
)

(define-public (set-blocks-per-day (amount uint))

  (begin

    (asserts! (is-admin tx-sender) ERR-UNAUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)

    (var-set blocks-per-day amount)

    (ok amount)
  )
)



;; ============================================================================
;; SECTION 11 - ADMIN MANAGEMENT
;; ============================================================================

(define-public (add-admin (admin principal))

  (begin

    (asserts! (is-owner tx-sender) ERR-UNAUTHORIZED)

    (map-set admins
      { admin: admin }
      { enabled: true }
    )

    (ok true)
  )
)

(define-public (remove-admin (admin principal))

  (begin

    (asserts! (is-owner tx-sender) ERR-UNAUTHORIZED)

    (map-delete admins { admin: admin })

    (ok true)
  )
)



;; ============================================================================
;; SECTION 12 - EMERGENCY CONTROLS
;; ============================================================================

(define-public (pause)

  (begin

    (asserts! (is-owner tx-sender) ERR-UNAUTHORIZED)

    (var-set paused true)

    (ok true)
  )
)

(define-public (unpause)

  (begin

    (asserts! (is-owner tx-sender) ERR-UNAUTHORIZED)

    (var-set paused false)

    (ok true)
  )
)