#!/bin/bash

# HorizCoin Post-Deploy Checklist Script
# This script performs sanity checks after deployment

set -e  # Exit on any error

echo "=== HORIZCOIN POST-DEPLOY CHECKLIST ==="
echo "Starting verification checks..."

# Check if addresses.json exists
if [ ! -f "addresses.json" ]; then
    echo "❌ addresses.json not found. Run deployment script first."
    exit 1
fi

echo "✅ addresses.json found"

# Extract network info
NETWORK=$(jq -r '.network' addresses.json)
TIMESTAMP=$(jq -r '.timestamp' addresses.json)

echo "📋 Network: $NETWORK"
echo "📋 Deployment Time: $(date -d @$TIMESTAMP)"

# Extract contract addresses
TOKEN=$(jq -r '.contracts.token' addresses.json)
TIMELOCK=$(jq -r '.contracts.timelock' addresses.json)
GOVERNOR=$(jq -r '.contracts.governor' addresses.json)
TREASURY=$(jq -r '.contracts.treasury' addresses.json)
PARAMETER_MODULE=$(jq -r '.contracts.parameterModule' addresses.json)
PAUSE_MODULE=$(jq -r '.contracts.pauseModule' addresses.json)
VESTING_VAULT=$(jq -r '.contracts.vestingVault' addresses.json)
MERKLE_AIRDROP=$(jq -r '.contracts.merkleAirdrop' addresses.json)
FIXED_PRICE_SALE=$(jq -r '.contracts.fixedPriceSale' addresses.json)
ESCROW_VAULT=$(jq -r '.contracts.escrowVault' addresses.json)
RATE_LIMITED_ADAPTER=$(jq -r '.contracts.rateLimitedAdapter' addresses.json)

echo ""
echo "=== CONTRACT ADDRESSES ==="
echo "🪙  Token:               $TOKEN"
echo "⏰ Timelock:            $TIMELOCK"
echo "🏛️  Governor:            $GOVERNOR"
echo "💰 Treasury:            $TREASURY"
echo "⚙️  Parameter Module:    $PARAMETER_MODULE"
echo "⏸️  Pause Module:        $PAUSE_MODULE"
echo "🎁 Vesting Vault:       $VESTING_VAULT"
echo "🪂 Merkle Airdrop:      $MERKLE_AIRDROP"
echo "💸 Fixed Price Sale:    $FIXED_PRICE_SALE"
echo "🏗️  Escrow Vault:        $ESCROW_VAULT"
echo "🔒 Rate Limited Adapter: $RATE_LIMITED_ADAPTER"

echo ""
echo "=== CORE CONTRACT VERIFICATION ==="

# Check if addresses are valid (not null or 0x0)
check_address() {
    local name=$1
    local addr=$2
    
    if [ "$addr" == "null" ] || [ "$addr" == "0x0000000000000000000000000000000000000000" ]; then
        echo "❌ $name address is invalid: $addr"
        return 1
    else
        echo "✅ $name address is valid: $addr"
        return 0
    fi
}

# Verify core contract addresses
check_address "Token" "$TOKEN"
check_address "Timelock" "$TIMELOCK"
check_address "Governor" "$GOVERNOR"
check_address "Treasury" "$TREASURY"
check_address "Parameter Module" "$PARAMETER_MODULE"
check_address "Vesting Vault" "$VESTING_VAULT"

echo ""
echo "=== ROLE VERIFICATION ==="

# Note: These checks would require Foundry/cast to be available
# For now, we'll provide manual verification instructions

echo "📝 MANUAL VERIFICATION REQUIRED:"
echo ""
echo "1. Verify Token ownership transferred to Treasury:"
echo "   Command: cast call $TOKEN 'owner()' --rpc-url \$RPC_URL"
echo "   Expected: $TREASURY"
echo ""

echo "2. Verify Timelock has PROPOSER_ROLE for Governor:"
echo "   Command: cast call $TIMELOCK 'hasRole(bytes32,address)' 0x8c5c4b4d1f0d9d08dfe6be5b5a5e5c5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e $GOVERNOR --rpc-url \$RPC_URL"
echo "   Expected: true"
echo ""

echo "3. Verify Treasury admin role transferred to Timelock:"
echo "   Command: cast call $TREASURY 'hasRole(bytes32,address)' 0x0000000000000000000000000000000000000000000000000000000000000000 $TIMELOCK --rpc-url \$RPC_URL"
echo "   Expected: true"
echo ""

echo "4. Verify Governor voting parameters:"
echo "   Command: cast call $GOVERNOR 'votingDelay()' --rpc-url \$RPC_URL"
echo "   Command: cast call $GOVERNOR 'votingPeriod()' --rpc-url \$RPC_URL"
echo "   Command: cast call $GOVERNOR 'quorumNumerator()' --rpc-url \$RPC_URL"
echo ""

echo "5. Verify Token total supply and balance:"
echo "   Command: cast call $TOKEN 'totalSupply()' --rpc-url \$RPC_URL"
echo "   Command: cast call $TOKEN 'balanceOf(address)' $TREASURY --rpc-url \$RPC_URL"
echo ""

echo "=== SECURITY CHECKLIST ==="
echo "📋 Security Items to Verify:"
echo ""
echo "☐ Timelock admin role renounced (for production)"
echo "☐ All critical roles transferred to appropriate contracts"
echo "☐ Token ownership properly transferred"
echo "☐ Multisig configured for emergency roles"
echo "☐ Parameter modules properly configured"
echo "☐ Rate limits configured appropriately"
echo "☐ Pause mechanisms tested"
echo "☐ Emission rates within acceptable bounds"
echo ""

echo "=== OPERATIONAL CHECKLIST ==="
echo "📋 Operational Items:"
echo ""
echo "☐ Vesting schedules can be created"
echo "☐ Airdrop Merkle roots can be set"
echo "☐ Governance proposals can be created"
echo "☐ Treasury operations are functional"
echo "☐ Emergency procedures documented"
echo "☐ Monitoring systems configured"
echo ""

echo "=== WARNING ITEMS ==="
echo "⚠️  IMPORTANT WARNINGS:"
echo ""
echo "⚠️  FixedPriceSale is a STUB contract - DO NOT ACTIVATE"
echo "⚠️  Configure sale parameters before any activation"
echo "⚠️  Verify all rate limits before production use"
echo "⚠️  Test governance flow before granting significant permissions"
echo "⚠️  Ensure multisig security for emergency roles"
echo ""

echo "=== NEXT STEPS ==="
echo "📝 Recommended Next Steps:"
echo ""
echo "1. Run automated tests against deployed contracts"
echo "2. Verify contract source code on block explorer"
echo "3. Set up monitoring and alerting"
echo "4. Create initial governance proposals"
echo "5. Configure vesting schedules if needed"
echo "6. Set up airdrop Merkle trees if applicable"
echo "7. Document emergency procedures"
echo "8. Train operators on governance tools"
echo ""

echo "=== AUDIT PREPARATION ==="
echo "📋 For audit preparation:"
echo ""
echo "☐ Freeze codebase and create audit branch"
echo "☐ Generate comprehensive test coverage report"
echo "☐ Document all assumptions and design decisions"
echo "☐ Prepare threat model documentation"
echo "☐ Create invariant test suite"
echo "☐ Set up gas optimization baseline"
echo ""

echo "=== CHECKLIST COMPLETE ==="
echo "✅ Post-deploy checklist completed"
echo "📁 Review addresses.json for contract addresses"
echo "📚 See docs/ for detailed documentation"
echo "🔐 Follow security procedures before mainnet deployment"
echo ""
echo "For questions or issues, contact: security@horizcoin.org"