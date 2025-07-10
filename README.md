# Tokenized Autonomous Outdoor Pest Control Networks

A decentralized pest control management system built on Stacks blockchain using Clarity smart contracts. This system provides autonomous monitoring, treatment coordination, and safety compliance for outdoor pest control operations.

## System Overview

The network consists of five interconnected smart contracts that work together to provide comprehensive pest control management:

### Core Contracts

1. **Infestation Detection Contract** (`infestation-detection.clar`)
    - Monitors pest population levels and activity patterns
    - Records detection events with timestamps and severity levels
    - Maintains historical data for trend analysis

2. **Treatment Coordination Contract** (`treatment-coordination.clar`)
    - Manages eco-friendly pest control application scheduling
    - Coordinates treatment resources and timing
    - Tracks treatment effectiveness and resource usage

3. **Prevention Planning Contract** (`prevention-planning.clar`)
    - Implements proactive pest deterrent strategies
    - Schedules preventive measures based on seasonal patterns
    - Manages prevention resource allocation

4. **Safety Compliance Contract** (`safety-compliance.clar`)
    - Ensures pet and child-safe pest control methods
    - Validates treatment safety protocols
    - Maintains compliance records and certifications

5. **Effectiveness Monitoring Contract** (`effectiveness-monitoring.clar`)
    - Tracks pest control success rates and metrics
    - Monitors treatment effectiveness over time
    - Provides data for strategy adjustments

## Token Economics

The system uses a native token (PEST) for:
- Incentivizing accurate pest detection reporting
- Paying for treatment services
- Rewarding effective prevention strategies
- Ensuring compliance with safety standards

## Key Features

- **Autonomous Operation**: Smart contracts automatically coordinate pest control activities
- **Safety First**: Built-in safety compliance ensures pet and child protection
- **Eco-Friendly**: Focus on environmentally sustainable pest control methods
- **Data-Driven**: Comprehensive monitoring and effectiveness tracking
- **Decentralized**: No single point of failure or control

## Getting Started

### Prerequisites
- Stacks blockchain development environment
- Clarity CLI tools
- Node.js for testing

### Installation

1. Clone the repository
2. Install dependencies: \`npm install\`
3. Run tests: \`npm test\`
4. Deploy contracts to testnet

### Testing

The project includes comprehensive test suites using Vitest:
- Unit tests for each contract
- Integration tests for system workflows
- Safety compliance validation tests

### Contract Deployment

Deploy contracts in the following order:
1. Safety Compliance Contract (foundational)
2. Infestation Detection Contract
3. Prevention Planning Contract
4. Treatment Coordination Contract
5. Effectiveness Monitoring Contract

## Usage Examples

### Reporting Pest Infestation
\`\`\`clarity
(contract-call? .infestation-detection report-infestation
u5 ;; severity level
"aphids" ;; pest type
u100) ;; estimated population
\`\`\`

### Scheduling Treatment
\`\`\`clarity
(contract-call? .treatment-coordination schedule-treatment
u1 ;; area-id
"organic-spray" ;; treatment type
u1000) ;; cost in tokens
\`\`\`

### Implementing Prevention
\`\`\`clarity
(contract-call? .prevention-planning implement-prevention
"companion-planting" ;; strategy type
u30) ;; duration in days
\`\`\`

## Safety Standards

All treatments must pass safety compliance checks:
- Pet-safe formulations only
- Child-safe application methods
- Environmental impact assessments
- Proper timing and weather considerations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests
4. Ensure all safety compliance checks pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For technical support or questions about the pest control network, please open an issue in the repository.
