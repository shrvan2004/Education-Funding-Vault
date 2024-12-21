// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EducationFundingVault {
    address public owner;
    mapping(address => uint256) public contributions;
    uint256 public totalFunds;
    uint256 public withdrawalDeadline;
    address payable public beneficiary;

    event FundDeposited(address indexed contributor, uint256 amount);
    event FundsWithdrawn(address indexed beneficiary, uint256 amount);
    event RefundIssued(address indexed contributor, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyBeforeDeadline() {
        require(block.timestamp < withdrawalDeadline, "Operation not allowed after deadline");
        _;
    }

    constructor(address payable _beneficiary, uint256 _durationInDays) {
        owner = msg.sender;
        beneficiary = _beneficiary;
        withdrawalDeadline = block.timestamp + (_durationInDays * 1 days);
    }

    function contribute() public payable onlyBeforeDeadline {
        require(msg.value > 0, "Contribution must be greater than 0");

        contributions[msg.sender] += msg.value;
        totalFunds += msg.value;
        emit FundDeposited(msg.sender, msg.value);
    }

    function withdrawFunds() public {
        require(msg.sender == beneficiary, "Only the beneficiary can withdraw funds");
        require(block.timestamp >= withdrawalDeadline, "Cannot withdraw before the deadline");
        require(totalFunds > 0, "No funds to withdraw");

        uint256 amountToWithdraw = totalFunds;
        totalFunds = 0;
        beneficiary.transfer(amountToWithdraw);
        emit FundsWithdrawn(beneficiary, amountToWithdraw);
    }

    function refund() public onlyBeforeDeadline {
        uint256 contributedAmount = contributions[msg.sender];
        require(contributedAmount > 0, "No contributions to refund");

        contributions[msg.sender] = 0;
        totalFunds -= contributedAmount;
        payable(msg.sender).transfer(contributedAmount);
        emit RefundIssued(msg.sender, contributedAmount);
    }

    function extendDeadline(uint256 _additionalDays) public onlyOwner {
        withdrawalDeadline += (_additionalDays * 1 days);
    }
}
