// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IOAppComposer } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppComposer.sol";

contract SimpleSwapMock is IOAppComposer {
    IERC20 public oft;
    IERC20 public erc20;

    event Swapped(address indexed user, address tokenIn, address tokenOut, uint256 amount);

    constructor(address _oft, address _erc20) {
        oft = IERC20(_oft);
        erc20 = IERC20(_erc20);
    }

    function swapOFTforERC20(uint256 _amount, address _receiver) public payable {
        require(_amount > 0, "Cannot swap 0 tokens");
        require(oft.balanceOf(msg.sender) >= _amount, "Insufficient Token A balance");
        require(erc20.balanceOf(address(this)) >= _amount, "Insufficient Token B in contract");

        oft.transferFrom(msg.sender, address(this), _amount);
        erc20.transfer(_receiver, _amount);

        emit Swapped(_receiver, address(oft), address(erc20), _amount);
    }

    function swapERC20forOFT(uint256 _amount, address _receiver) public payable {
        require(_amount > 0, "Cannot swap 0 tokens");
        require(erc20.balanceOf(msg.sender) >= _amount, "Insufficient Token B balance");
        require(oft.balanceOf(address(this)) >= _amount, "Insufficient Token A in contract");

        erc20.transferFrom(msg.sender, address(this), _amount);
        oft.transfer(_receiver, _amount);

        emit Swapped(_receiver, address(erc20), address(oft), _amount);
    }

    /// @notice Handles incoming composed messages from LayerZero.
    /// @dev Decodes the message payload and updates the state.
    /// @param _oApp The address of the originating OApp.
    /// @param /*_guid*/ The globally unique identifier of the message.
    /// @param _message The encoded message content.
    function lzCompose(
        address _oApp,
        bytes32 /*_guid*/,
        bytes calldata _message,
        address /*Executor*/,
        bytes calldata /*Executor Data*/
    ) external payable override {
        // Decode the payload to get the message
        (uint256 _amountToSwap, address _receiver) = abi.decode(_message, (uint256, address));
        this.swapOFTforERC20(_amountToSwap, _receiver);
    }
}
