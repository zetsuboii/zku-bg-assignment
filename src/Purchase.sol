// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice A modified version of Purchase contract in Solidity examples
/// @dev THIS CONTRACT HAS A KNOWN VULNERABILITY, DO NOT USE IT
contract Purchase {
    uint256 public purchaseTime;
    uint256 public value;
    address payable public seller;
    address payable public buyer;

    enum State {
        Created,
        Locked,
        Inactive
    }

    State public state;

    modifier condition(bool condition_) {
        require(condition_);
        _;
    }

    /// Only the buyer can call this function.
    error OnlyBuyer();
    /// Only the seller can call this function.
    error OnlySeller();
    /// The function cannot be called at the current state.
    error InvalidState();
    /// The provided value has to be even.
    error ValueNotEven();
    /// This function is callable only if caller is the buyer or 5 minutes have
    /// passed after the purchase
    error OnlyBuyerOrExpired();

    modifier onlyBuyer() {
        if (msg.sender != buyer) revert OnlyBuyer();
        _;
    }

    modifier onlySeller() {
        if (msg.sender != seller) revert OnlySeller();
        _;
    }

    modifier onlyBuyerOrExpired() {
        if (msg.sender != buyer && block.timestamp < 5 minutes)
            revert OnlyBuyerOrExpired();
        _;
    }

    modifier inState(State state_) {
        if (state != state_) revert InvalidState();
        _;
    }

    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();
    event SellerRefunded();

    /// @dev Ensure that `msg.value` is an even number.
    /// @dev Division will truncate if it is an odd number.
    /// @dev Check via multiplication that it wasn't an odd number.
    constructor() payable {
        seller = payable(msg.sender);
        value = msg.value / 2;
        if ((2 * value) != msg.value) revert ValueNotEven();
    }

    /// @notice Abort the purchase and reclaim the ether.
    /// @dev Can only be called by the seller before the contract is locked.
    function abort() external onlySeller inState(State.Created) {
        emit Aborted();
        state = State.Inactive;
        // We use transfer here directly. It is reentrancy-safe, because it is
        // the last call in this function and we already changed the state.
        seller.transfer(address(this).balance);
    }

    /// @notice Confirm the purchase as buyer.
    /// @dev Transaction has to include `2 * value` ether.
    /// @dev The ether will be locked until confirmReceived is called.
    function confirmPurchase()
        external
        payable
        inState(State.Created)
        condition(msg.value == (2 * value))
    {
        emit PurchaseConfirmed();
        buyer = payable(msg.sender);
        state = State.Locked;
        purchaseTime = block.timestamp;
    }

    /// @notice Complete the purchase, split the funds
    /// @dev Caller must be the buyer or 5 minutes must've past
    /// @dev This creates a bug where anyone can complete purchase after
    /// 5 minutes even if buyer didn't received anything
    function completePurchase()
        external
        onlyBuyer
        inState(State.Locked)
        onlyBuyerOrExpired
    {
        emit ItemReceived();
        emit SellerRefunded();
        buyer.transfer(value);
        seller.transfer(3 * value);
        state = State.Inactive;
    }
}
