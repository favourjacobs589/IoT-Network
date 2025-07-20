# Decentralized IoT Management Smart Contract

A comprehensive Clarity smart contract for managing IoT devices, data access control, monetization, and network orchestration on the Stacks blockchain.

## Overview

This smart contract enables decentralized management of IoT devices with features including device registration, data storage, access control, payment systems, device networks, and maintenance tracking. It provides a complete framework for building IoT ecosystems with built-in monetization and governance mechanisms.

## Features

### Device Management
- **Device Registration**: Register IoT devices with metadata, location, and pricing
- **Status Management**: Track device status (Active, Inactive, Maintenance, Offline)
- **Device Types**: Support for Sensors, Actuators, Gateways, and Hybrid devices
- **Firmware Tracking**: Monitor and update firmware versions
- **Reputation System**: Built-in device reputation scoring

### Data Management
- **Secure Data Storage**: Store device data with cryptographic hashes
- **Data Verification**: Verification hash system for data integrity
- **Timestamping**: Blockchain-based timestamping for all data entries
- **Data Monetization**: Set prices for data access

### Access Control
- **Multi-level Access**: Read, Write, and Admin access levels
- **Time-based Permissions**: Set expiration times for access grants
- **Payment-based Access**: Purchase data access with STX tokens
- **Owner Controls**: Device owners can grant/revoke access

### Network Management
- **Device Networks**: Create and manage groups of IoT devices
- **Public/Private Networks**: Support for both open and restricted networks
- **Network Fees**: Monetize network participation
- **Role-based Membership**: Different roles within networks

### Maintenance System
- **Scheduled Maintenance**: Plan and track device maintenance
- **Cost Tracking**: Monitor maintenance costs and scheduling
- **Status Integration**: Automatic status updates during maintenance
- **Historical Records**: Complete maintenance history

### Monetization
- **Data Pricing**: Set individual prices for device data access
- **Platform Fees**: Configurable platform fee system (default 2.5%)
- **Earnings Tracking**: Monitor total device earnings
- **Subscription System**: Time-based data access subscriptions

## Contract Architecture

### Constants

```clarity
;; Error Codes
ERR-NOT-AUTHORIZED (u1001)
ERR-DEVICE-NOT-FOUND (u1002)
ERR-DEVICE-ALREADY-EXISTS (u1003)
ERR-INVALID-PARAMETERS (u1004)
ERR-INSUFFICIENT-PAYMENT (u1005)
ERR-DEVICE-OFFLINE (u1006)
ERR-ACCESS-DENIED (u1007)
ERR-DATA-NOT-FOUND (u1008)
ERR-INVALID-TIMESTAMP (u1009)
ERR-DEVICE-MAINTENANCE (u1010)
ERR-SUBSCRIPTION-EXPIRED (u1011)
ERR-INVALID-DEVICE-TYPE (u1012)

;; Device Status
STATUS-ACTIVE (u1)
STATUS-INACTIVE (u2)
STATUS-MAINTENANCE (u3)
STATUS-OFFLINE (u4)

;; Device Types
TYPE-SENSOR (u1)
TYPE-ACTUATOR (u2)
TYPE-GATEWAY (u3)
TYPE-HYBRID (u4)

;; Access Levels
ACCESS-READ (u1)
ACCESS-WRITE (u2)
ACCESS-ADMIN (u3)
```

### Data Structures

- **devices**: Core device information and metadata
- **device-data**: Timestamped device data storage
- **device-access**: Access control lists with expiration
- **device-networks**: Network definitions and settings
- **network-members**: Device membership in networks
- **subscriptions**: Data access subscriptions
- **maintenance-records**: Maintenance scheduling and tracking

## Key Functions

### Device Management

#### `register-device`
Register a new IoT device on the blockchain.

```clarity
(register-device 
  device-id 
  device-type 
  location 
  metadata 
  firmware-version 
  data-price 
  access-price)
```

#### `update-device`
Update device information (owner only).

#### `update-device-status`
Change device operational status.

### Data Operations

#### `store-device-data`
Store new data from a device with verification.

```clarity
(store-device-data 
  device-id 
  data-hash 
  data-type 
  sensor-value 
  data-size 
  verification-hash)
```

#### `purchase-data-access`
Purchase time-limited access to device data.

### Access Control

#### `grant-device-access`
Grant access permissions to users (device owner only).

#### `revoke-device-access`
Remove access permissions.

### Network Management

#### `create-network`
Create a new device network.

#### `join-network`
Add a device to an existing network.

### Maintenance

#### `schedule-maintenance`
Schedule future device maintenance.

#### `complete-maintenance`
Mark maintenance as completed and update costs.

## Usage Examples

### Registering a Temperature Sensor

```clarity
(contract-call? .iot-contract register-device
  "temp-sensor-001"
  u1  ;; TYPE-SENSOR
  "Building A, Floor 2"
  "Temperature sensor with 0.1°C precision"
  "v1.2.3"
  u1000  ;; 1000 microSTX per data access
  u5000  ;; 5000 microSTX per write access
)
```

### Storing Sensor Data

```clarity
(contract-call? .iot-contract store-device-data
  "temp-sensor-001"
  0x1234567890abcdef...  ;; data hash
  "temperature"
  (some 235)  ;; 23.5°C
  u64  ;; data size in bytes
  0xfedcba0987654321...  ;; verification hash
)
```

### Purchasing Data Access

```clarity
(contract-call? .iot-contract purchase-data-access
  "temp-sensor-001"
  u144  ;; 144 blocks (~24 hours)
)
```

### Creating a Smart Building Network

```clarity
(contract-call? .iot-contract create-network
  "smart-building-alpha"
  "Smart Building Alpha Network"
  "IoT devices for Building Alpha management"
  true   ;; public network
  u10000 ;; 10000 microSTX joining fee
)
```

## Read-Only Functions

- `get-device-info`: Retrieve device information
- `get-device-data`: Get specific timestamped data
- `check-device-access`: Verify user access permissions
- `get-network-info`: Network details and statistics
- `get-maintenance-record`: Maintenance history
- `get-contract-stats`: Overall contract statistics

## Administrative Functions

### Platform Management

- `toggle-contract-pause`: Emergency pause/unpause
- `update-platform-fee`: Adjust platform fee rate (max 10%)
- `admin-update-device-status`: Emergency device status override

## Security Features

- **Owner Authorization**: Device owners control their devices
- **Access Control**: Multi-level permission system
- **Payment Verification**: STX balance checks before transactions
- **Time-based Expiry**: Automatic access expiration
- **Emergency Controls**: Admin override capabilities
- **Contract Pausing**: Emergency stop functionality

## Economic Model

### Revenue Streams
1. **Data Access Fees**: Users pay device owners for data access
2. **Network Participation**: Fees for joining device networks
3. **Platform Fees**: 2.5% platform fee on all transactions

### Fee Distribution
- Device owners receive payment minus platform fee
- Platform fees go to contract owner
- Network fees go to network creators

## Integration Guidelines

### For IoT Device Manufacturers
1. Implement device registration during setup
2. Regular data uploads with proper hashing
3. Status monitoring and updates
4. Maintenance scheduling integration

### For Data Consumers
1. Browse available devices and pricing
2. Purchase access subscriptions
3. Verify data integrity using hashes
4. Respect access level limitations

### For Network Operators
1. Create themed device networks
2. Set appropriate joining fees
3. Monitor network health and participation
4. Manage member roles and permissions

## Development Setup

### Prerequisites
- Stacks blockchain node
- Clarity CLI tools
- STX testnet tokens for testing

## Best Practices

### For Device Owners
- Set reasonable data pricing
- Maintain regular data updates
- Schedule preventive maintenance
- Monitor device reputation scores

### For Users
- Verify device reputation before purchasing access
- Check data freshness timestamps
- Respect access level permissions
- Report issues to device owners

### Security Considerations
- Regularly update firmware versions
- Use strong verification hashes
- Monitor access patterns
- Keep maintenance records updated