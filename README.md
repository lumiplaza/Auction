Overview
This is a simple auction smart contract written in Solidity (^0.8.0) that implements a timed auction with automatic bid extensions, refund processing, and commission collection

CONTRACT VARIABLES

Auction Parameters
initialPrice: Starting price of the auction (20 wei)

highestBid: Current highest bid amount

highestBidder: Address of the current highest bidder

Bid Tracking
previosBids: Mapping to track amounts that can be withdrawn by outbid bidders

totalBids: Mapping to track all bids made by each address

refundProcessed: Mapping to prevent double refunds

allBidders: Array storing all addresses that have placed bids

Contract State
auctionEnded: Boolean indicating if auction has ended

auctionStarted: Boolean indicating if auction has started

owner: Address of the contract owner

Time Management
auctionEndTime: Timestamp when auction will end

AUCTION_DURATION: Constant for initial auction duration (1 hour)

EXTENSION_TIME: Constant for bid extension time (10 minutes)

FUNCTIONS
Core Functions
startAuction():

Starts the auction (owner only)

Sets auction end time

placeBid():

Main bidding function (payable)

Requires bid to be 5% higher than current bid

Extends auction if bid placed in last hour

Tracks all bids and bidders

withdraw():

Allows outbid bidders to withdraw their previous bids

processRefunds() (internal):

Automatically processes refunds (98% of bid) for all non-winning bidders

Called when auction ends

endAuction():

Officially ends the auction

Processes refunds automatically

Utility Functions
withdrawCommission():

Allows owner to withdraw 2% commission from all bids (owner only)

claimItem() (view):

Allows winner to verify they can claim the auction item

EVENTS
BidPlaced: Emitted when a new bid is placed

Parameters: bidder address, bid amount

AuctionEnded: Emitted when auction ends

Parameters: winner address, winning bid amount

AuctionExtended: Emitted when auction time is extended

Parameters: new end time

AuctionStarted: Emitted when auction begins

RefundProcessed: Emitted when a bidder receives refund

Parameters: bidder address, refund amount

CommissionWithdrawn: Emitted when owner withdraws commission

Parameters: owner address, commission amount

MODIFIERS
onlyActiveAuction:

Ensures function can only be called during active auction

Checks auction has started, not ended, and time hasn't expired

onlyOwner:

Restricts function to contract owner only

KEY FEATURES
Automatic auction time extension when bids are placed in last hour

5% minimum bid increment requirement

2% commission on all losing bids

Automatic refund processing

Protection against double refunds

Owner commission withdrawal function

Winner verification function
