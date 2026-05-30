// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ARCEscrow
 * @dev Decentralized Milestone-Based Escrow System for Freelancers and Buyers.
 */
contract ARCEscrow {
    // Contract-er sob main addresses
    address public buyer;
    address public freelancer;
    address public arbiter; 

    uint256 public totalMilestones;
    uint256 public currentMilestone;
    uint256 public amountPerMilestone;
    
    enum Status { Setup, Active, Dispute, Completed }
    Status public contractStatus;

    // Reentrancy Guard Protection Logic
    uint8 private unlocked = 1;
    modifier nonReentrant() {
        require(unlocked == 1, "REENTRANCY_GUARD_TRIGGERED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    // Events (Frontend dashboard or logs trace korar jonno)
    event FundsDeposited(address indexed buyer, uint256 amount);
    event MilestoneReleased(uint256 indexed milestoneNumber, uint256 amount);
    event DisputeRaised();
    event DisputeResolved(address indexed winner);

    constructor(
        address _freelancer, 
        address _arbiter, 
        uint256 _milestones, 
        uint256 _totalAmount
    ) {
        require(_freelancer != address(0), "Invalid freelancer address");
        require(_arbiter != address(0), "Invalid arbiter address");
        require(_milestones > 0, "Milestones must be greater than 0");
        require(_totalAmount > 0, "Total amount must be greater than 0");

        buyer = msg.sender;
        freelancer = _freelancer;
        arbiter = _arbiter;
        totalMilestones = _milestones;
        amountPerMilestone = _totalAmount / _milestones;
        contractStatus = Status.Setup;
    }

    // 1. Buyer flat payment/budget contract-e lock korbe
    function depositFund() external payable {
        require(msg.sender == buyer, "Only buyer can deposit");
        require(contractStatus == Status.Setup, "Contract already funded");
        require(msg.value == (amountPerMilestone * totalMilestones), "Incorrect ETH/Native token amount");

        contractStatus = Status.Active;
        emit FundsDeposited(buyer, msg.value);
    }

    // 2. Freelancer partial milestone complete korle buyer payment release korbe
    function releaseMilestone() external nonReentrant {
        require(msg.sender == buyer, "Only buyer can release fund");
        require(contractStatus == Status.Active, "Contract is not active");
        require(currentMilestone < totalMilestones, "All milestones already completed");
        
        currentMilestone++;
        uint256 payment = amountPerMilestone;
        
        (bool success, ) = payable(freelancer).call{value: payment}("");
        require(success, "Transfer failed");
        
        emit MilestoneReleased(currentMilestone, payment);
        
        if (currentMilestone == totalMilestones) {
            contractStatus = Status.Completed;
        }
    }

    // 3. Jhamela ba dispute dhorle jekono party system active korte parbe
    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == freelancer, "Not authorized party");
        require(contractStatus == Status.Active, "Can only dispute an active contract");
        
        contractStatus = Status.Dispute;
        emit DisputeRaised();
    }

    // 4. Arbiter validation cross check kore final winner call korbe
    function resolveDispute(bool payFreelancer) external nonReentrant {
        require(msg.sender == arbiter, "Only registered arbiter can resolve");
        require(contractStatus == Status.Dispute, "No active dispute found");

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

    // Contract current balance trigger check
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
