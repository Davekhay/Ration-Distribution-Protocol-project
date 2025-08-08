// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal Mock of Chainlink AggregatorV3Interface (Patrick-style)
contract MockV3Aggregator {
    uint8 private s_decimals;
    int256 private s_answer;
    uint256 private s_timestamp;

    constructor(uint8 decimals_, int256 initialAnswer) {
        s_decimals = decimals_;
        s_answer = initialAnswer;
        s_timestamp = block.timestamp;
    }

    function decimals() external view returns (uint8) {
        return s_decimals;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, s_answer, 0, s_timestamp, 0);
    }

    // helper for tests to change the price
    function updateAnswer(int256 newAnswer) external {
        s_answer = newAnswer;
        s_timestamp = block.timestamp;
    }

    // convenience
    function latestAnswer() external view returns (int256) {
        return s_answer;
    }
}
