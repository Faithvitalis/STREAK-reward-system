# STREAK Reward System

A Clarity smart contract for tracking daily user logins and distributing rewards based on login streaks.

## Features
- Daily check-in for users to earn rewards
- Tracks last login, current streak, and total rewards
- Configurable reward amount and blocks-per-day
- Admin and owner management
- Emergency pause/unpause controls
- Error handling for unauthorized actions and invalid inputs

## Use Cases
- Game reward systems
- Daily platform engagement incentives
- NFT or token reward programs
- DeFi participation tracking

## Contract Structure
- **Ownership:** Only the contract owner can add/remove admins and pause/unpause the contract
- **Admin Management:** Admins can configure reward settings
- **Global Pause:** Emergency controls to pause/unpause contract operations
- **Reward Settings:** Adjustable reward amount and blocks-per-day
- **User Login Registry:** Tracks user login data

## Functions
### User Functions
- `check-in`: User checks in to receive daily reward and update streak
- `get-login-info`: View user's login data
- `get-streak`: View user's current streak
- `get-total-rewards`: View user's total rewards
- `can-check-in`: Check if user is eligible to check in

### Admin/Owner Functions
- `set-reward-amount`: Set daily reward amount
- `set-blocks-per-day`: Set blocks representing one day
- `add-admin`: Add a new admin
- `remove-admin`: Remove an admin
- `pause`: Pause contract
- `unpause`: Unpause contract

## Error Codes
- `ERR-UNAUTHORIZED`: Unauthorized action
- `ERR-PAUSED`: Contract is paused
- `ERR-TOO-SOON`: User checked in too soon
- `ERR-INVALID-AMOUNT`: Invalid reward or block amount

## Getting Started
1. Deploy the contract using Clarinet or Stacks CLI
2. Set initial reward amount and blocks-per-day
3. Add admins as needed
4. Users can call `check-in` to start earning rewards

## Example
```lisp
;; User checks in
(check-in)

;; Admin sets reward amount
(set-reward-amount u2000000)
```
