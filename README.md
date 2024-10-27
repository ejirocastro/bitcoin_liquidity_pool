# Bitcoin Liquidity Pool

A secure and efficient implementation of a Bitcoin liquidity pool smart contract in Clarity. This implementation provides a decentralized way to manage Bitcoin liquidity with features like automated reward distribution, emergency controls, and precise share calculations.

## Overview

The project consists of two main components:

- `liquidity-pool-trait.clar`: Defines the interface for the liquidity pool functionality
- `liquidity-pool.clar`: Implements the actual liquidity pool logic

### Key Features

- Secure deposit and withdrawal mechanisms
- Automated reward distribution system
- Precise share calculation and tracking
- Emergency shutdown capability
- Cooldown periods for risk management
- Dynamic reward rate calculations
- Comprehensive provider tracking

## Technical Specifications

### Constants

- Maximum Pool Size: 10,000 BTC (in sats)
- Minimum Deposit: 0.001 BTC (in sats)
- Reward Cycle Length: ~1 day (144 blocks)
- Cooldown Period: ~12 hours (72 blocks)
- Protocol Fee: 0.5%
- Precision: 6 decimal places

### State Management

The contract maintains several state variables and maps:

#### Pool Configuration

- Pool initialization status
- Emergency shutdown status

#### Pool Metrics

- Total liquidity
- Total shares
- Last reward block

#### Data Maps

- Liquidity providers tracking
- Reward checkpoints

## Interface (Trait) Description

### Administrative Functions

```clarity
initialize-pool() → (response bool uint)
set-emergency-shutdown(bool) → (response bool uint)
```

### Operation Functions

```clarity
deposit(uint) → (response uint uint)
```

### Read-Only Functions

```clarity
get-init-status() → bool
get-emergency-status() → bool
get-liquidity-info() → (response {...} uint)
get-provider-info(principal) → (response {...} uint)
get-provider-share-value(principal) → (response uint uint)
```

### Calculation Functions

```clarity
calculate-shares-for-amount(uint) → (response uint uint)
calculate-amount-for-shares(uint) → (response uint uint)
```

## Error Codes

| Code | Description          |
| ---- | -------------------- |
| u100 | Not authorized       |
| u101 | Pool full            |
| u102 | Insufficient balance |
| u103 | Invalid amount       |
| u104 | Pool empty           |
| u105 | Already initialized  |
| u106 | Not initialized      |
| u107 | Withdrawal too large |
| u108 | Cooldown active      |

## Usage Examples

### Initializing the Pool

```clarity
;; Only contract owner can initialize
(contract-call? .liquidity-pool initialize-pool)
```

### Making a Deposit

```clarity
;; Deposit 0.01 BTC (1,000,000 sats)
(contract-call? .liquidity-pool deposit u1000000)
```

### Checking Provider Info

```clarity
;; Get information about a liquidity provider
(contract-call? .liquidity-pool get-provider-info tx-sender)
```

## Security Considerations

1. **Access Control**: Only the contract owner can perform administrative functions
2. **Deposit Limits**: Both minimum and maximum deposit limits are enforced
3. **Emergency Shutdown**: Ability to pause operations in case of emergencies
4. **Cooldown Periods**: Prevents rapid deposit/withdrawal attacks
5. **Precision Handling**: Uses high precision (6 decimal places) for accurate calculations

## Development and Testing

To work with this contract:

1. Ensure you have Clarity tools installed
2. Deploy the trait contract first (`liquidity-pool-trait.clar`)
3. Deploy the implementation contract (`liquidity-pool.clar`)
4. Run tests against the implementation

## Contributing

Contributions are welcome! Please ensure you:

1. Follow the existing code style
2. Add tests for any new functionality
3. Update documentation as needed
4. Test thoroughly before submitting PRs

## License

This project is open source and available under the MIT License.
