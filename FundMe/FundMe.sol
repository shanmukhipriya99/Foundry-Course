// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PriceConverter} from "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    address public immutable i_owner;
    uint256 public constant MIN_USD = 5e18;
    address[] public funders;
    mapping(address => uint256) public amountFundedByAddress;

    constructor() {
        i_owner = msg.sender;
    }

    // Get funds from users
    // Set a minimum funding value in USD
    function fund() public payable {
        require(msg.value.getConversionRate() >= MIN_USD, "Didn't send enough ETH"); // 1e18 = 1 ETH = 1x10^18
        // Revert: Undo any actions that have been done & sends the remaining gas back
         funders.push(msg.sender);
         amountFundedByAddress[msg.sender] += msg.value;
    }

    // Withdraw funds
    function withdraw() public onlyOwner {
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            amountFundedByAddress[funder] = 0;
        }
        funders = new address[](0); // resetting the array
        // // transfer: throws error if fails
        // payable(msg.sender).transfer(address(this).balance);
        // // send: returns bool
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed!");
        // call: similar to send, returns bool & data: most preferrable
        // second parameter: bytes memory dataReturned
        (bool callSuccess, ) = payable(i_owner).call{value: address(this).balance}("");
        require(callSuccess, "Call failed!");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Only owner can withdraw funds!");
        if(msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // dealing with scenarios where users accidentally send funds without trigerring funds()

    // 1: receive(): if msg.data is empty
    receive() external payable {
        fund();
    }

    // 2: falllback(): if msg.data contains value
    fallback() external payable {
        fund();
    }

}