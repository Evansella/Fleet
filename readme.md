# Vehicle Fleet Management Smart Contract

A Clarity smart contract for managing vehicle fleets on the Stacks blockchain, enabling vehicle registration, operator assignments, and maintenance technician access control.

## Overview

This smart contract provides a decentralized system for tracking vehicles, assigning operators, and managing maintenance access permissions. Each vehicle is registered with details including model, mileage, and operator assignment.

## Features

- **Vehicle Registration**: Enroll new vehicles in the fleet with model and mileage information
- **Operator Management**: Assign and reassign vehicle operators
- **Maintenance Access Control**: Authorize/deauthorize technicians for specific vehicles
- **Vehicle Updates**: Update vehicle model and mileage information
- **Vehicle Retirement**: Remove vehicles from the fleet roster

## Constants

- `fleet-manager`: Contract deployer (tx-sender)
- Error codes:
  - `err-manager-restricted (u100)`: Manager-only operation
  - `err-vehicle-missing (u101)`: Vehicle not found
  - `err-vehicle-registered (u102)`: Vehicle already registered
  - `err-invalid-model (u103)`: Invalid model string
  - `err-invalid-mileage (u104)`: Invalid mileage value
  - `err-no-clearance (u105)`: Unauthorized access

## Data Structure

### Fleet Roster Map
```clarity
{
  vehicle-id: uint
} => {
  operator: principal,
  model: string-ascii 64,
  mileage: uint,
  added-at: uint,
  maintenance-access: {
    technician: principal,
    granted: bool
  }
}
```

## Public Functions

### `enroll-vehicle`
Register a new vehicle in the fleet.

**Parameters:**
- `model`: Vehicle model name (1-64 ASCII characters)
- `mileage`: Current mileage (1 to 999,999,999)

**Returns:** `(ok vehicle-id)` or error

**Example:**
```clarity
(contract-call? .fleet-management enroll-vehicle "Toyota Camry 2023" u50000)
```

### `update-vehicle`
Update vehicle model and mileage (operator only).

**Parameters:**
- `vehicle-id`: Vehicle identifier
- `revised-model`: New model name
- `revised-mileage`: Updated mileage

**Returns:** `(ok true)` or error

### `retire-vehicle`
Remove a vehicle from the fleet roster (operator only).

**Parameters:**
- `vehicle-id`: Vehicle identifier

**Returns:** `(ok true)` or error

### `reassign-vehicle`
Transfer vehicle ownership to a new operator (current operator only).

**Parameters:**
- `vehicle-id`: Vehicle identifier
- `new-operator`: Principal address of new operator

**Returns:** `(ok true)` or error

### `authorize-technician`
Grant maintenance access to a technician (operator only).

**Parameters:**
- `vehicle-id`: Vehicle identifier
- `granted`: Authorization status (true/false)
- `technician`: Principal address of technician

**Returns:** `(ok true)` or error

### `deauthorize-technician`
Revoke maintenance access from a technician (operator only).

**Parameters:**
- `vehicle-id`: Vehicle identifier
- `granted`: Authorization status (false)
- `technician`: Principal address of technician

**Returns:** `(ok true)` or error

## Read-Only Functions

### `get-fleet-count`
Returns the total number of vehicles enrolled.

**Returns:** `(ok uint)`

### `get-vehicle-details`
Retrieve complete information for a specific vehicle.

**Parameters:**
- `vehicle-id`: Vehicle identifier

**Returns:** Vehicle data tuple or error

## Validation Rules

- **Model**: Must be 1-64 characters
- **Mileage**: Must be between 1 and 999,999,999
- **Authorization**: Only vehicle operators can modify their vehicles
- **Vehicle Existence**: Operations require vehicle to exist in fleet roster

## Usage Example

```clarity
;; Enroll a new vehicle
(contract-call? .fleet-management enroll-vehicle "Honda Accord 2024" u15000)
;; Returns: (ok u1)

;; Update vehicle information
(contract-call? .fleet-management update-vehicle u1 "Honda Accord 2024 EX" u16500)

;; Reassign to new operator
(contract-call? .fleet-management reassign-vehicle u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)

;; Authorize technician
(contract-call? .fleet-management authorize-technician u1 true 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)

;; Get vehicle details
(contract-call? .fleet-management get-vehicle-details u1)
```

## Security Considerations

- Only vehicle operators can modify their assigned vehicles
- Each vehicle can have one authorized technician at a time
- Vehicle enrollment requires valid model and mileage parameters
- No central authority can modify vehicles (except operators themselves)
