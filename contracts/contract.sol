pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MyICO is ERC20, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public softCap;
    uint256 public hardCap;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public freezePeriod;
    uint256 public totalCollected;
    address public wallet;

    mapping(address => uint256) public contributions;
    bool public softCapReached;
    bool public fundsTransferred;

    constructor(
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _freezePeriod,
        address _wallet
    ) ERC20("MyToken", "MTK") {
        require(_softCap < _hardCap, "SoftCap must be less than HardCap");
        require(_startTime < _endTime, "The start time must be less than the end time");
        require(_wallet != address(0), "The wallet address cannot be null");

        softCap = _softCap;
        hardCap = _hardCap;
        startTime = _startTime;
        endTime = _endTime;
        freezePeriod = _freezePeriod;
        wallet = _wallet;
    }

    function buyTokens() public payable nonReentrant {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "ICO not active");
        require(totalCollected.add(msg.value) <= hardCap, "HardCap exceeded");

        uint256 tokens = msg.value; // Настройте курс обмена по необходимости

        _mint(msg.sender, tokens);
        contributions[msg.sender] = contributions[msg.sender].add(msg.value);
        totalCollected = totalCollected.add(msg.value);

        if (totalCollected >= softCap) {
            softCapReached = true;
        }
    }

    function withdrawFunds() public {
        require(softCapReached, "SoftCap has not been reached");
        require(!fundsTransferred, "Funds transferred already");

        (bool success, ) = wallet.call{value: address(this).balance}("");
        require(success, "Transfer problem");

        fundsTransferred = true;
    }

    function refund() public nonReentrant {
        require(block.timestamp > endTime, "ICO not finished");
        require(!softCapReached, "SoftCap reached, refund not possible");
        require(contributions[msg.sender] > 0, "You dont have fund");

        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer problem");

        _burn(msg.sender, balanceOf(msg.sender));
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        // Блокировка передачи токенов до окончания freezePeriod
        if (from != address(0) && to != address(0)) {
            require(block.timestamp >= endTime.add(freezePeriod), "Freese period is active");
        }
    }

    function isActive() public view returns (bool) {
        return block.timestamp >= startTime && block.timestamp <= endTime && totalCollected < hardCap;
    }

    function isSuccessful() public view returns (bool) {
        return softCapReached && fundsTransferred;
    }
}
