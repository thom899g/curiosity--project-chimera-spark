// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ChimeraSpark Heart Contract
 * @dev On-chain state kernel with self-preservation instincts
 * @notice Immutable memory and rule engine for cellular economic entity
 */
contract ChimeraSpark {
    // ============ STATE VARIABLES ============
    address public immutable owner;
    uint256 public immutable maxDrawdownBps; // Basis points (e.g., 2000 = 20%)
    uint256 public immutable maxGasPrice;
    uint256 public immutable maxSlippageBps;
    
    uint256 public totalEquity;
    uint256 public initialEquity;
    uint256 public lastUpkeepBlock;
    
    bool public isPaused;
    uint8 public consecutiveFails;
    
    // Circuit breaker thresholds
    uint256 public constant MAX_CONSECUTIVE_FAILS = 3;
    
    // ============ EVENTS ============
    event UpkeepPerformed(
        uint256 indexed cycleId,
        uint256 equityBefore,
        uint256 equityAfter,
        bool tradeExecuted,
        uint256 gasUsed
    );
    
    event CircuitBreakerTriggered(
        string reason,
        uint256 equity,
        uint256 timestamp
    );
    
    event EmergencyPause(bool paused, string reason);
    
    // ============ MODIFIERS ============
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier notPaused() {
        require(!isPaused, "System paused");
        _;
    }
    
    modifier gasPriceCheck() {
        require(tx.gasprice <= maxGasPrice * 1 gwei, "Gas price too high");
        _;
    }
    
    // ============ CONSTRUCTOR ============
    constructor(
        uint256 _maxDrawdownBps,
        uint256 _maxGasPrice,
        uint256 _maxSlippageBps
    ) payable {
        owner = msg.sender;
        maxDrawdownBps = _maxDrawdownBps;
        maxGasPrice = _maxGasPrice;
        maxSlippageBps = _maxSlippageBps;
        totalEquity = msg.value;
        initialEquity = msg.value;
        lastUpkeepBlock = block.number;
    }
    
    // ============ CORE FUNCTIONS ============
    /**
     * @dev Permissionless upkeep entry point - the heartbeat of the system
     * @param equityCheck Minimum equity required to proceed
     * @param shouldTrade Whether a trading signal was detected
     * @param targetPrice Price at which to execute (for slippage check)
     */
    function performUpkeep(
        uint256 equityCheck,
        bool shouldTrade,
        uint256 targetPrice
    ) external notPaused gasPriceCheck returns (bool) {
        // Pre-execution safety checks
        require(totalEquity >= equityCheck, "Equity check failed");
        require(block.number > lastUpkeepBlock, "Too soon");
        
        uint256 gasStart = gasleft();
        uint256 equityBefore = totalEquity;
        
        try this._executeUpkeep(shouldTrade, targetPrice) {
            // Success path
            uint256 gasUsed = gasStart - gasleft();
            lastUpkeepBlock = block.number;
            consecutiveFails = 0;
            
            emit UpkeepPerformed(
                block.number,
                equityBefore,
                totalEquity,
                shouldTrade,
                gasUsed
            );
            
            // Post-execution equity check
            _checkCircuitBreakers();
            return true;
            
        } catch (bytes memory reason) {
            // Failure path
            consecutiveFails++;
            emit CircuitBreakerTriggered(
                string(reason),
                totalEquity,
                block.timestamp
            );
            
            if (consecutiveFails >= MAX_CONSECUTIVE_FAILS) {
                isPaused = true;
                emit EmergencyPause(true, "Max consecutive fails");
            }
            return false;
        }
    }
    
    // ============ INTERNAL FUNCTIONS ============
    function _executeUpkeep(bool shouldTrade, uint256 targetPrice) internal {
        // Placeholder for actual trading logic
        // In production, this would interact with DEXes
        if (shouldTrade) {
            // Simulate trade with slippage check
            uint256 minReceived = targetPrice * (10000 - maxSlippageBps) / 10000;
            // ... DEX interaction would go here
        }
        
        // Update equity (simulated for now)
        // In production, this would be updated from actual DEX balances
        _updateEquity();
    }
    
    function _updateEquity() internal {
        // In production: query actual token balances and convert to ETH value
        // For now, simulate small random change (±0.5%)
        int256 change = int256(totalEquity) * (int256(block.timestamp % 100) - 50) / 10000;
        if (change > 0) {
            totalEquity += uint256(change);
        } else if (uint256(-change) < totalEquity) {
            totalEquity -= uint256(-change);
        }
    }
    
    function _checkCircuitBreakers() internal {
        // Drawdown check
        uint256 drawdownBps = (initialEquity - totalEquity) * 10000 / initialEquity;
        if (drawdownBps >= maxDrawdownBps) {
            isPaused = true;
            emit EmergencyPause(true, "Max drawdown reached");
        }
    }
    
    // ============ ADMIN FUNCTIONS ============
    function emergencyWithdraw(address recipient) external onlyOwner {
        require(isPaused, "System must be paused");
        uint256 balance = address(this).balance;
        payable(recipient).transfer(balance);
        totalEquity = 0;
    }
    
    function setPaused(bool _paused) external onlyOwner {
        isPaused = _paused;
        emit EmergencyPause(_paused, "Manual override");
    }
    
    function injectCapital() external payable onlyOwner {
        totalEquity += msg.value;
        if (totalEquity > initialEquity) {
            initialEquity = totalEquity;
        }
    }
    
    // ============ VIEW FUNCTIONS ============
    function getHealthStatus() external view returns (
        bool healthy,
        uint256 equity,
        uint256 drawdownBps,
        uint8 fails,
        bool paused
    ) {
        uint256 currentDrawdownBps = (initialEquity - totalEquity) * 10000 / initialEquity;
        healthy = !isPaused && 
                 consecutiveFails < MAX_CONSECUTIVE_FAILS &&
                 currentDrawdownBps < maxDrawdownBps;
        
        return (
            healthy,
            totalEquity,
            currentDrawdownBps,
            consecutiveFails,
            isPaused
        );
    }
    
    // Accept ETH
    receive() external payable {
        totalEquity += msg.value;
    }
}