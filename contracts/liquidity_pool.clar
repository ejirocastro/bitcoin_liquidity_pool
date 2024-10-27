;; Bitcoin Liquidity Pool
;; A decentralized protocol for providing Bitcoin liquidity on Stacks

(impl-trait 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.liquidity-pool-trait.pool-trait)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-POOL-FULL (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-POOL-EMPTY (err u104))
(define-constant ERR-ALREADY-INITIALIZED (err u105))
(define-constant ERR-NOT-INITIALIZED (err u106))
(define-constant ERR-WITHDRAWAL-TOO-LARGE (err u107))
(define-constant ERR-COOLDOWN-ACTIVE (err u108))

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MAX-POOL-SIZE u1000000000000) ;; 10,000 BTC in sats
(define-constant MIN-DEPOSIT u100000) ;; 0.001 BTC in sats
(define-constant REWARD-CYCLE-LENGTH u144) ;; ~1 day in blocks
(define-constant COOLDOWN-PERIOD u72) ;; ~12 hours in blocks
(define-constant PROTOCOL-FEE u5) ;; 0.5%
(define-constant PRECISION u1000000) ;; 6 decimal places for calculations

;; Data variables - State Group 1: Pool Configuration
(define-data-var pool-initialized bool false)
(define-data-var emergency-shutdown bool false)

;; Data variables - State Group 2: Pool Metrics
(define-data-var total-liquidity uint u0)
(define-data-var total-shares uint u0)
(define-data-var last-reward-block uint u0)

;; Data maps
(define-map liquidity-providers
    principal
    {
        shares: uint,
        deposited-amount: uint,
        last-deposit-block: uint,
        last-withdrawal-block: uint,
        cumulative-rewards: uint
    }
)

(define-map reward-checkpoints
    uint ;; block height
    {
        total-liquidity: uint,
        reward-rate: uint,
        accumulated-rewards: uint
    }
)

;; Private helper functions
(define-private (is-contract-owner)
    (is-eq tx-sender CONTRACT-OWNER)
)

(define-private (calculate-reward-rate)
    (let
        (
            (total-liq (var-get total-liquidity))
        )
        (if (is-eq total-liq u0)
            u0
            (/ (* total-liq u1) u100000) ;; 0.001% per block
        )
    )
)

(define-private (update-reward-checkpoint)
    (let
        (
            (current-block block-height)
            (last-block (var-get last-reward-block))
            (blocks-elapsed (- current-block last-block))
        )
        (if (> blocks-elapsed u0)
            (begin
                (map-set reward-checkpoints current-block
                    {
                        total-liquidity: (var-get total-liquidity),
                        reward-rate: (calculate-reward-rate),
                        accumulated-rewards: (+ 
                            (default-to u0 
                                (get accumulated-rewards 
                                    (map-get? reward-checkpoints last-block)
                                )
                            )
                            (* blocks-elapsed (calculate-reward-rate))
                        )
                    }
                )
                (var-set last-reward-block current-block)
                true
            )
            false
        )
    )
)

;; Read-only functions - Configuration Status
(define-read-only (get-init-status)
    (var-get pool-initialized)
)

(define-read-only (get-emergency-status)
    (var-get emergency-shutdown)
)

;; Read-only functions - Pool Information
(define-read-only (get-liquidity-info)
    {
        total-liquidity: (var-get total-liquidity),
        total-shares: (var-get total-shares),
        last-reward-block: (var-get last-reward-block)
    }
)

(define-read-only (get-provider-info (provider principal))
    (map-get? liquidity-providers provider)
)

(define-read-only (get-provider-share-value (provider principal))
    (let
        (
            (provider-data (unwrap! (map-get? liquidity-providers provider) (err u0)))
            (provider-shares (get shares provider-data))
        )
        (ok (if (is-eq (var-get total-shares) u0)
            u0
            (/ (* provider-shares (var-get total-liquidity)) (var-get total-shares))
        ))
    )
)

;; Public functions - Pool Administration
(define-public (initialize-pool)
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (not (var-get pool-initialized)) ERR-ALREADY-INITIALIZED)
        (var-set pool-initialized true)
        (var-set last-reward-block block-height)
        (ok true)
    )
)

(define-public (set-emergency-shutdown (shutdown bool))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set emergency-shutdown shutdown)
        (ok true)
    )
)

;; Public functions - Pool Operations
(define-public (deposit (amount uint))
    (let
        (
            (provider-data (default-to 
                {
                    shares: u0,
                    deposited-amount: u0,
                    last-deposit-block: u0,
                    last-withdrawal-block: u0,
                    cumulative-rewards: u0
                }
                (map-get? liquidity-providers tx-sender)
            ))
        )
        (asserts! (var-get pool-initialized) ERR-NOT-INITIALIZED)
        (asserts! (not (var-get emergency-shutdown)) ERR-POOL-FULL)
        (asserts! (>= amount MIN-DEPOSIT) ERR-INVALID-AMOUNT)
        (asserts! (<= (+ amount (var-get total-liquidity)) MAX-POOL-SIZE) ERR-POOL-FULL)
        
        (let
            (
                (new-shares (if (is-eq (var-get total-liquidity) u0)
                    amount
                    (/ (* amount (var-get total-shares)) (var-get total-liquidity))
                ))
            )
            (map-set liquidity-providers tx-sender
                {
                    shares: (+ (get shares provider-data) new-shares),
                    deposited-amount: (+ (get deposited-amount provider-data) amount),
                    last-deposit-block: block-height,
                    last-withdrawal-block: (get last-withdrawal-block provider-data),
                    cumulative-rewards: (get cumulative-rewards provider-data)
                }
            )
            (var-set total-liquidity (+ (var-get total-liquidity) amount))
            (var-set total-shares (+ (var-get total-shares) new-shares))
            (update-reward-checkpoint)
            (ok new-shares)
        )
    )
)

(define-read-only (calculate-shares-for-amount (amount uint))
    (ok (if (is-eq (var-get total-liquidity) u0)
        amount
        (/ (* amount (var-get total-shares)) (var-get total-liquidity))
    ))
)

(define-read-only (calculate-amount-for-shares (shares uint))
    (ok (if (is-eq (var-get total-shares) u0)
        u0
        (/ (* shares (var-get total-liquidity)) (var-get total-shares))
    ))
)