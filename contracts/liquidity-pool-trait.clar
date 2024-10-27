;; liquidity-pool-trait.clar
;; Liquidity Pool Trait Definition

(define-trait pool-trait
    (
        ;; Pool Administration
        (initialize-pool () (response bool uint))
        (set-emergency-shutdown (bool) (response bool uint))

        ;; Pool Operations
        (deposit (uint) (response uint uint))

        ;; Read-only Configuration Status
        (get-init-status () bool)
        (get-emergency-status () bool)

        ;; Read-only Pool Information
        (get-liquidity-info () 
            (response 
                {
                    total-liquidity: uint,
                    total-shares: uint,
                    last-reward-block: uint
                }
                uint
            )
        )

        (get-provider-info (principal) 
            (response
                (optional 
                    {
                        shares: uint,
                        deposited-amount: uint,
                        last-deposit-block: uint,
                        last-withdrawal-block: uint,
                        cumulative-rewards: uint
                    }
                )
                uint
            )
        )

        (get-provider-share-value (principal) (response uint uint))

        ;; Calculation Functions
        (calculate-shares-for-amount (uint) (response uint uint))
        (calculate-amount-for-shares (uint) (response uint uint))
    )
)