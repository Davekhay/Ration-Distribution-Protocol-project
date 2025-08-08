// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// Custom errors 
error RD_ZeroAdmin();
error RD_ZeroFeed();
error RD_ZeroDealer();
error RD_NotDealer();
error RD_AlreadyRegistered();
error RD_NotRegistered();
error RD_ClaimNotReady();
error RD_InvalidPrice();
error RD_NotDealerToRemove();

/// Structs
struct Beneficiary {
    bool registered;
    uint256 lastClaimed;
}

contract RationDistribution is Ownable, Pausable {
    /* ========== STATE ========== */
    mapping(address => bool) private s_dealers;
    mapping(address => Beneficiary) private s_beneficiaries;

    AggregatorV3Interface public priceFeed;
    uint256 public cycleDuration;

    /* ========== EVENTS ========== */
    event DealerAdded(address indexed dealer);
    event DealerRemoved(address indexed dealer);
    event BeneficiaryRegistered(address indexed dealer, address indexed beneficiary);
    event RationClaimed(address indexed beneficiary, uint256 amount, uint256 timestamp);

    /* ========== CONSTRUCTOR ========== */
    constructor(address _admin, uint256 _cycleDuration, address _priceFeed) {
        if (_admin == address(0)) revert RD_ZeroAdmin();
        if (_priceFeed == address(0)) revert RD_ZeroFeed();

        // set owner to deployer first then transfer to desired admin
        _transferOwnership(_admin); // this makes owner() == _admin

        cycleDuration = _cycleDuration;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /* ========== MODIFIERS ========== */
    modifier onlyDealer() {
        if (!s_dealers[msg.sender]) revert RD_NotDealer();
        _;
    }

    /* ========== ADMIN ========== */
    function addDealer(address dealer) external onlyOwner {
        if (dealer == address(0)) revert RD_ZeroDealer();
        s_dealers[dealer] = true;
        emit DealerAdded(dealer);
    }

    function removeDealer(address dealer) external onlyOwner {
        if (!s_dealers[dealer]) revert RD_NotDealerToRemove();
        s_dealers[dealer] = false;
        emit DealerRemoved(dealer);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /* ========== DEALER ========== */
    function registerBeneficiary(address beneficiary) external onlyDealer {
        if (beneficiary == address(0)) revert RD_ZeroDealer(); // reusing zero dealer error for zero address
        if (s_beneficiaries[beneficiary].registered) revert RD_AlreadyRegistered();

        s_beneficiaries[beneficiary] = Beneficiary({registered: true, lastClaimed: 0});
        emit BeneficiaryRegistered(msg.sender, beneficiary);
    }

    function claimRationFor(address beneficiary) external onlyDealer whenNotPaused {
        Beneficiary storage b = s_beneficiaries[beneficiary];
        if (!b.registered) revert RD_NotRegistered();
        if (block.timestamp < b.lastClaimed + cycleDuration) revert RD_ClaimNotReady();

        uint256 amount = getSubsidyAmount();
        b.lastClaimed = block.timestamp;
        emit RationClaimed(beneficiary, amount, block.timestamp);

        // NOTE: no transfer logic here — add token/ETH transfer if desired
    }

    /* ========== VIEWS ========== */
    function getBeneficiary(address beneficiary) external view returns (Beneficiary memory) {
        return s_beneficiaries[beneficiary];
    }

    function isDealer(address account) public view returns (bool) {
        return s_dealers[account];
    }

    function isBeneficiaryEligible(address beneficiary) public view returns (bool) {
        Beneficiary memory b = s_beneficiaries[beneficiary];
        if (!b.registered) return false;
        return block.timestamp >= b.lastClaimed + cycleDuration;
    }

    function getSubsidyAmount() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        if (price <= 0) revert RD_InvalidPrice();
        uint256 usdAmount = 1e8; // $1 in feed decimals (8)
        return (usdAmount * 1 ether) / uint256(price);
    }

    function beneficiaries(address beneficiary) public view returns (bool registered, uint256 lastClaimed) {
    Beneficiary memory b = s_beneficiaries[beneficiary];
    return (b.registered, b.lastClaimed);
    }

}
