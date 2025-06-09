// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auction {
    // Auction parameters
    uint256 public initialPrice;
    uint256 public highestBid;
    address public highestBidder;
   
    // Mappings to track bids
    mapping(address => uint256) public previosBids; // For withdrawals during the auction
    mapping(address => uint256) public totalBids;  // To track all bids
    mapping(address => bool) public refundProcessed; // To prevent double refunds
    address[] public allBidders;                   // List of all bidders
    
    // Contract state
    bool public auctionEnded;
    bool public auctionStarted;
    address public owner;
   
    // Time management
    uint256 public auctionEndTime;
    uint256 public constant AUCTION_DURATION = 1 hours;
    uint256 public constant EXTENSION_TIME = 10 minutes;
   
    // Events
    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);
    event AuctionExtended(uint256 newEndTime);
    event AuctionStarted();
    event RefundProcessed(address indexed bidder, uint256 amount);
    event CommissionWithdrawn(address indexed owner, uint256 amount);

    // Modifiers
    modifier onlyActiveAuction() {
        require(auctionStarted, "Auction has not started yet");
        require(!auctionEnded, "Auction has already ended");
        require(block.timestamp < auctionEndTime, "Auction time has expired");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
   
    constructor() {
        initialPrice = 20 wei;
        highestBid = initialPrice;
        owner = msg.sender;
        auctionStarted = false;
    }
   
    // the auction begins
    function startAuction() external onlyOwner {
        require(!auctionStarted, "Auction already started");
        auctionStarted = true;
        auctionEndTime = block.timestamp + AUCTION_DURATION;
        emit AuctionStarted();
    }


   // requirements to be able to bid
    function placeBid() external payable onlyActiveAuction {
        if (block.timestamp >= auctionEndTime && auctionStarted && !auctionEnded) {
            auctionEnded = true;
            processRefunds();
            return;
        }
       
        require(msg.value > highestBid, "Bid must be higher than current highest bid");

        uint validBid = highestBid + (highestBid * 5 / 100);
        require(msg.value >= validBid, "Bid must be 5% higher than current bid");
       
        if (block.timestamp > auctionEndTime - 1 hours) {
            auctionEndTime = block.timestamp + EXTENSION_TIME;
            emit AuctionExtended(auctionEndTime);
        }
       
        // Register bidder if new
        if (totalBids[msg.sender] == 0) {
            allBidders.push(msg.sender);
        }
        totalBids[msg.sender] += msg.value;
        
        // For immediate withdrawals 
        if (highestBidder != address(0)) {
            previosBids[highestBidder] += highestBid;
        }
       
        highestBid = msg.value;
        highestBidder = msg.sender;
       
        emit BidPlaced(msg.sender, msg.value);
    }
   
    //  withdrawals prior to the last offer
    function withdraw() external {
        uint256 amount = previosBids[msg.sender];
        require(amount > 0, "No funds to withdraw");
       
        previosBids[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }
    
    // Process refunds automatically when auction ends
    function processRefunds() internal {
        require(auctionEnded, "Auction not ended yet");
        
        for (uint i = 0; i < allBidders.length; i++) {
            address bidder = allBidders[i];
            
            if (!refundProcessed[bidder] && bidder != highestBidder && totalBids[bidder] > 0) {
                uint256 refundAmount = totalBids[bidder] * 98 / 100; // 2% commission
                refundProcessed[bidder] = true;
                
                (bool success, ) = bidder.call{value: refundAmount}("");
                if (success) {
                    emit RefundProcessed(bidder, refundAmount);
                }
            }
        }
    }
    
    // Function to display winner and winning bid, and return bids to non-winners
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction has not yet ended");
        require(!auctionEnded, "Auction already ended");
        require(auctionStarted, "Auction never started");
       
        auctionEnded = true;
        emit AuctionEnded(highestBidder, highestBid);
        
        // Process refunds automatically
        processRefunds();
    }
    
    // Function for owner to withdraw accumulated commissions
    function withdrawCommission() external onlyOwner {
        require(auctionEnded, "Auction not ended yet");
        
        uint256 commission = address(this).balance - highestBid;
        require(commission > 0, "No commission to withdraw");
        
        (bool success, ) = owner.call{value: commission}("");
        require(success, "Commission withdrawal failed");
        
        emit CommissionWithdrawn(owner, commission);
    }
    
    // Function for winner to claim the item 
    function claimItem() view external {
        require(auctionEnded, "Auction not ended yet");
        require(msg.sender == highestBidder, "Only winner can claim item");
    }
}