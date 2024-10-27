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
