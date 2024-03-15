// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IOAppCore } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppCore.sol";
import { IOAppComposer } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppComposer.sol";
import { OFTComposeMsgCodec } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";

/// @title SwapMock Contract
/// @dev This contract mocks an ERC20 token swap in response to an OFT being received (lzReceive) on the destination chain.
/// @notice The contract is designed to interact with LayerZero's Omnichain Fungible Token (OFT) Standard,
/// allowing it to respond to cross-chain OFT mint events with a token swap action.
contract SwapMock is IOAppComposer {
    using SafeERC20 for IERC20;
    IERC20 public erc20;

    /// @notice Emitted when a token swap is executed.
    /// @param user The address of the user who receives the swapped tokens.
    /// @param tokenOut The address of the ERC20 token being swapped.
    /// @param amount The amount of tokens swapped.
    event Swapped(address indexed user, address tokenOut, uint256 amount);

    /// @notice Constructs the SwapMock contract.
    /// @dev Initializes the contract with a specific ERC20 token address.
    /// @param _erc20 The address of the ERC20 token that will be used in swaps.
    constructor(address _erc20) {
        erc20 = IERC20(_erc20);
    }

    /// @notice Handles incoming composed messages from LayerZero.
    /// @dev Decodes the message payload to perform a token swap.
    ///      This method expects the encoded compose message to contain the swap amount and recipient address.
    /// @param _oApp The address of the originating OApp.
    /// @param /*_guid*/ The globally unique identifier of the message (unused in this mock).
    /// @param _message The encoded message content, expected to be (uint256 amount, address receiver).
    /// @param /*Executor*/ Executor address (unused in this mock).
    /// @param /*Executor Data*/ Additional data for checking for a specific executor (unused in this mock).
    function lzCompose(
        address _oApp,
        bytes32 /*_guid*/,
        bytes calldata _message,
        address /*Executor*/,
        bytes calldata /*Executor Data*/
    ) external payable override {
        // Extract the composed message from the delivered message using the MsgCodec
        bytes memory _composeMsgContent = OFTComposeMsgCodec.composeMsg(_message);
        // Decode the composed message to get the amount and receiver for the token swap
        (uint256 _amountToSwap, address _receiver) = abi.decode(_composeMsgContent, (uint256, address));

        // Execute the token swap by transferring the specified amount to the receiver
        erc20.safeTransfer(_receiver, _amountToSwap);

        // Emit an event to log the token swap details
        emit Swapped(_receiver, address(erc20), _amountToSwap);
    }
}