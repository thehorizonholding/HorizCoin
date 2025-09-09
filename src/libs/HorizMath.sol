// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title HorizMath
 * @notice Mathematical utility functions for HorizCoin contracts
 * @dev Provides safe math operations and common calculations
 */
library HorizMath {
    /// @notice Basis points denominator (10,000 = 100%)
    uint256 public constant BASIS_POINTS_DENOMINATOR = 10000;
    
    /// @notice Maximum basis points value
    uint256 public constant MAX_BASIS_POINTS = 10000;
    
    /// @notice Error thrown when basis points exceed maximum
    error ExceedsMaxBasisPoints();
    
    /// @notice Error thrown when division by zero
    error DivisionByZero();

    /**
     * @notice Calculates percentage of a value using basis points
     * @param value The value to calculate percentage of
     * @param basisPoints Basis points (100 = 1%, 10000 = 100%)
     * @return Percentage of the value
     */
    function percentageOf(uint256 value, uint256 basisPoints) internal pure returns (uint256) {
        if (basisPoints > MAX_BASIS_POINTS) revert ExceedsMaxBasisPoints();
        return (value * basisPoints) / BASIS_POINTS_DENOMINATOR;
    }

    /**
     * @notice Calculates what basis points one value represents of another
     * @param part The part value
     * @param whole The whole value
     * @return Basis points representation
     */
    function toBasisPoints(uint256 part, uint256 whole) internal pure returns (uint256) {
        if (whole == 0) revert DivisionByZero();
        return (part * BASIS_POINTS_DENOMINATOR) / whole;
    }

    /**
     * @notice Safely adds two values with overflow check
     * @param a First value
     * @param b Second value
     * @return Sum of a and b
     */
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @notice Safely subtracts two values with underflow check
     * @param a First value
     * @param b Second value
     * @return Difference of a and b
     */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction underflow");
        return a - b;
    }

    /**
     * @notice Safely multiplies two values with overflow check
     * @param a First value
     * @param b Second value
     * @return Product of a and b
     */
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @notice Safely divides two values with zero check
     * @param a Dividend
     * @param b Divisor
     * @return Quotient of a and b
     */
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) revert DivisionByZero();
        return a / b;
    }

    /**
     * @notice Calculates the minimum of two values
     * @param a First value
     * @param b Second value
     * @return Minimum value
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @notice Calculates the maximum of two values
     * @param a First value
     * @param b Second value
     * @return Maximum value
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @notice Calculates compound interest
     * @param principal Principal amount
     * @param rate Interest rate in basis points per period
     * @param periods Number of periods
     * @return Final amount after compound interest
     */
    function compoundInterest(
        uint256 principal,
        uint256 rate,
        uint256 periods
    ) internal pure returns (uint256) {
        if (periods == 0) return principal;
        if (rate > MAX_BASIS_POINTS) revert ExceedsMaxBasisPoints();
        
        uint256 result = principal;
        for (uint256 i = 0; i < periods; i++) {
            result = (result * (BASIS_POINTS_DENOMINATOR + rate)) / BASIS_POINTS_DENOMINATOR;
        }
        return result;
    }

    /**
     * @notice Calculates linear interpolation between two points
     * @param x0 Start x value
     * @param y0 Start y value
     * @param x1 End x value
     * @param y1 End y value
     * @param x Target x value
     * @return Interpolated y value
     */
    function linearInterpolation(
        uint256 x0,
        uint256 y0,
        uint256 x1,
        uint256 y1,
        uint256 x
    ) internal pure returns (uint256) {
        if (x1 <= x0) revert DivisionByZero();
        if (x < x0) return y0;
        if (x > x1) return y1;
        
        if (y1 >= y0) {
            return y0 + ((y1 - y0) * (x - x0)) / (x1 - x0);
        } else {
            return y0 - ((y0 - y1) * (x - x0)) / (x1 - x0);
        }
    }

    /**
     * @notice Calculates square root using Babylonian method
     * @param x Value to calculate square root of
     * @return Square root of x
     */
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        
        return y;
    }

    /**
     * @notice Checks if a value is within a range (inclusive)
     * @param value Value to check
     * @param min Minimum value
     * @param max Maximum value
     * @return Whether value is in range
     */
    function inRange(uint256 value, uint256 min, uint256 max) internal pure returns (bool) {
        return value >= min && value <= max;
    }

    /**
     * @notice Clamps a value to a range
     * @param value Value to clamp
     * @param min Minimum value
     * @param max Maximum value
     * @return Clamped value
     */
    function clamp(uint256 value, uint256 min, uint256 max) internal pure returns (uint256) {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }
}