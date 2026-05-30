// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ARCEscrow {
    address public buyer;
    address public freelancer;
    address public arbiter;
    
    uint256 public totalMilestones;
    uint256 public currentMilestone;
    uint256 public amountPerMilestone;
    uint256 public totalBudget;

    enum Status { Setup, Active, Dispute, Completed }
    Status public contractStatus;

    uint8 private unlocked = 1;
    modifier nonReentrant() {
        require(unlocked == 1, "REENTRANCY_GUARD_TRIGGERED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    event FundsDeposited(address indexed buyer, uint256 amount);
    event MilestoneReleased(uint256 indexed milestoneNumber, uint256 amount);
    event DisputeRaised();
    event DisputeResolved(address indexed winner);

    constructor(address _freelancer, address _arbiter, uint256 _milestones, uint256 _totalAmount) {
        require(_freelancer != address(0), "Invalid freelancer");
        require(_arbiter != address(0), "Invalid arbiter");
        require(_milestones > 0, "Milestones must be > 0");
        require(_totalAmount > 0, "Amount must be > 0");

        buyer = msg.sender;
        freelancer = _freelancer;
        arbiter = _arbiter;
        totalMilestones = _milestones;
        totalBudget = _totalAmount;
        amountPerMilestone = _totalAmount / _milestones;
        contractStatus = Status.Setup;
    }

    function depositFund() external payable {
        require(msg.sender == buyer, "Only buyer can deposit");
        require(contractStatus == Status.Setup, "Contract already funded");
        require(msg.value == totalBudget, "Incorrect total budget amount");

        contractStatus = Status.Active;
        emit FundsDeposited(buyer, msg.value);
    }

    function releaseMilestone() external nonReentrant {
        require(msg.sender == buyer, "Only buyer can release");
        require(contractStatus == Status.Active, "Contract is not active");
        require(currentMilestone < totalMilestones, "All milestones completed");

        currentMilestone++;
        uint256 payment;

        if (currentMilestone == totalMilestones) {
            payment = address(this).balance;
            contractStatus = Status.Completed;
        } else {
            payment = amountPerMilestone;
        }

        (bool success, ) = payable(freelancer).call{value: payment}("");
        require(success, "Transfer failed");

        emit MilestoneReleased(currentMilestone, payment);
    }

    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == freelancer, "Not authorized");
        require(contractStatus == Status.Active, "Can only dispute active contract");

        contractStatus = Status.Dispute;
        emit DisputeRaised();
    }

    function resolveDispute(bool payFreelancer) external nonReentrant {
        require(msg.sender == arbiter, "Only arbiter can resolve");
        require(contractStatus == Status.Dispute, "No active dispute");

        uint256 remainingBalance = address(this).balance;
        contractStatus = Status.Completed;

        if (payFreelancer) {
            (bool success, ) = payable(freelancer).call{value: remainingBalance}("");
            require(success, "Transfer to freelancer failed");
            emit DisputeResolved(freelancer);
        } else {
            (bool success, ) = payable(buyer).call{value: remainingBalance}("");
            require(success, "Refund to buyer failed");
            emit DisputeResolved(buyer);
        }
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
