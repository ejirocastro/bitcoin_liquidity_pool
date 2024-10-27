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


;; Data variables
(define-data-var total-liquidity uint u0)
(define-data-var total-shares uint u0)
(define-data-var last-reward-block uint u0)
(define-data-var pool-initialized bool false)
(define-data-var emergency-shutdown bool false)


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

;; Authorization check
(define-private (is-contract-owner)
    (is-eq tx-sender CONTRACT-OWNER)
)

;; Initialize pool
(define-public (initialize-pool)
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (not (var-get pool-initialized)) ERR-ALREADY-INITIALIZED)
        (var-set pool-initialized true)
        (var-set last-reward-block block-height)
        (ok true)
    )
)


;; Emergency controls
(define-public (emergency-shutdown)
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set emergency-shutdown true)
        (ok true)
    )
)

(define-public (resume-pool)
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set emergency-shutdown false)
        (ok true)
    )
)


;; Deposit liquidity
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
            (current-shares (get shares provider-data))
            (current-deposits (get deposited-amount provider-data))
        )
        (asserts! (var-get pool-initialized) ERR-NOT-INITIALIZED)
        (asserts! (not (var-get emergency-shutdown)) ERR-POOL-FULL)
        (asserts! (>= amount MIN-DEPOSIT) ERR-INVALID-AMOUNT)
        (asserts! (<= (+ amount (var-get total-liquidity)) MAX-POOL-SIZE) ERR-POOL-FULL)
        
        ;; Calculate new shares
        (let
            (
                (new-shares (if (is-eq (var-get total-liquidity) u0)
                    amount
                    (/ (* amount (var-get total-shares)) (var-get total-liquidity))
                ))
            )
            ;; Update provider data
            (map-set liquidity-providers tx-sender
                {
                    shares: (+ current-shares new-shares),
                    deposited-amount: (+ current-deposits amount),
                    last-deposit-block: block-height,
                    last-withdrawal-block: (get last-withdrawal-block provider-data),
                    cumulative-rewards: (get cumulative-rewards provider-data)
                }
            )
            
            ;; Update pool state
            (var-set total-liquidity (+ (var-get total-liquidity) amount))
            (var-set total-shares (+ (var-get total-shares) new-shares))
            
            ;; Update reward checkpoint
            (update-reward-checkpoint)
            
            (ok new-shares)
        )
    )
)