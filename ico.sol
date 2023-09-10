// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";



contract ICO {
    IERC20 public token; // The ERC20 token being sold
    address public wallet; // The address where funds will be collected
    uint256 public rate; // Number of tokens per Ether
    uint256 public minPurchase; // Minimum purchase amount in Ether
    uint256 public maxPurchase; // Maximum purchase amount in Ether
    uint256 public hardCap; // Maximum amount of Ether to be raised
    uint256 public totalPurchased; // Total Ether purchased
    bool public isICOActive; // ICO status

    event TokensPurchased(address indexed purchaser, uint256 amount);

    constructor(
        address _token,
        address _wallet,
        uint256 _rate,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        uint256 _hardCap
    ) {
        require(_token != address(0), "Token address cannot be zero");
        require(_wallet != address(0), "Wallet address cannot be zero");
        require(_rate > 0, "Rate must be greater than zero");
        require(_minPurchase > 0, "Minimum purchase must be greater than zero");
        require(_hardCap > 0, "Hard cap must be greater than zero");

        token = IERC20(_token);
        wallet = _wallet;
        rate = _rate;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        isICOActive = true;
    }

    modifier onlyWhileICOActive() {
        require(isICOActive, "ICO is not active");
        _;
    }

    receive() external payable onlyWhileICOActive {
        purchaseTokens(msg.sender, msg.value);
    }

     modifier onlyOwner() {
        require(msg.sender == wallet, "not an owner!");
        _;
    }

    function purchaseTokens(address beneficiary, uint256 weiAmount) public payable onlyWhileICOActive {
        require(beneficiary != address(0), "Beneficiary address cannot be zero");
        require(weiAmount >= minPurchase, "Below minimum purchase");
        require(weiAmount <= maxPurchase || maxPurchase == 0, "Exceeds maximum purchase");

        uint256 tokenAmount = weiAmount * rate;

        require(token.balanceOf(address(this)) >= tokenAmount, "Insufficient tokens in ICO contract");

        totalPurchased += weiAmount;
        token.transfer(beneficiary, tokenAmount);
        emit TokensPurchased(beneficiary, tokenAmount);
    }

    function withdrawFunds() external onlyOwner {
        require(!isICOActive, "ICO is still active");
        require(msg.sender == wallet, "Only the wallet address can withdraw");
        uint256 balance = address(this).balance;
        payable(wallet).transfer(balance);
    }

    function endICO() external {
        require(msg.sender == wallet, "Only the wallet address can end the ICO");
        isICOActive = false;
    }
}